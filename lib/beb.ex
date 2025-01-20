defmodule BestEffortBroadcast do
  # Start the BEB process and register it globally
  def start(name, processes) do
    pid = spawn(BestEffortBroadcast, :init, [name, processes])
    case :global.re_register_name(name, pid) do
      :yes ->
        IO.puts("BEB process #{name} registered successfully.")
        pid
      :no ->
        IO.puts("Failed to register BEB process #{name}.")
        :error
    end
  end

  # Initialize BEB process with a name and list of processes
  def init(name, processes) do
    IO.puts("Starting BEB for #{name} with participants: #{inspect(processes)}")
    state = %{
      delivered: MapSet.new(), # Keeps track of delivered messages
      processes: processes     # List of target processes
    }
    loop(state)
  end

  # Main loop to handle incoming messages
  defp loop(state) do
    receive do
      # Broadcast a message to all participants
      {:beb_broadcast, message} ->
        unless MapSet.member?(state.delivered, message) do
          Enum.each(state.processes, fn process ->
            send(process, {:beb_deliver, self(), message})
          end)
          IO.puts("Broadcasted: #{inspect(message)}")
          state = %{state | delivered: MapSet.put(state.delivered, message)}
        end
        loop(state)

      # Handle delivered messages
      {:beb_deliver, sender, message} ->
        IO.puts("Delivered from #{inspect(sender)}: #{inspect(message)}")
        loop(state)

      # Stop the BEB process
      {:stop} ->
        IO.puts("Stopping BEB process.")
        :ok

      # Handle unknown messages
      _ ->
        IO.puts("Received an unknown message.")
        loop(state)
    end
  end

  # External interface to broadcast a message
  def beb_broadcast(name, message) do
    pid = :global.whereis_name(name)
    if pid != :undefined do
      send(pid, {:beb_broadcast, message})
    else
      IO.puts("BEB process #{name} not found.")
    end
  end
end