defmodule BookingsPipeline do
  @moduledoc false

  use Broadway

  @producer BroadwayRabbitMQ.Producer

  @producer_config [
    queue: "bookings_queue",
    declare: [durable: true],
    on_failure: :reject_and_requeue
  ]

  def start_link(_args) do
    options = [
      name: BookingsPipeline,
      producer: [module: {@producer, @producer_config}, concurrency: 1],
      processors: [
        default: [concurrency: System.schedulers_online() * 2]
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end
end
