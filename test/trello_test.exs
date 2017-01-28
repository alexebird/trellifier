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

  test "it should get trello cards", %{member: member, board: board, list: list, n: n} do
    {status, cards} = Trello.cards(member, board, list, n)
    assert status == :ok
    #IO.inspect cards
    assert length(cards) == n
  end

  test "it should get the schedules", %{member: member} do
    {status, scheds} = Trello.schedules(member, "Trellifier", "Schedules")
    #IO.inspect scheds
    assert status == :ok
  end

  test "it should get the velocity", %{member: member} do
    {status, lists} = Trello.velocity(member, "Todo", "Done")
    IO.inspect lists
    assert status == :ok
  end
end
