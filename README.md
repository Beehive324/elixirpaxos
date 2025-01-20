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
2. Compile all your files:
```bash
c "paxos.ex"

c "beb.ex"

c "eld.ex"
```

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






