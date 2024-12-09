defmodule PointLinks do

  def start(name, processes) do
    pid = spawn(PointLinks, :init, [name, processes])
    pid
  end


  def init(name, processes) do
    state =%{
    name: name,
    processes: processes,
    delivered: %MapSet{}
    }
    run(state)
  end

   def run(state) do

    state = receive do
      {:send, {q, m}} ->
        self.send(q, {:deliver, {self(), m}})
        state

        {:deliver, {p, m}} ->
        state = if m not in state.delivered do
          state = %{state | delivered: MapSet.put(state.delivered, m)}
          self.send({p, m})
        end

        state
    end
end

end