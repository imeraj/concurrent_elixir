defmodule SendServer do
  @moduledoc false

  use GenServer

  # API

  # callbacks
  @impl GenServer
  def init(args) do
    IO.puts("Received arguments: #{inspect(args)}")
    max_retries = Keyword.get(args, :max_retries, 5)
    state = %{emails: [], max_retries: max_retries}

    # retry
    Process.send_after(self(), :retry, 5000)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:send, email}, state) do
    status =
      case Sender.send_email(email) do
        {:ok, "email sent"} -> "sent"
        :error -> "failed"
      end

    emails = [%{email: email, status: status, retries: 0}] ++ state.emails

    Process.send_after(self(), :retry, 5000)
    {:noreply, %{state | emails: emails}}
  end

  @impl GenServer
  def handle_info(:retry, state) do
    {failed, done} =
      Enum.split_with(state.emails, fn item ->
        item.status == "failed" and item.retries < state.max_retries
      end)

    retried =
      Enum.map(failed, fn item ->
        IO.inspect("Retrying #{inspect(item)}")

        new_status =
          case Sender.send_email(item.email) do
            {:ok, "email sent"} -> "sent"
            :error -> "failed"
          end

        %{email: item.email, status: new_status, retries: item.retries + 1}
      end)

    new_state = %{state | emails: retried ++ done}

    {failed, _done} =
      Enum.split_with(state.emails, fn item ->
        item.status == "failed" and item.retries < state.max_retries
      end)

    if failed != [] do
      Process.send_after(self(), :retry, 5000)
    end

    # update state
    {:noreply, new_state}
  end

  # internal functions
end
