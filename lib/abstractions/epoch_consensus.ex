defmodule EpochConsensus do


  """
epoch consensus abstraction, whose goal
is to reach consensus in a given epoch

"""
  def start(name, processes) do
    pid = spawn(EpochConsensus,:init, [name, processes])
    case :global.re_register_name(name,pid) do
      :yes -> pid
      :no -> :error
      IO.puts "registered_name #{name}"
      pid
    end
  end


  def init(name, processes) do

    state = %{
      val: 0,
    valts: 0,
    tmpval: 0,
    states: 0,
    accepted: 0


    }
    run(state)
  end


  def run(state) do

    state = receive do

      {:propose} ->
      state

      {:deliver} ->
      state

      {:deliver} ->
      state

      #if states > N/ 2
      # do (ts, v) highest states


      {:deliver} ->
      state

      {:deliver} ->
      state

      {:deliver} ->
      state

      #upon accepted

      {:deliver} ->
      state

      {:abort} ->
      state

    end

  end







  end
