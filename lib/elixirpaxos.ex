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
    acceptor: acceptor,
    learner: learner,
    acceptors: [],
    value: 0,

    }
    state
    run(state)
  end


  def run(state) do




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


end
