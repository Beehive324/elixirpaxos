defmodule StorageServer do
  @moduledoc """
  A storage server implementation that mimics a replicated data store using Paxos for achieving consensus.
  This server ensures consistency across replicas by coordinating with Paxos processes.
  """

  def start(name, paxos_proc) do
    pid = spawn(StorageServer, :init, [name, paxos_proc])
    pid = case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> nil
    end
    IO.puts(if pid, do: "registered #{name}", else: "failed to register #{name}")
    pid
  end

  def init(name, paxos_proc) do
    state = %{
      name: name,
      pax_pid: get_paxos_pid(paxos_proc),
      last_instance: 0,
      pending: {0, nil},
      data_store: %{} # Key-value store to mimic a replicated database
    }

    # Ensures shared destiny (if one of the processes dies, the other does too)
    Process.link(state.pax_pid)

    run(state)
  end

  # Retrieves the PID of the Paxos instance to connect to
  defp get_paxos_pid(paxos_proc) do
    case :global.whereis_name(paxos_proc) do
      pid when is_pid(pid) -> pid
      :undefined -> raise("Paxos process #{Atom.to_string(paxos_proc)} not found")
    end
  end

  defp run(state) do
    receive do
      {:write, key, value, sender} ->
        new_instance = state.last_instance + 1
        state = %{state | last_instance: new_instance, pending: {new_instance, sender}}
        send(state.pax_pid, {:propose, new_instance, {key, value}, self()})
        run(state)

      {:read, key, sender} ->
        value = Map.get(state.data_store, key, :not_found)
        send(sender, {:read_reply, key, value})
        run(state)

      {:poll_for_decisions} ->
        state = poll_for_decisions(state)
        run(state)

      {:decision, instance, {key, value}} ->
        if instance == state.last_instance do
          # Update the data store and notify the sender if it matches the pending instance
          {_instance, sender} = state.pending
          new_data_store = Map.put(state.data_store, key, value)
          send(sender, {:write_ack, key, value})
          state = %{state | data_store: new_data_store, pending: {0, nil}}
        end
        run(state)
    end
  end

  defp poll_for_decisions(state) do
    send(state.pax_pid, {:get_decision, state.last_instance, self()})
    receive do
      {:decision, instance, {key, value}} when instance == state.last_instance ->
        IO.puts("#{state.name}: Decided value #{inspect(value)} for key #{inspect(key)} in instance #{instance}")
        new_data_store = Map.put(state.data_store, key, value)
        %{state | data_store: new_data_store, pending: {0, nil}}
      after
        1000 ->
          IO.puts("#{state.name}: No decision yet for instance #{state.last_instance}")
          state
    end
  end

  defp wait_for_reply(_, 0), do: nil
  defp wait_for_reply(r, attempt) do
    msg = receive do
      msg -> msg
      after 1000 ->
        send(r, {:poll_for_decisions})
        nil
    end
    if msg, do: msg, else: wait_for_reply(r, attempt - 1)
  end
end
