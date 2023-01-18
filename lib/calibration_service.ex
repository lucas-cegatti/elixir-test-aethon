defmodule ElixirInterviewStarter.CalibrationService do
  @moduledoc """
  GenServer to process messages from calibration sessions.
  """
  use GenServer

  alias ElixirInterviewStarter.DeviceMessages
  alias ElixirInterviewStarter.CalibrationSession

  @spec start_link(keyword()) :: {:ok, pid()} | {:error, any()}
  def start_link(opts) when is_list(opts) do
    user_email = Keyword.fetch!(opts, :user_email)
    session = Keyword.get(opts, :session, nil)

    GenServer.start_link(__MODULE__, %{session: session}, name: String.to_atom(user_email))
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Returns the current session.
  """
  def handle_call(:get_current_session, _from, %{session: session} = state) do
    {:reply, {:ok, session}, state}
  end

  @doc """
  Starts the calibration session with the new given session.
  """
  def handle_cast({:start, session}, state) do
    session = %CalibrationSession{session | session_state: :precheck_1}

    {:noreply, %{state | session: session}, {:continue, :start_precheck_1}}
  end

  def handle_cast(:start_precheck_2, %{session: session} = state) do
    task = Task.async(fn -> DeviceMessages.send(session.user_email, "start_precheck_2/1") end)

    state =
      case Task.await(task, 30_000) do
        :ok ->
          %{state | session: %{session | precheck_2: true, session_state: :finished}}

        {:error, :timeout} ->
          %{state | session: %{session | precheck_2: false, session_state: :failed}}
      end

    {:noreply, state}
  end

  @doc """
  Starts precheck 1 for the provided session.

  This function uses Task to monitor the timeout of the device and marks the states of
  the session depending on the result.
  """
  def handle_continue(:start_precheck_1, %{session: session} = state) do
    task =
      Task.async(fn ->
        DeviceMessages.send(session.user_email, "startPrecheck1")
      end)

    state =
      case Task.await(task, 30_000) do
        :ok ->
          %{state | session: %{session | precheck_1: true, session_state: :active}}

        %{"precheck1" => true} ->
          %{state | session: %{session | precheck_1: true}}

        %{"precheck1" => false} ->
          %{state | session: %{session | precheck_1: false, session_state: :failed}}

        {:error, :timeout} ->
          %{state | session: %{session | precheck_1: false, session_state: :failed}}
      end

    {:noreply, state}
  end
end
