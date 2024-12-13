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


  #Implementing BestEffort BroadCast

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


  #Implementing LeaderELection

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

   #split between proposer and acceptor, n - 2
    state = %{
    name: name,
    participants: participants,
    leader: leader,
    proposer: proposer,
    acceptor: %MapSet{},
    learner: learner,
    promises: 0,
    acceptors: [],
    value: 0,
    value_set: %MapSet{},
    round: 0, #round number
    }
    state
    run(state)
  end


  def run(state) do
    state = receive do
      {:propose} ->
      val = propose(state.name)
      pre_req = {(val)}
      self.send(pre_req, {state.name, state.participants})
      state

      {:deliver} ->
      beb_broacast(m, state.processes)
      {:accept} ->
      state
      {:leader} ->
      get_le_name(state.processes)
      state


    end

  end








end
