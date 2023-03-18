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
      ],
      batchers: [
        cinema: [],
        musical: [],
        default: []
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  # callbacks
  @impl Broadway
  def handle_message(_processor, message, _context) do
    %{data: %{event: event, user: _user}} = message

    if Tickets.tickets_available?(event) do
      case event do
        "cinema" ->
          Broadway.Message.put_batcher(message, :cinema)

        "musical" ->
          Broadway.Message.put_batcher(message, :musical)

        "failed" ->
          Broadway.Message.put_batcher(message, :failed)

        _ ->
          message
      end
    else
      Broadway.Message.failed(message, "bookings-closed")
    end
  end

  @impl Broadway
  def prepare_messages(messages, _context) do
    messages =
      Enum.map(messages, fn message ->
        Broadway.Message.update_data(message, fn data ->
          [event, user_id] = String.split(data, ",")
          %{event: event, user_id: user_id}
        end)
      end)

    users = Tickets.users_by_ids(Enum.map(messages, & &1.data.user_id))

    # put users in messages
    Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        user = Enum.find(users, &(data.user_id == &1.id))
        Map.put(data, :user, user)
      end)
    end)
  end

  @impl Broadway
  def handle_failed(messages, _context) do
    IO.inspect(messages, label: "Failed messages")

    Enum.map(messages, fn
      %{status: {:failed, "bookings-closed"}} = message ->
        Broadway.Message.configure_ack(message, on_failure: :reject)

      message ->
        message
    end)
  end

  @impl Broadway
  def handle_batch(_batcher, messages, batch_info, _context) do
    IO.puts(
      "#{inspect(self())} Batch #{batch_info.batcher} #{batch_info.batch_key} [size: #{batch_info.size}]"
    )

    messages
    |> Tickets.insert_all_tickets()
    |> Enum.each(fn message ->
      channel = message.metadata.amqp_channel
      payload = "email,#{message.data.user.email}"
      AMQP.Basic.publish(channel, "", "notifications_queue", payload)
    end)

    messages
  end
end
