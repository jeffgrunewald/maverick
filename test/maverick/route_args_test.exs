defmodule Maverick.RouteArgTest do
  use Maverick.HttpCase, async: false

  defmodule Routes do
    use Maverick

    @route method: :get, path: "/hello/:first/:last", args: ["first", "last"]
    def hello(first, last) do
      "Hello #{first} #{last}"
    end

    @route method: :get, path: "/hello2/:first/:last", args: [:params]
    def hello_with_map(%{"first" => first, "last" => last}) do
      hello(first, last)
    end

    @route method: :get, path: "/hello3/:first/:last", args: [:conn]
    def hello_with_conn(%Plug.Conn{params: %{"first" => first, "last" => last}}) do
      hello(first, last)
    end
  end

  defmodule TestApi do
    use Maverick.Api, otp_app: :maverick, modules: [Routes], root_scope: "/api"
  end

  finch_client()
  start_api(TestApi)

  test "getting entire conn", ctx do
    body =
      :get
      |> Finch.build("#{ctx.host}/api/hello3/Fred/Walker")
      |> Finch.request(ctx.finch_client)
      |> json_response(200)

    assert "Hello Fred Walker" == body
  end

  test "getting entire params map", ctx do
    body =
      :get
      |> Finch.build("#{ctx.host}/api/hello2/Fred/Walker")
      |> Finch.request(ctx.finch_client)
      |> json_response(200)

    assert "Hello Fred Walker" == body
  end

  test "test reading params from params", ctx do
    body =
      :get
      |> Finch.build("#{ctx.host}/api/hello/Joe/Walker")
      |> Finch.request(ctx.finch_client)
      |> json_response(200)

    assert "Hello Joe Walker" == body
  end
end
