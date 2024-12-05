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
    last: 0,
    ts: 0,
    name: name,
    processes: processes
    }

    run(state)
  end

  def run(state) do
    state = receive do
      {:trust, } ->
      #trusted :=p
      #if p = self then
      #ts := ts + N
      #trigger <beb, Broadcast>
        state

      {:deliver, {ts}} ->
      state
        #if l = trusted and newts then
        #assings lastss := newts
        #triger startEpoch
        #else send nack

      {:deliver} ->
      state

    end
  end
end