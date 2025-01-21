defmodule Paxos do
  def start(name, participants) do

    if Process.whereis(name) do
      Process.unregister(name)
    end


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

  def init(name, participants) do
    state = %{
      name: name,
      participants: participants,
      quorum_size: div(length(participants), 2) + 1,
      proposals: %{},
      decisions: %{},
      promises: %{},
      accepts: %{},
      ballot_nums: %{},
      a_bals: %{},
      a_vals: %{}
    }

    Process.register(self(), name)
    run(state)
  end

  defp run(state) do
    new_state = receive do
      {:propose, inst, value, sender} ->
        case state.decisions[inst] do
          nil ->
            # Start Prepare phase
            current_bal = Map.get(state.ballot_nums, inst, 0)
            new_bal = current_bal + 1
            state = put_in(state.ballot_nums[inst], new_bal)
            broadcast(state.participants, {:prepare, inst, new_bal, state.name})
            %{state |
              proposals: Map.put(state.proposals, inst, {value, sender}),
              promises: Map.put(state.promises, inst, [])}

          decision ->
            # Already decided
            send(sender, {:decision, inst, decision})
            state
        end

      {:prepare, inst, bal, sender} ->
        current_a_bal = Map.get(state.a_bals, inst, 0)
        if bal > current_a_bal do
          current_a_val = Map.get(state.a_vals, inst)
          state = %{state |
            a_bals: Map.put(state.a_bals, inst, bal),
            a_vals: Map.put(state.a_vals, inst, current_a_val)
          }
          send(sender, {:promise, inst, bal, current_a_bal, current_a_val, state.name})
          state
        else
          send(sender, {:nack, inst, bal, state.name})
          state
        end

      {:promise, inst, bal, a_bal, a_val, sender} ->
        current_bal = Map.get(state.ballot_nums, inst, 0)
        if bal == current_bal do
          promises = Map.get(state.promises, inst, []) ++ [{a_bal, a_val, sender}]
          state = %{state | promises: Map.put(state.promises, inst, promises)}

          if length(promises) >= state.quorum_size do
            # Quorum reached, select a value to propose
            {_, value_to_propose, _} =
              Enum.max_by(promises, fn {a_bal, _, _} -> a_bal end,
                fn -> {0, elem(Map.get(state.proposals, inst, {nil, nil}), 0), nil} end)

            # If no value was previously accepted, use the proposed value
            value_to_propose = value_to_propose || elem(Map.get(state.proposals, inst), 0)

            broadcast(state.participants, {:accept, inst, bal, value_to_propose, state.name})
            %{state | accepts: Map.put(state.accepts, inst, [])}
          else
            state
          end
        else
          state
        end

      {:accept, inst, bal, value, sender} ->
        current_a_bal = Map.get(state.a_bals, inst, 0)
        if bal >= current_a_bal do
          state = %{state |
            a_bals: Map.put(state.a_bals, inst, bal),
            a_vals: Map.put(state.a_vals, inst, value)
          }
          send(sender, {:accepted, inst, bal, state.name})
          state
        else
          send(sender, {:nack, inst, bal, state.name})
          state
        end

      {:accepted, inst, bal, sender} ->
        current_bal = Map.get(state.ballot_nums, inst, 0)
        if bal == current_bal do
          accepts = Map.get(state.accepts, inst, []) ++ [sender]
          state = %{state | accepts: Map.put(state.accepts, inst, accepts)}

          if length(accepts) >= state.quorum_size do
            # Quorum reached in Accept phase, commit the value
            {value, proposer} = Map.get(state.proposals, inst)
            broadcast(state.participants, {:commit, inst, value})
            send(proposer, {:decision, inst, value})
            handle_commit(state, inst, value)
          else
            state
          end
        else
          state
        end

      {:commit, inst, value} ->
        handle_commit(state, inst, value)

      {:get_decision, inst, sender} ->
        decision = Map.get(state.decisions, inst, nil)
        send(sender, {:decision, inst, decision})
        state
    end

    run(new_state)
  end

  defp broadcast(participants, message) do
    Enum.each(participants, fn participant ->
      if participant != self() do
        send(:global.whereis_name(participant), message)
      end
    end)
  end

  defp handle_commit(state, inst, value) do
    %{state | decisions: Map.put(state.decisions, inst, value)}
  end
end