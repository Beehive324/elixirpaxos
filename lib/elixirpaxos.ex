Code.require('eventual_leader_detector.ex')
Code.require('best_effort_broadcast.ex')

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
  group of machines with no leader, can we still arive at a single
    common consensus value

  """

  def init(name, participants) do
    state = %{
    name: name,
    participants: participants,
    leader: leader,
    proposer: proposer,
    acceptor: %MapSet{},
    learner: learner,
    acceptors: [],
    value: 0,

    }
    state
    run(state)
  end


  def run(state) do

    state = receive do

      {:propose} ->
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

  defp prepare() do
    #generate unique proposal number
    #sends a prepare request to all other nodes
  end

  defp propose(pid, inst, value, t) do
    {:decision, v}

    {:abort}
    {:timeout}
  end

  defp get_decision(pid, inst, t) do


  end


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
    pid = spawn(EventualLeaderElection, :init, [])
    Process.register(pid, get_le_name())
    Process.link(pid)
  end

  defp eventual_leader_election() do
    EventualLeaderElection.eventualleader(Process.whereis(get_le_name()))
  end





end
