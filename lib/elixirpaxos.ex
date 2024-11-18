defmodule Elixirpaxos do

  def start(name, participants) do
    pid = spawn(Elixirpaxos, :init, [name, paxos_proc])
    pid = case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> nil
    end
    IO.puts(if pid, do: "registered #{name}", else: "failed to register #{name}")
  end
  @moduledoc """
  Documentation for `Elixirpaxos`.
  """


  def init(name, participants) do

    state = %{
    name: name,

    }
  end


  def propose(pid, inst, value, t) do
    {:decision, v}

    {:abort}

    {:timeout}
  end



  defp get_decision(pid, inst, t) do

  end

  @doc """
  Hello world.

  ## Examples

      iex> Elixirpaxos.hello()
      :world

  """
  def hello do
    :world
  end
end
