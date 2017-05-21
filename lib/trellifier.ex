defmodule Trellifier do
  use Application
  require Logger

  @trello_user "alexbird5"

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

  def notify_goals(args) do
    [board, list] = args
    {:ok, goals} = Trello.cards(@trello_user, board, list, 3)
    {:ok, accomplished} = Trello.cards(@trello_user, board, "Accomplished", -1)

    body = """
    #{Enum.map(goals, &("G: " <> &1["name"])) |> Enum.join("\n")}
    Accs: #{Enum.count(accomplished)}
    """

    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def notify_top_n(args) do
    [board, lists] = args
    cards = lists
            |> Enum.chunk(2, 2, [])
            |> Enum.map(fn([list_name, n])->
              [list_name, String.to_integer(n)]
            end)
            |> Enum.flat_map(fn([list_name, n])->
              {:ok, more_cards} = Trello.cards(@trello_user, board, list_name, n)
              more_cards
            end)

    body = case cards do
      []  ->
        "you must be productive. 0 things to do!"
      bod ->
        Enum.map(bod, &("- " <> &1["name"])) |> Enum.join("\n")
    end

    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def notify_progress(_args) do
    {:ok, done} = Trello.cards(@trello_user, "Todo", "Done", -1)
    {:ok, doing} = Trello.cards(@trello_user, "Todo", "Doing", -1)
    {:ok, today} = Trello.cards(@trello_user, "Todo", "Today", -1)
    {:ok, this_week} = Trello.cards(@trello_user, "Todo", "This Week", -1)
    {:ok, vel} = Trello.velocity(@trello_user, "Todo", "Done")
    {:ok, quarter} = Trello.cards(@trello_user, "Todo", "2017-Q2", -1)

    total = Enum.reduce([done, doing, today, this_week], 0, fn(x,acc)-> Enum.count(x) + acc end)

    body = """
    #{Enum.count(this_week)}-#{Enum.count(doing)}-#{Enum.count(done)}/#{total}
    vel: #{:io_lib.format("~.1f", [vel])}
    Q:   #{Enum.count quarter}
    """

    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def refresh_schedules() do
    Logger.info "refresh_schedules"
    {:ok, trello_jobs} = Trello.schedules(@trello_user, "Trellifier", "Schedules")

    quantum_jobs = Quantum.jobs

    del = schedules_to_delete(trello_jobs, quantum_jobs)
          |> Enum.reject(fn(e)-> e == nil end)
    start = schedules_to_start(trello_jobs, quantum_jobs)

    Enum.each del, fn(job)->
      Logger.info "deleting quantum job #{job}"
      Quantum.delete_job(job)
    end

    Enum.each start, fn(job)->
      Logger.info "starting quantum job #{job}"
      Quantum.add_job(job, Keyword.get(trello_jobs, job))
    end

    curr = Quantum.jobs |> Keyword.keys |> Enum.reject(fn(e)-> e == nil end)
    Enum.each curr, fn(e)->
      Logger.info "quantum job #{e} is running"
    end
  end

  defp schedules_to_delete(trello_jobs, quantum_jobs) do
    job_set_difference(quantum_jobs, trello_jobs)
  end

  defp schedules_to_start(trello_jobs, quantum_jobs) do
    job_set_difference(trello_jobs, quantum_jobs)
  end

  defp job_set_difference(jobs_a, jobs_b) do
    names_a = jobs_a |> Keyword.keys |> MapSet.new
    names_b = jobs_b |> Keyword.keys |> MapSet.new
    MapSet.difference(names_a, names_b)
  end
end
