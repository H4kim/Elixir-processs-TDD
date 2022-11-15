defmodule Poll do
  defstruct candidates: []

  def new(candidates \\ []) do
    %Poll{candidates: candidates}
  end

  # Public interface
  def start_link() do
    spawn(Poll, :run, [new()])
  end

  def add_candidate(pid, name) do
    send(pid, %{message_type: "add_candidate", name: name})
  end

  def candidates(pid) do
    send(pid, %{message_type: "get_candidates", sender: self()})

    receive do
      {_pid, candidates} ->
        candidates
    after
      5_000 -> nil
    end
  end

  def vote(pid, name) do
    send(pid, %{message_type: "vote", name: name})
  end

  def exit(pid) do
    send(pid, %{message_type: :exit})
  end

  # Process implementation details
  def run(state) do
    receive do
      message ->
        case handle_messages(message, state) do
          :exit -> :exit
          state -> run(state)
        end
    end
  end

  def handle_messages(%{message_type: "add_candidate", name: name}, candidates_struct) do
    candidate = Candidate.new(name)
    candidates = [candidate | candidates_struct.candidates]
    Map.put(candidates_struct, :candidates, candidates)
  end

  def handle_messages(%{message_type: "get_candidates", sender: sender}, candidates_struct) do
    send(sender, {self(), candidates_struct.candidates})
    candidates_struct
  end

  def handle_messages(%{message_type: "vote", name: name}, candidates_struct) do
    candidates =
      Enum.map(candidates_struct.candidates, fn
        candidate when candidate.name == name -> Map.put(candidate, :votes, candidate.votes + 1)
        candidate -> candidate
      end)

    Map.put(candidates_struct, :candidates, candidates)
  end

  def handle_messages(%{message_type: :exit}), do: :exit
end
