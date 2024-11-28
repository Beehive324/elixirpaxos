defmodule EventualLeaderDetector do

  def start(name, processes) do
    pid = spawn(EventualLeaderDetector, :init, [name processes])
    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
    IO.puts "registered #{name}"
    pid
  end


  def init(name, processes) do
    state = %{
      suspected: %MapSet{},
      leader: 0
    }
    run(state)
  end


  def run(state) do
    state = receive do
      {:suspect, proc} ->
          state = %{ suspected | suspected: MapSet.delete(state.suspected,proc)}
          state
      {:restore, proc} ->
          state = %{ state| suspected: MapSet.delete(state.suspected,proc)}
          state

    end



  end

  end
