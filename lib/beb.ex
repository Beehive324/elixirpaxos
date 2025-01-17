defmodule BestEffortBroadcast do
  def start(name, processes) do
    pid = spawn(BestEffortBroadcast, :init, [name, processes])
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
    IO.puts("Registered #{name}")
    pid
  end

  def init(name, processes) do
    IO.puts("Initializing BestEffortBroadcast with name=#{inspect(name)} and processes=#{inspect(processes)}")
    state = %{
      delivered: MapSet.new(),
      processes: processes
    }
    beb_broadcast(state)
  end

  defp beb_broadcast(state) do
    receive do
      {:broadcast, m} ->
        if not MapSet.member?(state.delivered, m) do
          Enum.each(state.processes, fn process ->
            send(process, {:deliver, m})
          end)
          IO.puts("Broadcasted message: #{m}")
          state = %{state | delivered: MapSet.put(state.delivered, m)}
        end
        beb_broadcast(state)

      {:deliver, m} ->
        IO.puts("Delivered message: #{m}")
        beb_broadcast(state)

      {:stop} ->
        IO.puts("Stopping BestEffortBroadcast process.")
        :ok
    end
  end
end
