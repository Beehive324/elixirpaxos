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
    need the eventual leader

  """

  def init(name, participants) do
    state = %{
    name: name,
    participants: participants,
    leader: leader,
    acceptors: [],
    value: 0,

    }
    state
    run(state)
  end


  def run(state) do




  end

  defp propose(pid, inst, value, t) do
    {:decision, v}

    {:abort}
    {:timeout}
  end

  defp get_decision(pid, inst, t) do


  end


end
