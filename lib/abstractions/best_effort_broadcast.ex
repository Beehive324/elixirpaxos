Code.require('Perfect_Point_To_Point_Links.ex')


defmodule BestEffortBroadcast do

  def start() do

  end


  def init() do
    state = %{
    delivered: %MapSet{}
    }
    run(state)
  end


  def run(state) do

    state = receive do

      {:broadcast, m} ->
        pl.send(state.processes, m)
        state

      {:deliver, m} ->
      state

    end


    end

  defp get_pl_name() do
    {:registered_name, parent} = Process.info(self(), :registered_name)
    String.to_atom(Atom.to_string(parent) <> "_beb")
  end

  defp start_pl(name) do
    Process.register(self(), name)
    pid = spawn(PointLinks, :init, [])
    Process.register(pid, get_le_name())
    Process.link(pid)
  end

  defp pl() do
    PointLinks.eventualleader(Process.whereis(get_le_name()))
  end



  end
