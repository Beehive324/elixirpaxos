defmodule PointLinks do
  def init(name, processes) do
    Process.register(self(), name)
    run(%{
      processes: processes,
      delivered: MapSet.new()
    })
  end

  def send_message(pid, q, m) do
    send(pid, {:send, q, m})
  end

  defp run(state) do
    new_state = receive do
      {:send, q, m} ->
        send(q, {:deliver, {self(), m}})
        state

      {:deliver, {p, m}} = message ->
        if not MapSet.member?(state.delivered, message) do
          new_state = %{state | delivered: MapSet.put(state.delivered, message)}
          send(self(), {p, m})
          new_state
        else
          state
        end
    end

    run(new_state)
  end
end