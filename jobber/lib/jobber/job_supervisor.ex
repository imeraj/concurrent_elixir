defmodule Jobber.JobSupervisor do
  @moduledoc false

  use Supervisor, restart: :temporary

  # API
  def start_link(args), do: Supervisor.start_link(__MODULE__, args)

  # Callbacks
  @impl Supervisor
  def init(args) do
    children = [
      {
        Jobber.Job,
        args
      }
    ]

    options = [
      strategy: :one_for_one,
      max_seconds: 30
    ]

    Supervisor.init(children, options)
  end
end
