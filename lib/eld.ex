defmodule EventualLeaderDetector do
  def init(name, processes) do
    state = %{
      name: name,
      processes: processes,
      suspected: MapSet.new(),
      leader: determine_leader(processes, MapSet.new())
    }

    IO.puts("Leader election started for #{inspect(name)}. Initial leader: #{inspect(state.leader)}")

    loop(state)
  end

  defp loop(state) do
    receive do
      {:suspect, process} ->
        IO.puts("Suspecting process #{inspect(process)}")
        updated_suspected = MapSet.put(state.suspected, process)
        new_leader = determine_leader(state.processes, updated_suspected)
        if new_leader != state.leader do
          IO.puts("Leader changed from #{inspect(state.leader)} to #{inspect(new_leader)}")
        end
        loop(%{state | suspected: updated_suspected, leader: new_leader})

      {:restore, process} ->
        IO.puts("Restoring process #{inspect(process)}")
        updated_suspected = MapSet.delete(state.suspected, process)
        new_leader = determine_leader(state.processes, updated_suspected)
        if new_leader != state.leader do
          IO.puts("Leader changed from #{inspect(state.leader)} to #{inspect(new_leader)}")
        end
        loop(%{state | suspected: updated_suspected, leader: new_leader})

      :get_leader ->
        send(self(), {:leader, state.leader})
        loop(state)
    end
  end


  def determine_leader(processes, suspected \\ MapSet.new()) do
    Enum.find(processes, fn process -> not MapSet.member?(suspected, process) end)
  end
end
