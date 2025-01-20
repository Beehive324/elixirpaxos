defmodule Paxos do

  #spwan each processc
  def start(name, paxos_proc) do
  # Unregister if the process name is already taken
  if Process.whereis(name) do
    IO.puts("Process #{inspect(name)} already exists. Unregistering...")
    Process.unregister(name)
  end

  # Spawn and register the process
  pid = spawn(Paxos, :init, [name, paxos_proc])

  case :global.re_register_name(name, pid) do
    :yes ->
      IO.puts("Registered #{name} globally.")
      pid

    :no ->
      IO.puts("Failed to register #{name} globally. Name already in use.")
      nil
  end
end



  @moduledoc """
  """

  #Implementing BestEffortBroadCast abstraction
  def get_beb_name() do
    {:registered_name, parent} = Process.info(self(), :registered_name)
    String.to_atom(Atom.to_string(parent) <> "_beb")
  end

  def start_beb(name, participants) do
    beb_name = String.to_atom("#{name}_beb")
    if Process.whereis(beb_name) do
      IO.puts("Process #{inspect(beb_name)} already registered. Unregistering...")
      Process.unregister(beb_name)
    end
    Process.register(self(), name)
    pid = spawn(BestEffortBroadcast, :init, [name, participants])
    Process.register(pid, beb_name)
    Process.link(pid)
  end

  def beb_broadcast(m, dest) do
    BestEffortBroadcast.beb_broadcast(Process.whereis(get_beb_name()), m, dest)
  end

  #Implementing LeaderELection abstraction
  defp get_le_name() do
    {:registered_name, parent} = Process.info(self(), :registered_name)
    String.to_atom(Atom.to_string(parent) <> "_eld")
  end

  defp start_le(name, processes) do
    eld_name = String.to_atom("#{name}_eld")
    pid = spawn(EventualLeaderDetector, :init, [name, processes])
    Process.register(pid, eld_name)
    Process.link(pid)
  end

  def leader_detector(processes) do
    EventualLeaderDetector.determine_leader(Process.whereis(get_le_name(), processes))
  end

  #Two steps in paxos: propose, accept
  #allows processes to propose values
  def propose(pid, inst, value, t) do
    send(pid, {:propose, inst, {:val, value}})
    receive do
      {:decision, value} -> {:decision, value}
      {:abort, value} -> {:abort}
    after
    t -> {:timeout}
    end
  end

  #get_decision api
  def get_decision(pid, inst, t) do
    send(pid, {:get_decision, self(),inst})
    receive do
      {:decision, val, value} -> value
    after
      t -> nil
    end
  end


  #  { ProcessID : ( proposal_num , proposal_val ) }
  def init(name, participants) do
    # needs to maintain a majoriy quorom to complete a round (n / 2 + 1) to
    start_beb(name, participants)
    #split between proposer and acceptor, n - 2
    state = %{
    name: name, # { prepare request: (1, proceess_id) }
    inst: nil,
    sender: nil,
    participants: participants,
    prep_requests: %MapSet{}, #store prepare requests
    proposals: %MapSet{}, #proposal num, value
    proposal_number: 1,
    proposal_value: 0,
    decisions: %MapSet{},
    promises: nil, #have a map to store promises
    quorum_size: nil,
    bal: 0, #indicates which round of paxos, increment every time theres is a new round of paxos
    a_bal: 0, #highest proposal number
    a_val: 0, #accepted value
    #start each process at {1, process_id}, counter and process id
    v: nil
    }
    state
    run(state)
  end

  #handle promises
  #list

  #receive promises
  def receivePromises(0, list) , do: list
  def receivePromises(n, list) when n>0 do
    receive do
      {:promiseOk, tStore, cmd, pid} ->
        receivePromises(n-1, [{tStore, cmd, pid} |list])
    after
      # wait for 1s
      1_000 ->
        receivePromises(n-1, list)
    end
  end

  #receive proposals
  def receiveProposals(0, acc) , do: acc
  def receiveProposals(n, acc\\0) when n>0 do
    receive do
      :proposalSuccess ->
        # proposerSay "Received 'ProposalSuccess'"
        receiveProposals(n-1, acc+1)
    after
      # wait for 1s
      1_000 ->
        # proposerSay "Proposal didn't come"
        receiveProposals(n-1, acc)
    end
  end

  #Leader Based functions
  #(1) Broadcast prepare
  def run(state) do
    state = receive do
      {:get_decision} ->
        decision = Map.get(state.decisions)

        if decision != nil do
          send(state.participants, decision)
        end

      # Prepare Phase
      {:prepare, value, t} ->
        #send prepare message
        prepare_req = {self(), state.proposal_number}
        beb_broadcast({:prepare, prepare_req}, state.participants) # m , dest
        proposal = {state.proposal_number, state.proposal_value}
        state = %{ state |
        prep_requests: MapSet.put(state.prep_requests, prepare_req), #store prepare request
        proposal_number: state.proposal_number + 1,
        bal: state.proposal_number + 1,
        proposal_value: value,
        quorom_size: div(length(state.participants), 2) + 1,
        proposals: MapSet.put(state.proposals, proposal)
        }

        promises = receivePromises(state.quorum_size, []) #p promises
        state = %{state | promises: promises}
        # If the proposer receives the requested responses  from a majority of acceptors
		    if length(state.promises) > div(state.quorum_size, 2)  do
          max_promise = Enum.max_by(state.promises, fn {a_bal, _a_val, _pid} -> a_bal end, fn -> {0, nil, nil} end)
          IO.puts("#{max_promise}")
          {highest_a_bal, highest_a_val, _pid} = max_promise
          new_value =
            if highest_a_val == nil do
              state.proposal_value
              #propose(self(), state.inst, state.proposal_value, state.t)
              #val = beb_broadcast({:accept, val}, state.participants) # send accept request
            else
              highest_a_val #return highest_val
              #val = propose(self(), state.inst, highest_a_val, state.t)
              #beb_broadcast({:accept, val}, state.participants) #send accept request
            end
          state = %{state | proposal_value: new_value}
          IO.puts("Quorum reached. Selected value: #{new_value}")
        else
          state = %{state | proposal_number: state.proposal_number + 1, bal: state.proposal_number + 1}
          IO.puts("Quorum not reached. Retrying...")
        end
        state

        state = %{ state | proposal_number: state.proposal_number,proposal_value: state.proposal_value,
          proposals: MapSet.put(state.proposals, {state.proposal_number, state.proposal_value})}

        beb_broadcast({:accept, {state.proposal_number, state.proposal_value}}, state.participants)






      # Accept Phae
      #(3)
      {:quorom, {:prepared, b, a_bal, a_val, v}} ->
        if a_val == nil do
          # Default value if no value has been accepted
          state = %{state | v: 0}
        else
          # Use the accepted value
          state = %{state | v: a_val}
        end
        # Broadcast the accept message
        beb_broadcast({:accept, state.b, state.v}, state.participants)
        state

      # Accept (Phase 2)
      {:accept, {b, v}} ->
        if b >= state.bal do
          # Update state with the accepted ballot and value
          state = %{state | bal: b, a_bal: b, a_val: v}
          beb_broadcast({:accepted, b}, state.participants)
        else
          # Send nack if ballot number is less than state.bal
          send({:nack, b}, state.participants)
        end
        state

      # Learning (Phase 3)
      {:accept_quorom, pid, inst, val} ->
        decision = get_decision(pid, inst, val)
        state = %{state | a_val: decision}
        state.v
        state
    end
  end
end
