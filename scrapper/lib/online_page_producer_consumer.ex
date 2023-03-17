defmodule OnlinePageProducerConsumer do
  @moduledoc false

  use GenStage
  require Logger

  # API
  def start_link(id) do
    initial_state = []
    GenStage.start_link(__MODULE__, initial_state, name: via(id))
  end

  # Callbacks
  @impl GenStage
  def init(initial_state) do
    Logger.info("OnlinePageProducerConsumer init")

    subscription = [
      {PageProducer, min_demand: 0, max_demand: 1}
    ]

    {:producer_consumer, initial_state, subscribe_to: subscription}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Logger.info("OnlinePageProducerConsumer received #{inspect(events)}")
    events = Enum.filter(events, &Scrapper.online?/1)
    {:noreply, events, state}
  end

  def via(id) do
    {:via, Registry, {ProducerConsumerRegistry, id}}
  end
end
