defmodule TrellifierTest do
  use ExUnit.Case, async: true

  setup do
    %{}
  end

  test "it should know when to delete a schedule", %{} do
    trello_jobs = [
      card_id_foo: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
      card_id_bar: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
    ]
    quantum_jobs = [
      card_id_foo: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
      card_id_quux: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
    ]

    del = Trellifier.schedules_to_delete(trello_jobs, quantum_jobs) |> MapSet.to_list
    assert del == [:card_id_quux]
  end

  test "it should know when to start a schedule", %{} do
    trello_jobs = [
      card_id_foo: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
      card_id_bar: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
    ]
    quantum_jobs = [
      card_id_foo: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
      card_id_quux: %Quantum.Job{args: [], name: nil, nodes: nil, overlap: true, pid: nil, schedule: "0 8 * * *", state: :active, task: {"Trellifier", :notify_top_n}, timezone: "America/Los_Angeles"},
    ]

    start = Trellifier.schedules_to_start(trello_jobs, quantum_jobs) |> MapSet.to_list
    assert start == [:card_id_bar]
  end
end
