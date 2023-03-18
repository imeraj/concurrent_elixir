defmodule NotificationsPipeline do
  @moduledoc false

  use Broadway

  @producer BroadwayRabbitMQ.Producer

  @producer_config [
    queue: "notifications_queue",
    declare: [durable: true],
    on_failure: :reject_and_requeue,
    qos: [prefetch_count: 50]
  ]

  def start_link(_args) do
    options = [
      name: NotificationsPipeline,
      producer: [module: {@producer, @producer_config}],
      processors: [
        default: [concurrency: System.schedulers_online() * 2]
      ],
      batchers: [
        email: [concurrency: 5, batch_timeout: 1_000, batch_size: 50]
      ]
    ]

    Broadway.start_link(__MODULE__, options)
  end

  # callbacks
  @impl Broadway
  def handle_message(_processor, message, _context) do
    message
    |> Broadway.Message.put_batcher(:email)
    |> Broadway.Message.put_batch_key(message.data.recipient)
  end

  @impl Broadway
  def prepare_messages(messages, _context) do
    Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        [type, recipient] = String.split(data, ",")
        %{type: type, recipient: recipient}
      end)
    end)
  end

  @impl Broadway
  def handle_batch(_batcher, messages, batch_info, _context) do
    IO.puts(
      "#{inspect(self())} Batch #{batch_info.batcher} #{batch_info.batch_key} [size: #{batch_info.size}]"
    )

    # send email digest

    messages
  end
end
