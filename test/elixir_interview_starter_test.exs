defmodule ElixirInterviewStarterTest do
  use ExUnit.Case
  doctest ElixirInterviewStarter

  alias ElixirInterviewStarter.CalibrationService
  alias ElixirInterviewStarter.CalibrationSession

  test "it can go through the whole flow happy path" do
    assert {:ok, %CalibrationSession{session_state: :active}} =
             ElixirInterviewStarter.start("my@email.com")

    assert {:ok, %CalibrationSession{}} = ElixirInterviewStarter.start_precheck_2("my@email.com")
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
    assert {:ok, %CalibrationSession{session_state: :active}} =
             ElixirInterviewStarter.start("mytest2@email.com")

    assert {:ok, %CalibrationSession{session_state: :active, precheck_1: true}} =
             ElixirInterviewStarter.get_current_session("mytest2@email.com")
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
    assert {:ok, _session} = ElixirInterviewStarter.start("mytest3@email.com")

    assert {:error, "Invalid session state"} = ElixirInterviewStarter.start("mytest3@email.com")
  end

  test "start_precheck_2/1 starts precheck 2" do
    assert {:ok, _session} = ElixirInterviewStarter.start("mytest4@email.com")

    assert {:ok, _session} = ElixirInterviewStarter.start_precheck_2("mytest4@email.com")

    assert {:ok,
            %CalibrationSession{session_state: :finished, precheck_1: true, precheck_2: true}} =
             ElixirInterviewStarter.get_current_session("mytest4@email.com")
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
    assert {:error, "No ongoing session"} =
             ElixirInterviewStarter.start_precheck_2("mytest5@email.com")
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is not done with precheck 1" do
    precheck_1_session = %CalibrationSession{
      session_state: :precheck_1,
      precheck_1: false,
      user_email: "mytest6@email.com"
    }

    CalibrationService.start_link(
      user_email: precheck_1_session.user_email,
      session: precheck_1_session
    )

    assert {:error, "Not done with precheck 1"} =
             ElixirInterviewStarter.start_precheck_2(precheck_1_session.user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is already done with precheck 2" do
    precheck_2_session = %CalibrationSession{
      session_state: :finished,
      precheck_2: true,
      user_email: "mytest7@email.com"
    }

    CalibrationService.start_link(
      user_email: precheck_2_session.user_email,
      session: precheck_2_session
    )

    assert {:error, "Already finished precheck 2"} =
             ElixirInterviewStarter.start_precheck_2(precheck_2_session.user_email)
  end

  test "get_current_session/1 returns the provided user's ongoing calibration session" do
    assert {:ok, _session} = ElixirInterviewStarter.start("mytest8@email.com")

    assert {:ok, %CalibrationSession{session_state: :active, user_email: "mytest8@email.com"}} =
             ElixirInterviewStarter.get_current_session("mytest8@email.com")
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibration session" do
    assert {:ok, nil} = ElixirInterviewStarter.get_current_session("mytest9@email.com")
  end
end
