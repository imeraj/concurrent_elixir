defmodule Sender do
  @moduledoc false

  def send_email("konnichiwa@world.com" = email),
    do: raise("Oops, couldn't send email to #{email}")

  def send_email(email) do
    Process.sleep(3000)
    IO.puts("Email to #{email} sent")
    {:ok, "email sent"}
  end

  def notify_all(emails) when is_list(emails) and emails != [] do
    Sender.EmailTaskSupervisor
    |> Task.Supervisor.async_stream_nolink(emails, &send_email/1,
      max_concurrency: 2,
      ordered: false,
      on_timeout: :kill_task
    )
    |> Enum.to_list()
  end
end
