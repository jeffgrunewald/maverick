defprotocol Maverick.Response do
  @fallback_to_any true
  def handle(t, conn)
end

defimpl Maverick.Response, for: Any do
  def handle(term, %Plug.Conn{private: %{maverick_route: route}} = conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(route.success_code, Jason.encode!(term))
  end
end

defimpl Maverick.Response, for: Tuple do
  def handle({:ok, term}, conn) do
    Maverick.Response.handle(term, conn)
  end

  def handle({status, headers, term}, conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> add_headers(headers)
    |> Plug.Conn.resp(status, Jason.encode!(term))
  end

  def handle({:error, exception}, conn) when is_exception(exception) do
    Maverick.Exception.handle(exception, conn)
  end

  def handle({:error, error_message}, %Plug.Conn{private: %{maverick_route: route}} = conn) do
    response =
      %{error_code: route.error_code, error_message: error_message}
      |> Jason.encode!()

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(route.error_code, response)
  end

  defp add_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, conn ->
      Plug.Conn.put_resp_header(conn, key, value)
    end)
  end
end
