
"""
epoch-change -> responsible for triggering the sequence of epochs
at all processes.
Epoch consensus abstraction, goal is to reach consensus in a given epoch
implemented in a fail-noisy model, relying on an eventual leader detector
leader ℓ0
"""

defmodule EpochChange do
   def start(name, processes) do #start a process
    pid = spawn(EpochChange, :init, [name, processes]) #spawning a processes
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
    IO.puts "registered #{name}"
    pid
  end

  def init(name, processes) do
    start_beb(name)
    start_evl(name)

    state = %{
    name: name,
    processes: processes,
    trusted: nil,
    lastts: 0,
    ts: get_process_rank(name, processes)
    }
    run(state)
  end

   #Synching BestEffort Broadcast
  defp get_beb_name() do
     {:registered_name, parent} = Process.info(self(), :registered_name)
     String.to_atom(Atom.to_string(parent) <> "_beb")
  end

  defp start_beb(name) do
    Process.register(self(), name)
    pid = spawn(BestEffortBroadcast, :init, [])
    Process.register(pid, get_beb_name())
    Process.link(pid)
  end

  defp beb_broadcast(m, dest) do
    BestEffortBroadcast.beb_broadcast(Process.whereis(get_beb_name()), m, dest)
  end

  #Synching Eventual Leader Detector
  defp get_evl_name() do
     {:registered_name, parent} = Process.info(self(), :registered_name)
     String.to_atom(Atom.to_string(parent) <> "_evl")
  end

  defp start_evl(name) do
    Process.register(self(), name)
    pid = spawn(EventualLeaderDetector, :init, [])
    Process.register(pid, get_evl_name())
    Process.link(pid)
  end

  defp eventual_leader_detector(processes) do
    EventualLeaderDetector.eventual_leader_detector(Process.whereis(get_evl_name()))
  end

  def run(state) do
    state = receive do
      {:trust, p} ->
      state = %{state | trusted: p}
      if p == self() do
        state = %{state | ts: state.ts + Enum.count(state.processes)}
        beb_broadcast({:new_epoch, state.ts}, state.processes)
        state
      end

      {:deliver, {:new_epoch, newts}} ->
      state = if state.l == state.trusted and state.l == state.newts and state.newts > state.lastts do
        state = %{state | lastss: state.newts}
        start_epoch(state.name, state.processes)
        state
      end

      send(state.processes, {self(), state.l})
      state

      {:check} ->
      if state.trusted == self() do
        state = %{ state | ts: state.ts + Enum.count(state.processes)}
        beb_broadcast({:new_epoch, state.ts}, state.processes)
      end
    end
  end

  defp get_process_rank(name, processes) do
    Enum.find_index(processes, &(&1 == name)) || 0
  end

  defp start_epoch(name, processes) do

    send(self(), {:epoch_started, name, processes})

  end

end