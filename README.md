# Elixirpaxos

**Abortable Paxos Uniform Consensus Algorith Implementation using Elixir**

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



## Abstractions(Introduction To Reliable and Secure programs)

# Epoch Consensus
Module:
Name: EpochConsensus, instance ep, with timestamp ts and leader process l

Events:
Request: <ep, Propose | v> : Propose values v for epoch consensus.Executed only by leader l

Request: <ep, Abort >: Aborts epoch consensus

Response: <ep, Decide | v >: Outputs a decide value v of epoch consensus

Response: <ep, Aborted | state >: Signals that epoch consensus has completed the abort and outputs internal state state





