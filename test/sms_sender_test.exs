defmodule SmsSenderTest do
  use ExUnit.Case, async: true

  setup do
    SmsSender.start_link
    {:ok,
      to: "+14147376185",
      body: "ExUnit test",
    }
  end

  test "sends an sms", %{to: to, body: body} do
    {status, _} = SmsSender.send_sms(to, body)
    assert status == :ok
  end
end
