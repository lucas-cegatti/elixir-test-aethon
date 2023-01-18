defmodule ElixirInterviewStarter do
  @moduledoc """
  See `README.md` for instructions on how to approach this technical challenge.
  """

  alias ElixirInterviewStarter.CalibrationService
  alias ElixirInterviewStarter.CalibrationSession

  @spec start(user_email :: String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Creates a new `CalibrationSession` for the provided user, starts a `GenServer` process
  for the session, and starts precheck 1.

  If the user already has an ongoing `CalibrationSession`, returns an error.
  """
  def start(user_email) do
    unless has_session_process?(user_email),
      do: CalibrationService.start_link(user_email: user_email)

    session = get_or_create_session(user_email)

    case validate_state_for(:start, session) do
      :ok ->
        GenServer.cast(String.to_atom(user_email), {:start, session})
        {:ok, session}

      {:error, _reason} = error ->
        error
    end
  end

  @spec start_precheck_2(user_email :: String.t()) ::
          {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Starts the precheck 2 step of the ongoing `CalibrationSession` for the provided user.

  If the user has no ongoing `CalibrationSession`, their `CalibrationSession` is not done
  with precheck 1, or their calibration session has already completed precheck 2, returns
  an error.
  """
  def start_precheck_2(user_email) do
    with {:ok, session} when not is_nil(session) <- get_current_session(user_email),
         :ok <- validate_state_for(:precheck_2, session) do
      GenServer.cast(String.to_atom(user_email), :start_precheck_2)

      {:ok, session}
    else
      {:ok, nil} -> {:error, "No ongoing session"}
      {:error, _reason} = error -> error
    end
  end

  @spec get_current_session(user_email :: String.t()) :: {:ok, CalibrationSession.t() | nil}
  @doc """
  Retrieves the ongoing `CalibrationSession` for the provided user, if they have one
  """
  def get_current_session(user_email) do
    case has_session_process?(user_email) do
      true -> GenServer.call(String.to_atom(user_email), :get_current_session)
      false -> {:ok, nil}
    end
  end

  defp get_or_create_session(user_email) do
    case get_current_session(user_email) do
      {:ok, nil} -> %CalibrationSession{user_email: user_email}
      {:ok, session} -> session
    end
  end

  defp has_session_process?(user_email) do
    GenServer.whereis(String.to_atom(user_email)) != nil
  end

  defp validate_state_for(:start, %CalibrationSession{session_state: :precheck_1}),
    do: {:error, "Already started precheck 1"}

  defp validate_state_for(:start, %CalibrationSession{
         session_state: :active,
         precheck_1: false
       }),
       do: :ok

  defp validate_state_for(:start, %CalibrationSession{
         session_state: :finished,
         precheck_1: true
       }),
       do: :ok

  defp validate_state_for(:precheck_2, %CalibrationSession{
         session_state: :active,
         precheck_1: true,
         precheck_2: false
       }),
       do: :ok

  defp validate_state_for(:precheck_2, %CalibrationSession{
         session_state: :precheck_1,
         precheck_1: false
       }),
       do: {:error, "Not done with precheck 1"}

  defp validate_state_for(:precheck_2, %CalibrationSession{
         session_state: :finished,
         precheck_2: true
       }),
       do: {:error, "Already finished precheck 2"}

  defp validate_state_for(_step, _session), do: {:error, "Invalid session state"}
end
