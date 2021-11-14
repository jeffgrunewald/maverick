defmodule Maverick.ResponseTest do
  use Maverick.ConnCase, async: true
  use Plug.Test

  setup do
    route = %Maverick.Route{success_code: 200, error_code: 403}

    [
      route: route,
      conn: conn(:get, "/") |> Plug.Conn.put_private(:maverick_route, route)
    ]
  end

  test "a raw map is json encoded with success response", ctx do
    response =
      Maverick.Response.handle(%{one: 1}, ctx.conn)
      |> json_response(200)

    assert %{"one" => 1} == response
  end

  test "a raw string is json encoded with success response", ctx do
    response =
      Maverick.Response.handle("hello world", ctx.conn)
      |> json_response(200)

    assert "hello world" == response
  end

  test "an ok tuple with json encode the term with success response", ctx do
    response =
      Maverick.Response.handle({:ok, %{one: 1}}, ctx.conn)
      |> json_response(200)

    assert %{"one" => 1} == response
  end

  test "a 3 element tuple controle status, headers and response explicitly", ctx do
    conn = Maverick.Response.handle({202, [{"key", "value"}], %{one: 1}}, ctx.conn)
    response = json_response(conn, 202)

    assert %{"one" => 1} == response
    assert ["value"] = Plug.Conn.get_resp_header(conn, "key")
  end

  test "a error tuple json encodes reason with error response", ctx do
    response =
      Maverick.Response.handle({:error, "bad stuff"}, ctx.conn)
      |> json_response(403)

    assert %{"error_code" => 403, "error_message" => "bad stuff"} == response
  end

  test "an error exception tuple triggers Maverick.Exception protocol", ctx do
    exception = ArgumentError.exception(message: "argument is bad")

    response =
      Maverick.Response.handle({:error, exception}, ctx.conn)
      |> json_response(500)

    assert %{"error_code" => 500, "error_message" => "argument is bad"} == response
  end
end
