defmodule EpochConsensus do

  """
epoch consensus abstraction, whose goal
is to reach consensus in a given epoch

Module: EpochConsensus, instance ep , with timestamp ts and leader process l

Events:
    Requests: <Propose | v>
    Request: <ep, Abort> : Aborts epoch consensus
    Indication: <ep, Decide | v> Outputs a decided value v of epoch consensus
    Indication: <ep, Aborted | state>: Signlas that epoch consensus has completed the abort and outputs internal state state

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
