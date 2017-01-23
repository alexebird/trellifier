defmodule Trellifier do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      #supervisor(Trellifier.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Trellifier.Endpoint, []),
      # Start your own worker by calling: Trellifier.Worker.start_link(arg1, arg2, arg3)
      # worker(Trellifier.Worker, [arg1, arg2, arg3]),
      worker(Trello, []),
      worker(SmsSender, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Trellifier.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Trellifier.Endpoint.config_change(changed, removed)
    :ok
  end

  def notify_alex_bird() do
    {:ok, doing} = Trello.cards("alexbird5", "Todo", "Doing", -1)
    {:ok, this_week} = Trello.cards("alexbird5", "Todo", "This Week", 3)
    body = Enum.map(doing ++ this_week, &("- " <> &1["name"])) |> Enum.join("\n")
    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end
end
