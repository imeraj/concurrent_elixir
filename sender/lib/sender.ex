defmodule Sender do
  @moduledoc false

  def send_email(email) do
    Process.sleep(3000)
    IO.puts("Email to #{email} sent")
    {:ok, "email sent"}
  end

  def notify_all(emails) when is_list(emails) and emails != [] do
    Enum.each(emails, &send_email/1)
  end
end
