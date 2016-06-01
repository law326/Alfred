defmodule Alfred.Bots.TFL do
  use Slack

  @behaviour Alfred.Bot

  require Logger

  def parse_message(_resp, message, slack) do
    api_get
    |> format_response
    |> send_message(message.channel, slack)
  end

  def format_response(response) do
    response
    |> Enum.map(fn(res) -> "#{res.tube} - *#{res.status}*" end)
    |> Enum.join("\n")
  end

  @moduledoc """
  Provides general request making and handling functionality (for internal use).
  """
  alias Alfred.Config

  # https://api.tfl.gov.uk/Line/Mode/tube/Status

  @doc """
  General HTTP `POST` request function. Takes a url part,
  and optionally a token, data Map and list of params.
  """
  def api_get do
    build_url
    |> HTTPoison.get!(%{})
    |> handle_response
  end

  defp handle_response(%HTTPoison.Response{body: body, status_code: status_code}) do
    response = Poison.decode!(body, keys: :atoms)
    case status_code do
      200 ->
        parse_response(response)
      _ -> IO.inspect response
    end
  end

  def parse_response(list) do
    parse_response(list, [])
  end
  def parse_response([], acc), do: acc
  def parse_response([h | t], acc) do
    tube = Map.get(h, :name)
    status = Map.get(h, :lineStatuses) |> List.first |> Map.get(:statusSeverityDescription)
    parse_response(t, [%{tube: tube, status: status} | acc])
  end


  defp build_url do
   "#{url}/Line/Mode/tube/Status?app_id=#{app_id}&app_key=#{app_key}"
  end

  defp url do
    Application.get_env(:alfred, :tfl)
    |> Dict.get(:base_url)
  end

  defp app_key do
    Application.get_env(:alfred, :tfl)
    |> Dict.get(:app_key)
  end

  defp app_id do
    Application.get_env(:alfred, :tfl)
    |> Dict.get(:app_id)
  end
end
