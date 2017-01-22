defmodule SmsSender do
  use GenServer

  @from_number Application.get_env(:trellifier, :from_number)

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def send_sms(to, body) do
    GenServer.call(__MODULE__, {:send_sms, to, body}, 30000)
  end


  #
  # server callbacks
  #

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:send_sms, to, body}, _from, state) do
    {:reply, send_twilio_sms(to, body), state}
  end

  defp send_twilio_sms(to, body) do
    {:ok, _} = ExTwilio.Message.create(
      to: to,
      from: @from_number,
      body: body,
    )
  end
end
