Code.require('best_effort_broadcast.ex')
Code.require('Eventual_leader_detector.ex')

defmodule EpochChange do
   def start(name, processes) do
    pid = spawn(EpochChange, :init, [name processes])
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
    IO.puts "registered #{name}"
    pid
  end


  def init(name, processes) do
    state = %{
    trusted: 0,
    last: 0, #hashmap containing timestamp of the last epoch it started
    lastts: 0, #
    ts: 0,
    name: name,
    processes: processes,
    ts: 0,
    lastts: get_process_rank(name, processes)
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

  defp evl() do
    EventualLeaderDetector.evl(Process.whereis(get_evl_name()))
  end



  def run(state) do
    state = receive do
      {:trust,{process} } ->
      if trusted = p do
        state = { state | state.ts + Enum.count(processes)}
        beb_broadcast({processes}, ts)
        state
      end
      #trusted :=p
      #if p = self then
      #ts := ts + N
      #trigger <beb, Broadcast>
        state

      {:deliver, {l}} ->
      state = if l == trusted and l = newts and newts > lastts do
        lastts = newts
        start_epoch(name, processes)
        state

      end
      self.send((l))
      state

      end



      {:deliver} ->
      if trusted == self() do
        state = { state | state.ts + Enum.count(processes)}
        beb_broadcast(ts, newepoch)
      end


    end
  end

  defp get_process_rank(name, processes) do
    Enum.find_index(processes, &(&1 == name)) || 0
  end


  defp start_epoch(name, processes) do

  end




end