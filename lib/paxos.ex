defmodule Paxos do

  #spwan each process
  def start(name, paxos_proc) do
    pid = spawn(Paxos, :init, [name, paxos_proc])
    pid = case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> nil
    end
    IO.puts(if pid, do: "registered #{name}", else: "failed to register #{name}")
  end

  @moduledoc """
  """

  #Implementing BestEffortBroadCast abstraction
  defp get_beb_name() do
    {:registered_name, parent} = Process.info(self(), :registered_name)
    String.to_atom(Atom.to_string(parent) <> "_beb")
  end

  defp start_beb(name) do
    Process.register(self(), name)
    pid = spawn(BestEffortBroadcast, :init, [])
    Process.register(pid, get_beb_name())
    Process.link(pid)
  end

  defp beb_broadcast(m, dest) do
    BestEffortBroadcast.beb_broadcast(Process.whereis(get_beb_name()), m, dest)
  end

  #Implementing LeaderELection abstraction
  defp get_le_name() do
    {:registered_name, parent} = Process.info(self(), :registered_name)
    String.to_atom(Atom.to_string(parent) <> "_beb")
  end

  defp start_le(name) do
    Process.register(self(), name)
    pid = spawn(EventualLeaderDetector, :init, [])
    Process.register(pid, get_le_name())
    Process.link(pid)
  end

  defp eventual_leader_detector() do
    EventualLeaderDetector.eventual_leader_detector(Process.whereis(get_le_name()))
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

  def init(name, participants) do
    # needs to maintain a majoriy quorom to complete a round (n / 2 + 1) to
    start_beb(name)
    #split between proposer and acceptor, n - 2
    state = %{
    name: name,
    inst: nil,
    participants: participants,
    proposals: %MapSet{}, #proposal num, value
    proposal_number: 0,
    proposal_value: 0,
    quorom: 0,
    bal: 0, #ballot number
    a_bal: 0, #accepted ballot number
    a_val: 0, #accepted value
    v: nil
    }
    state
    run(state)
  end

  #Leader Based functions
  #(1) Broadcast prepare
  def run(state) do
    state = receive do
      #Proposer Logic
      #Phase 1. (a)
      {:broadcast, value, t} ->
       prepare_req = propose(self(), state.inst, state.value, t) #start by proposing a message
       beb_broadcast({:propose, prepare_req}, state.participants) #send this message to other aceptors
       state =  %{state | proposal_number: state.proposal_number + 1} #increase proposal number
       proposal = {state.proposal_number, state.proposal_value} #establish new proposl number
       state = %{state | proposal: Map.put(state.proposals, ({state.proposal_number, state.proposal_value}))} # add it to the map
       state = %{state | bal: state.proposal_number}
       state #call state

      state

      #Promise (Phase 1a)
      {:prepare, b} ->
       state = if b > state.bal do
        state = %{state | bal: b}
        send(state.sender, {:prepared, b, state.a_bal, state.a_val})
       else
        send({:nack}, b)

       end
      state
      #Acceptor Logic
      {:prepare, b} when b > state.bal ->
      send(state.sender, {:prepared, b, state.a_bal, state.a_val})
      state = %{state | bal: state.b}
      state

      #(3)
      {:quorom, {:prepared, b, a_bal, a_val, v}} ->
      if a_val == nil do
        state = %{state | v: 0}
        state
        else
          state =  %{state | v: a_val}
          state
        end
        beb_broadcast({:accept, state.b, state.v}, state.participants)
        state

      state

      #Accept (Phase 2)
      {:accept, {b, v}} ->
      if b >= state.bal do
        state = %{state | bal:  b}
        state = %{state | a_bal: b}
        state = %{state | a_val: v}
        beb_broadcast({:accepted, b}, state.participants)

        else
        send({:nack, b}, state.participants)
      end
      state
      #Learning (Phase 3)
      {:accept_quorom} ->
      state.v
      state

      end

    end
  end








