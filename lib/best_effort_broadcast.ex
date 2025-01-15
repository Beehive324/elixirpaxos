defmodule BestEffortBroadcast do

  def start(name, processes) do
    pid = spawn(BestEffortBroadcast, :init, [name ,processes])
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
    IO.puts "registered #{name}"
    pid
  end

  def init() do
    state = %{
    delivered: %MapSet{}
    }
    beb_broadcast(state)
  end


  def beb_broadcast(state) do
    state = receive do
      {:broadcast, m} ->
        if m not in state.delivered do
          send(state.processes, m)
        end
        state
      {:deliver, m} ->
      state
    end

  end
end
