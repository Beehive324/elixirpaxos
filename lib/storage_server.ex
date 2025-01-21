defmodule StorageServer do
  @moduledoc """
  A distributed storage server implementation that uses Paxos for consensus.
  Provides consistent key-value storage across multiple nodes.
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
      data_store: %{}
    }

    # Ensures shared destiny (if one of the processes dies, the other does too)
    Process.link(state.pax_pid)
    run(state)
  end

  defp get_paxos_pid(paxos_proc) do
    case paxos_proc do
      pid when is_pid(pid) -> pid
      :undefined -> raise("Paxos process is not registered")
      _ -> raise("Invalid Paxos process reference")
    end
  end

  def put(pid, key, value) do
    send(pid, {:put, self(), key, value})
    receive do
      {:put_ok} -> :ok
      {:put_failed} -> :fail
      {:abort} -> :fail
    after
      5000 -> :timeout
    end
  enddefmodule StorageServer do
  @moduledoc """
  A distributed storage server implementation that uses Paxos for consensus.
  Provides consistent key-value storage across multiple nodes.
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
      data_store: %{}
    }

    # Ensures shared destiny (if one of the processes dies, the other does too)
    Process.link(state.pax_pid)
    run(state)
  end

  defp get_paxos_pid(paxos_proc) do
    case paxos_proc do
      pid when is_pid(pid) -> pid
      :undefined -> raise("Paxos process is not registered")
      _ -> raise("Invalid Paxos process reference")
    end
  end

  def put(pid, key, value) do
    send(pid, {:put, self(), key, value})
    receive do
      {:put_ok} -> :ok
      {:put_failed} -> :fail
      {:abort} -> :fail
    after
      5000 -> :timeout
    end
  end

  def get(pid, key) do
    send(pid, {:get, self(), key})
    receive do
      {:get_reply, ^key, value} -> {:ok, value}
      {:key_not_found, ^key} -> :not_found
    after
      5000 -> :timeout
    end
  end

  def run(state) do
    state = receive do
      {:put, client, key, value} ->
        state = poll_for_decisions(state)
        if Paxos.propose(state.pax_pid, state.last_instance + 1, {:put, key, value}, 1000) == {:abort} do
          send(client, {:abort})
        else
          %{state | pending: {state.last_instance + 1, client}}
        end

      {:get, client, key} ->
        state = poll_for_decisions(state)
        case Map.get(state.data_store, key) do
          nil -> send(client, {:key_not_found, key})
          value -> send(client, {:get_reply, key, value})
        end
        state

      {:poll_for_decisions} ->
        poll_for_decisions(state)

      _ -> state
    end

    run(state)
  end

  defp poll_for_decisions(state) do
    case Paxos.get_decision(state.pax_pid, i = state.last_instance + 1, 1000) do
      {:put, key, value} ->
        state = case state.pending do
          {^i, client} ->
            send(client, {:put_ok})
            %{state | pending: {0, nil}, data_store: Map.put(state.data_store, key, value)}

          _ ->
            %{state | data_store: Map.put(state.data_store, key, value)}
        end
        poll_for_decisions(%{state | last_instance: i})

      nil -> state
    end
  end
end


  def get(pid, key) do
    send(pid, {:get, self(), key})
    receive do
      {:get_reply, ^key, value} -> {:ok, value}
      {:key_not_found, ^key} -> :not_found
    after
      5000 -> :timeout
    end
  end

  def run(state) do
    state = receive do
      {:put, client, key, value} ->
        state = poll_for_decisions(state)
        if Paxos.propose(state.pax_pid, state.last_instance + 1, {:put, key, value}, 1000) == {:abort} do
          send(client, {:abort})
        else
          %{state | pending: {state.last_instance + 1, client}}
        end

      {:get, client, key} ->
        state = poll_for_decisions(state)
        case Map.get(state.data_store, key) do
          nil -> send(client, {:key_not_found, key})
          value -> send(client, {:get_reply, key, value})
        end
        state

      {:poll_for_decisions} ->
        poll_for_decisions(state)

      _ -> state
    end

    run(state)
  end

  defp poll_for_decisions(state) do
    case Paxos.get_decision(state.pax_pid, i = state.last_instance + 1, 1000) do
      {:put, key, value} ->
        state = case state.pending do
          {^i, client} ->
            send(client, {:put_ok})
            %{state | pending: {0, nil}, data_store: Map.put(state.data_store, key, value)}

          _ ->
            %{state | data_store: Map.put(state.data_store, key, value)}
        end
        poll_for_decisions(%{state | last_instance: i})

      nil -> state
    end
  end
end
