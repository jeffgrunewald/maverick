defmodule Maverick.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Maverick.Conn.Helpers
    end
  end
end

defmodule Maverick.Conn.Helpers do
  require ExUnit.Assertions

  def response(%Plug.Conn{status: status, resp_body: body}, given) do
    given = Plug.Conn.Status.code(given)

    if given == status do
      body
    else
      raise "expected response with status #{given}, got: #{status}, with body:\n#{inspect(body)}"
    end
  end

  def json_response(conn, status) do
    body = response(conn, status)
    _ = response_content_type(conn, :json)

    Jason.decode!(body)
  end

  def response_content_type(conn, format) when is_atom(format) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
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
end
