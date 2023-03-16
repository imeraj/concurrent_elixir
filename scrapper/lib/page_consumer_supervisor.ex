defmodule PageConsumerSupervisor do
  @moduledoc false

  use ConsumerSupervisor
  require Logger

  # API
  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  # Callbacks
  @impl ConsumerSupervisor
  def init(:ok) do
    Logger.info("PageConsumerSupervisor init")

    children = [
      %{
        id: PageConsumer,
        start: {PageConsumer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [
        {PageProducer, max_demand: System.schedulers_online() * 2}
      ]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
