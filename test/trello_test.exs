defmodule TrelloTest do
  use ExUnit.Case, async: true

  setup do
    Trello.start_link
    {:ok,
      member: "alexbird5",
      board: "Todo",
      list: "This Week",
      n: 3,
    }
  end

  test "gets trello cards", %{member: member, board: board, list: list, n: n} do
    {status, cards} = Trello.cards(member, board, list, n)
    #IO.inspect cards
    assert status == :ok
    assert length(cards) == n
  end
end
