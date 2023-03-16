defmodule PageConsumer do
  @moduledoc false

  require Logger

  def start_link(event) do
    Logger.info("PageConsumer received #{event}")

    Task.start_link(fn ->
      Scrapper.work()
    end)
  end
end
