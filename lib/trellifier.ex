defmodule Trellifier do
  use Application
  require Logger

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

  def notify_goals() do
    {:ok, goals} = Trello.cards("alexbird5", "Goals", "Goals", 3)
    {:ok, accomplished} = Trello.cards("alexbird5", "Goals", "Accomplished", -1)

    body = """
    #{Enum.map(goals, &("G: " <> &1["name"])) |> Enum.join("\n")}
    Accs: #{Enum.count(accomplished)}
    """

    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def notify_bird() do
    {:ok, doing} = Trello.cards("alexbird5", "Todo", "Doing", -1)
    {:ok, this_week} = Trello.cards("alexbird5", "Todo", "Today", 3)
    body = case doing ++ this_week do
      []  -> "you must be productive. 0 things to do!"
      bod -> Enum.map(bod, &("- " <> &1["name"])) |> Enum.join("\n")
    end
    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def notify_progress() do
    {:ok, done} = Trello.cards("alexbird5", "Todo", "Done", -1)
    {:ok, doing} = Trello.cards("alexbird5", "Todo", "Doing", -1)
    {:ok, today} = Trello.cards("alexbird5", "Todo", "Today", -1)
    {:ok, this_week} = Trello.cards("alexbird5", "Todo", "This Week", -1)
    {:ok, vel} = Trello.velocity("alexbird5", "Todo", "Done")
    {:ok, quarter} = Trello.cards("alexbird5", "Todo", "2017-Q2", -1)

    total = Enum.reduce([done, doing, today, this_week], 0, fn(x,acc)-> Enum.count(x) + acc end)

    body = """
    #{Enum.count(this_week)}-#{Enum.count(doing)}-#{Enum.count(done)}/#{total}
    vel: #{:io_lib.format("~.1f",  [vel])}
    Q:   #{Enum.count quarter}
    """

    {:ok, _} = SmsSender.send_sms(System.get_env("ALEX_BIRD_CELL"), body)
  end

  def refresh_schedules() do
    Logger.info "refresh_schedules"
    {:ok, trello_jobs} = Trello.schedules("alexbird5", "Trellifier", "Schedules")
    quantum_jobs = Quantum.jobs
    del = schedules_to_delete(trello_jobs, quantum_jobs) |> Enum.reject(fn(e)-> e == nil end)
    start = schedules_to_start(trello_jobs, quantum_jobs)

    Enum.each del, fn(e)->
      Logger.info "deleting quantum job #{e}"
      Quantum.delete_job(e)
    end

    Enum.each start, fn(e)->
      Logger.info "starting quantum job #{e}"
      Quantum.add_job(e, Keyword.get(trello_jobs, e))
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
