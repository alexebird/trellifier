defmodule TrelloTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, trello} = Trello.start_link
    {:ok, trello: trello, member: "alexbird5", board: "Todo", list: "This Week"}
  end

  test "gets trello cards", %{trello: trello, member: member, board: board, list: list} do
    {status, _} = Trello.cards(trello, member, board, list)
    assert status == :ok
  end
end
