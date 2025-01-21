# Elixirpaxos

**Abortable Paxos Uniform Consensus Algorithm Implementation using Elixir**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixirpaxos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixirpaxos, "~> 0.1.0"}
  ]
end
```

## Safety and Liveness Properties
Safety Property:

Only a value that has been proposed may be chosen

Only a single value is chosen

A process never learns that a value has been chosen unless it has been chosen

Liveness Property:

Some proposed value is eventually chosen


# API
## propose(pid, inst, value, t)

Proposes a value.

Parameters:

pid: Process identifier of the Paxos replica.

inst: Identifier for the consensus instance.

value: Value to be proposed.

t: Timeout in milliseconds.

Returns:

{:decision, v} if a value v has been decided.

{:abort} if the proposal was interrupted by a higher ballot.

{:timeout} if no decision was reached before the timeout.

## get_decision(pid, inst, t)

Description: Retrieves a decision

Parameters:

pid: Process identifier of the Paxos replica.

inst: Identifier for the consensus instance.

t: Timeout in milliseconds.

Returns:

The decided value if available.

nil if no decision is available within the timeout.


## Usage (using mix)
1. To run the project cd into lib:
```bash
cd lib
```
2. Compile the project using mix:
```bash
mix compile
```
## Usage (using iex)
1. Go into the lib folder and run the iex command:
```bash
iex
```
2. Compile the following files:
```bash
c "paxos.ex"

c "beb.ex"

c "eld.ex"

```

# Implementation: Storage Server

The further abstraction we chose to implement on top of Paxos is a storage server,
the main goal here is to ensure that data replicas remain consistent across nodes in a distributed environment 
through providing consistent key-value storage across nodes.

## Features:

Initiates a Paxos proposal to store a key-value pair.

### API Methods:
#### put(key, value):
- Stores a key-value pair in the distributed key-value store.
- Ensures consistency using Paxos consensus before committing the change

##### get(key)
- Retrieves the value associated with a key from the distributed key-value store
- Return the value if it exists or None if the key was not found


## Testing
1. Go into the test folder directory:
```bash
cd test
```

2. Start Erlang port mapper:
```bash
epmd -daemon
```

3. Run Tests using the following command:
```bash
iex test_script.exs
```






