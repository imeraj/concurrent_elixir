defmodule Airports do
  @moduledoc false

  alias NimbleCSV.RFC4180, as: CSV

  defp airports_csv, do: Application.app_dir(:airports, "/priv/airports.csv")

  def open_airports do
    airports_csv()
    |> File.read!()
    |> CSV.parse_string()
    |> Enum.map(fn row ->
      %{
        id: Enum.at(row, 0),
        type: Enum.at(row, 2),
        name: Enum.at(row, 3),
        country: Enum.at(row, 8)
      }
    end)
    |> Enum.reject(&(&1.type == "closed"))
  end
end
