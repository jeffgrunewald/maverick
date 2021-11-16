defmodule Maverick.ApiTest do
  use Maverick.HttpCase, async: false

  @headers [{"content-type", "application/json"}]

  finch_client()
  start_api(Maverick.TestApi)

  describe "serves the handled routes" do
    test "GET request with empty body", ctx do
      body =
        :get
        |> Finch.build("#{ctx.host}/api/v1/route1/hello/steve")
        |> Finch.request(ctx.finch_client)
        |> json_response(200)

      assert "Hi there steve" == body
    end

    test "POST request with custom error code", ctx do
      request_body = %{num1: 2, num2: 3} |> Jason.encode!()

      body =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, request_body)
        |> Finch.request(ctx.finch_client)
        |> json_response(200)

      assert %{"product" => 6} == body
    end

    test "POST request that handles the complete Request struct", ctx do
      {:ok, resp} =
        :post
        |> Finch.build(
          "#{ctx.host}/api/v1/route2/fly/me/to/the",
          @headers ++ [{"space-rocket", "brrr"}],
          ""
        )
        |> Finch.request(ctx.finch_client)

      %{"destination" => destination} = json_response(resp, 200)

      assert {"space-rocket", "brrr"} in resp.headers
      assert destination in ["moon", "mars", "stars"]
    end

    test "PUT requests with query params", ctx do
      {:ok, %DateTime{} = time, _} =
        :put
        |> Finch.build("#{ctx.host}/api/v1/route2/clock/now?timezone=Etc/UTC", @headers)
        |> Finch.request(ctx.finch_client)
        |> json_response(200)
        |> DateTime.from_iso8601()

      assert :lt == DateTime.compare(time, DateTime.utc_now())
    end
  end

  describe "supplies error results" do
    test "handles unexpected routes", ctx do
      body =
        :post
        |> Finch.build(
          "#{ctx.host}/api/v1/route1/gimme/that/data",
          @headers,
          %{"magic_word" => "please"} |> Jason.encode!()
        )
        |> Finch.request(ctx.finch_client)
        |> json_response(404)

      assert %{"error_code" => 404, "error_message" => "Not Found"} == body
    end

    test "handles error tuples from internal functions", ctx do
      request_body = %{num1: 25, num2: 2} |> Jason.encode!()

      body =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, request_body)
        |> Finch.request(ctx.finch_client)
        |> json_response(403)

      assert %{"error_code" => 403, "error_message" => "illegal operation"} == body
    end
  end
end
