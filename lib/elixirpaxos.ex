Code.require('abstractions/eventual_leader_detector.ex')
Code.require('abstractions/best_effort_broadcast.ex')


defmodule Paxos do
  def start(name, participants) do
    pid = spawn(Paxos, :init, [name, paxos_proc])
    pid = case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> nil
    end
    IO.puts(if pid, do: "registered #{name}", else: "failed to register #{name}")
  end

  @moduledoc """
  Documentation for `Paxos`.
    Algorithm for solving consensus
  group of machines with a leader, can we still arive at a single
    common consensus value

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

  defp beb_broacast(m, dest) do
    BestEffortBroadcast.beb_broadcast(Process.whereis(get_beb_nme()), m, dest)
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

  #prpose api
  defp propose(pid, inst, value, t) do
    val = make_ref() #create unique reference number
    send(pid, {:propose, self(), val, inst, value})
    receive do
      {:decision, ^ref, value} -> {:decision, value}
      {:abort, ^ref} -> {:abort}
    after
    t -> {:timeout}
    end
  end
  #get_decision api
  defp get_decision(pid, inst, t) do
    val = make_ref()
    send(pid, {:get_decision, self(), ref, inst})
    receive do
      {:decision, ^ref, value} -> value
    after
      t -> nil
    end
  end

  def init(name, participants) do
    leader = EventualLeaderDetector.start(name, participants) #starts by assigning a leader
    # needs to maintain a majoriy quorom to complete a round (n / 2 + 1) to
    start_beb(name)
    start_le(name)
    #split between proposer and acceptor, n - 2
    state = %{
    name: name,
    participants: participants,
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
  defp start_ballot(state, b, initial_value) do

  end

  #(3) upon quorom S of (prepared, b, a_bal, a_val
  defp quorum_s(prepared, b, a_bal, a_val) do

  end

  defp quorom_accept(state, accepted, b) do

  end

  def run(state) do
    state = receive do
      #(1)
      {:broadcast, value} ->
       message = propose(self(), state.inst, state.value)
       beb_broacast({:propose, message}, state.participants)
       state

      state


      #(2)
      {:prepare, b} when b > state.bal ->
      send(state.sender, {:prepared, b, state.a_bal, state.a_val})
      state = %{state | bal: b}
      state

      {:prepare, b} when b > state.bal ->
      send(state.sender, {:prepared, b, state.a_bal, state.a_val})
      state = %{state | bal: b}
      state

      #(3)
      {:quorom, {:prepared, b, a_bal, a_val}} ->
      if a_val == nil do
        state = %{state | v: state.v = 0}
        state
        else
          state =  %{state | v: state.v = state.a_val}
          state
        end
        beb_broacast({:accept, b, v})
        state

      state

      #(4)
      {:accept, {b, v}} ->
      if b >= state.bal do
        state = %{state | bal: state.bal = b}
        state = %{state | a_bal: state.bal = b}
        state = %{state | a_val: state.bal = v}
        send(beb_broacast({:accepted, b}, state.participants))

        else
        send({:nack, b}, state.paricpants)
      end
      state
      #(5)
      {:accept_quorom} ->
      state.v
      state


      end

    end
  end









end
