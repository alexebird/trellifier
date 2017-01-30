defmodule Trello do
  use GenServer

  @base_url  "https://api.trello.com/1"
  @api_key   System.get_env("TRELLO_API_KEY")
  @api_token System.get_env("TRELLO_API_TOKEN")

  #
  # client api
  #

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def cards(member, board, list, n) do
    GenServer.call(__MODULE__, {:cards, member, board, list, n}, 30000)
  end

  def schedules(member, board, list) do
    GenServer.call(__MODULE__, {:schedules, member, board, list}, 30000)
  end

  def velocity(member, board, list) do
    GenServer.call(__MODULE__, {:velocity, member, board, list}, 30000)
  end


  #
  # server callbacks
  #

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:cards, member, board, list, n}, _from, state) do
    {:reply, trello_get_cards(member, board, list, n), state}
  end

  def handle_call({:schedules, member, board, list}, _from, state) do
    {:reply, trello_get_schedules(member, board, list), state}
  end

  def handle_call({:velocity, member, board, list}, _from, state) do
    {:reply, trello_get_velocity(member, board, list), state}
  end


  #
  # trello client
  #

  def trello_get_schedules(member, board, list) do
    {:ok, cards} = trello_get_cards(member, board, list, -1)
    scheds = Enum.map(cards, &make_quantum/1)
    {:ok, scheds}
  end

  def make_quantum(card) do
    [stars, func]  = Enum.chunk(String.split(card["name"], ~r/\s/), 5, 5, [])
    [module, func] = String.split(List.first(func), ".")

    {
      String.to_atom("card_id_" <> card["id"]),
      %Quantum.Job{
        schedule: Enum.join(stars, " "),
        timezone: "America/Los_Angeles",
        task:     {module, String.to_atom(func)}}
    }
  end

  def trello_get_velocity(member, board, list) do
    boards = trello_get_member_boards!(member)
    bid = find(boards, board)["id"]
    weeks = 3
    vel = trello_get_board_lists!(bid, "closed")
          |> filter(list)
          |> Enum.take(weeks)
          |> Enum.map(&(Enum.count &1["cards"]))
          |> Enum.sum
    #IO.inspect vel
    {:ok, vel / (weeks/1)}
  end

  def trello_get_cards(member, board, list, n) do
    boards = trello_get_member_boards!(member)
    bid = find(boards, board)["id"]
    lists = trello_get_board_lists!(bid)
    list = find(lists, list)
    cards = case n do
      -1 -> list["cards"]
      _ -> Enum.take(list["cards"], n)
      end
    {:ok, cards}
  end

  def trello_get_board_lists!(board_id, filter \\ "open") do
    get!("/boards/#{board_id}/lists",
         [{"fields", "name"},
          {"cards", "open"},
          {"filter", filter},
          {"card_fields", "name,dateLastActivity,desc,due,shortUrl,pos"}])
  end

  def find(coll, name) do
    Enum.find coll, fn(e)->
      String.downcase(e["name"]) =~ String.downcase(name)
    end
  end

  def filter(coll, name) do
    Enum.filter coll, fn(e)->
      String.downcase(e["name"]) =~ String.downcase(name)
    end
  end

  def trello_get_member_boards!(member) do
    get!("/members/#{member}/boards",
         [{"fields", "name"},
          {"card_fields", "name"}])
  end

  def get!(url, query \\ []) do
    query = query ++ [{"key", @api_key}, {"token", @api_token}]
    HTTPoison.get!("#{@base_url}/#{url}?#{query_string(query)}")
      |> Map.get(:body)
      |> Poison.decode!
  end

  def query_string(pairs) do
    Enum.map(pairs, fn({k,v})->
      "#{k}=#{v}"
    end) |> Enum.join("&")
  end
end
