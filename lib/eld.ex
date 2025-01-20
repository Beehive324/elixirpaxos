defmodule EventualLeaderDetector do
  def start(name, processes) do
    # Spawn a process to run the `init` function
    pid = spawn(EventualLeaderDetector, :init, [name, processes])

    # Register the process globally
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
  end

  def init(name, processes) do
    state = %{
      processes: processes,  # Store the list of processes
      suspected: MapSet.new(),  # Keep track of suspected processes
      leader: nil  # No leader initially
    }

    # Start the event loop
    eld(state)
  end

  def eld(state) do
    # Wait for messages
    new_state =
      receive do
        {:suspect, proc} ->
          IO.puts("Suspecting process #{inspect(proc)}")
          # Add the process to the suspected set
          %{state | suspected: MapSet.put(state.suspected, proc)}

        {:restore, proc} ->
          IO.puts("Restoring process #{inspect(proc)}")
          # Remove the process from the suspected set
          %{state | suspected: MapSet.delete(state.suspected, proc)}

        :get_leader ->
          # Determine the current leader
          leader = determine_leader(state)
          IO.puts("Current leader is #{inspect(leader)}")
          send(self(), {:leader, leader})
          state

        {:leader, leader} ->
          # Update the leader in the state
          %{state | leader: leader}
      end

    # Continue the event loop
    eld(new_state)
  end

  def determine_leader(state) do
    # Find the leader as the smallest process ID not suspected
    Enum.find(state.processes, fn proc ->
      not MapSet.member?(state.suspected, proc)
    end)
  end
end
