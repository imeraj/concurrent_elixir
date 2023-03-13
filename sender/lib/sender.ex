defmodule Sender do
  @moduledoc false

  def send_email(email) do
    Process.sleep(3000)
    IO.puts("Email to #{email} sent")
    {:ok, "email sent"}
  end

  def notify_all(emails) when is_list(emails) and emails != [] do
    emails
    |> Enum.map(fn email ->
      Task.async(fn ->
        send_email(email)
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end
