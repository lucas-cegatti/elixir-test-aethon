defmodule ElixirInterviewStarter.CalibrationSession do
  @moduledoc """
  A struct representing an ongoing calibration session, used to identify who the session
  belongs to, what step the session is on, and any other information relevant to working
  with the session.
  """

  @type t() :: %__MODULE__{}

  defstruct precheck_1: false,
            precheck_2: false,
            session_state: :active,
            user_email: nil
end
