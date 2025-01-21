defmodule Paxos do


  def start(name, participants) do
    # Unregister if the process name is already taken
    if Process.whereis(name) do
      Process.unregister(name)
    end

    # Spawn and register the Paxos process
    pid = spawn(Paxos, :init, [name, participants])

    case :global.re_register_name(name, pid) do
      :yes -> pid
      :no -> nil
    end
  end

  def propose(pid, inst, value, timeout) do
    send(pid, {:propose, inst, value, self()})

    receive do
      {:decision, ^inst, decision_value} -> {:decision, decision_value}
      {:abort, ^inst} -> {:abort}
    after
      timeout -> {:timeout}
    end
  end

  def get_decision(pid, inst, timeout) do
    send(pid, {:get_decision, inst, self()})

    receive do
      {:decision, ^inst, value} -> value
    after
      timeout -> nil
    end
  end

  # ==================== Internal Implementation ====================

  def init(name, participants) do
    state = %{
      name: name,
      participants: participants,
      quorum_size: div(length(participants), 2) + 1,
      proposals: %{}, # Tracks proposals by instance
      decisions: %{}, # Tracks decided values by instance
      promises: %{}, # Tracks promises received in Prepare phase
      accepts: %{},  # Tracks accept messages in Accept phase
      bal: 0,        # Current ballot number
      a_bal: 0,      # Highest promised ballot number
      a_val: nil     # Value associated with the highest promised ballot
    }

    Process.register(self(), name)
    run(state)
  end

  defp run(state) do
    receive do
      {:propose, inst, value, sender} ->
        state = handle_propose(state, inst, value, sender)
        run(state)

      {:prepare, inst, bal, sender} ->
        state = handle_prepare(state, inst, bal, sender)
        run(state)

      {:promise, inst, bal, a_bal, a_val, sender} ->
        state = handle_promise(state, inst, bal, a_bal, a_val, sender)
        run(state)

      {:accept, inst, bal, value, sender} ->
        state = handle_accept(state, inst, bal, value, sender)
        run(state)

      {:accepted, inst, bal, sender} ->
        state = handle_accepted(state, inst, bal, sender)
        run(state)

      {:commit, inst, value} ->
        state = handle_commit(state, inst, value)
        run(state)

      {:get_decision, inst, sender} ->
        decision = Map.get(state.decisions, inst, nil)
        send(sender, {:decision, inst, decision})
        run(state)
    end
  end

  # ==================== Handle Events ====================

  defp handle_propose(state, inst, value, sender) do
    case state.decisions[inst] do
      nil ->
        # Start Prepare phase
        new_bal = state.bal + 1
        state = %{state | bal: new_bal}
        broadcast(state.participants, {:prepare, inst, new_bal, state.name})
        %{state | proposals: Map.put(state.proposals, inst, {value, sender}), promises: Map.put(state.promises, inst, [])}

      decision ->
        # Already decided
        send(sender, {:decision, inst, decision})
        state
    end
  end

  defp handle_prepare(state, inst, bal, sender) do
    if bal > state.a_bal do
      state = %{state | a_bal: bal}
      send(sender, {:promise, inst, bal, state.a_bal, state.a_val, state.name})
    else
      send(sender, {:nack, inst, bal, state.name})
    end

    state
  end

  defp handle_promise(state, inst, bal, a_bal, a_val, sender) do
    if bal == state.bal do
      promises = Map.get(state.promises, inst, []) ++ [{a_bal, a_val, sender}]
      state = %{state | promises: Map.put(state.promises, inst, promises)}

      if length(promises) >= state.quorum_size do
        # Quorum reached, select a value to propose
        highest_a_val = Enum.max_by(promises, fn {a_bal, _, _} -> a_bal end, fn -> {0, state.proposals[inst] |> elem(0)} end)
        value_to_propose = elem(highest_a_val, 1)
        broadcast(state.participants, {:accept, inst, bal, value_to_propose, state.name})
        state = %{state | accepts: Map.put(state.accepts, inst, [])}
      end

      state
    else
      state
    end
  end

  defp handle_accept(state, inst, bal, value, sender) do
    if bal >= state.a_bal do
      state = %{state | a_bal: bal, a_val: value}
      send(sender, {:accepted, inst, bal, state.name})
    else
      send(sender, {:nack, inst, bal, state.name})
    end

    state
  end

  defp handle_accepted(state, inst, bal, sender) do
    accepts = Map.get(state.accepts, inst, []) ++ [sender]
    state = %{state | accepts: Map.put(state.accepts, inst, accepts)}

    if length(accepts) >= state.quorum_size do
      # Quorum reached in Accept phase, commit the value
      {value, _} = state.proposals[inst]
      broadcast(state.participants, {:commit, inst, value})
      state = handle_commit(state, inst, value)
    end

    state
  end

  defp handle_commit(state, inst, value) do
    %{state | decisions: Map.put(state.decisions, inst, value)}
  end


  defp broadcast(participants, message) do
    Enum.each(participants, fn participant ->
      if participant != self() do
        send(:global.whereis_name(participant), message)
      end
    end)
  end
end