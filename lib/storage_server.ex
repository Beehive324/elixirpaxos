defmodule StorageServer do
    def start(name, paxos_proc) do
        pid = spawn(StorageServer, :init, [name, paxos_proc])
        pid = case :global.re_register_name(name, pid) do
            :yes -> pid
            :no  -> nil
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
            balance: 0,

        }
        # Ensures shared destiny (if one of the processes dies, the other one does too)
        # Process.link(state.pax_pid)
        run(state)
    end

    # Get pid of a Paxos instance to connect to
    defp get_paxos_pid(paxos_proc) do
        case :global.whereis_name(paxos_proc) do
                pid when is_pid(pid) -> pid
                :undefined -> raise(Atom.to_string(paxos_proc))
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
        if msg, do: msg, else: wait_for_reply(r, attempt-1)
    end







    def run(state) do

    end


    defp poll_for_decisions(state) do

    end

end