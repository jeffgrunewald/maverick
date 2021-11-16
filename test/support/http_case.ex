defmodule Maverick.HttpCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Maverick.Test.HttpHelpers
    end
  end
end

defmodule Maverick.Test.HttpHelpers do
  defmacro start_api(api) do
    quote do
      setup do
        start_supervised!({Plug.Cowboy, scheme: :http, plug: unquote(api), options: [port: 4000]})

        [host: "http://localhost:4000"]
      end
    end
  end

  defmacro finch_client do
    quote do
      setup do
        name = self() |> inspect() |> String.to_atom()

        opts = [
          name: name,
          pools: %{
            default: [
              size: 50,
              count: 1,
              protocol: :http1
            ]
          }
        ]

        start_supervised!({Finch, opts})
        [finch_client: name]
      end
    end
  end

  def response(%Finch.Response{status: status, body: body}, given) do
    given = Plug.Conn.Status.code(given)

    if given == status do
      body
    else
      raise "expected response with status #{given}, got: #{status}, with body:\n#{inspect(body)}"
    end
  end

  def json_response({:ok, response}, status), do: json_response(response, status)

  def json_response(response, status) do
    body = response(response, status)
    _ = response_content_type(response, :json)

    Jason.decode!(body)
  end

  def response_content_type(response, format) when is_atom(format) do
    case get_response_header(response, "content-type") do
      [] ->
        raise "no content-type was set, expected a #{format} response"

      [h] ->
        if response_content_type?(h, format) do
          h
        else
          raise "expected content-type for #{format}, got: #{inspect(h)}"
        end

      [_ | _] ->
        raise "more than one content-type was set, expected a #{format} response"
    end
  end

  def response_content_type?(header, format) do
    case parse_content_type(header) do
      {part, subpart} ->
        format = Atom.to_string(format)

        format in MIME.extensions(part <> "/" <> subpart) or
          format == subpart or String.ends_with?(subpart, "+" <> format)

      _ ->
        false
    end
  end

  defp parse_content_type(header) do
    case Plug.Conn.Utils.content_type(header) do
      {:ok, part, subpart, _params} ->
        {part, subpart}

      _ ->
        false
    end
  end

  defp get_response_header(response, header) do
    Enum.filter(response.headers, fn {name, _} -> name == header end)
    |> Enum.map(fn {_, v} -> v end)
  end
end
