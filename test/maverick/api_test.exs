defmodule Maverick.ApiTest do
  use ExUnit.Case, async: true
  use Maverick.ApiCase

  @headers [{"content-type", "application/json"}]

  describe "serves the handled routes" do
    setup :http1_client
    setup :http_server

    test "GET request with empty body", ctx do
      {:ok, resp} = req(ctx.client, :get, "#{ctx.host}/api/v1/route1/hello/steve")

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert "Hi there steve" == resp_body(resp)
    end

    test "POST request with custom error code", ctx do
      body = %{num1: 2, num2: 3} |> Jason.encode!()

      {:ok, resp} = req(ctx.client, :post, "#{ctx.host}/api/v1/route1/multiply", @headers, body)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 6} == resp_body(resp)
    end

    test "POST request that handles the complete Request struct", ctx do
      {:ok, resp} =
        req(
          ctx.client,
          :post,
          "#{ctx.host}/api/v1/route2/fly/me/to/the",
          @headers ++ [{"space-rocket", "brrr"}]
        )

      %{"destination" => destination} = resp |> resp_body()

      assert 200 == resp_code(resp)
      assert {"space-rocket", "BRRR"} in resp_headers(resp)
      assert destination in ["moon", "mars", "stars"]
    end

    test "PUT requests with query params", ctx do
      {:ok, resp} =
        req(ctx.client, :put, "#{ctx.host}/api/v1/route2/clock/now?timezone=Etc/UTC", @headers)

      {:ok, %DateTime{} = time, _} = resp |> resp_body() |> DateTime.from_iso8601()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert :lt == DateTime.compare(time, DateTime.utc_now())
    end
  end

  describe "supplies error results" do
    setup :http1_client
    setup :http_server

    test "handles unexpected routes", ctx do
      body = %{"magic_word" => "please"} |> Jason.encode!()

      {:ok, resp} =
        req(ctx.client, :post, "#{ctx.host}/api/v1/route1/gimme/that/data", @headers, body)

      assert 404 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 404, "error_message" => "Not Found"} == resp_body(resp)
    end

    test "handles error tuples from internal functions", ctx do
      body = %{num1: 25, num2: 2} |> Jason.encode!()

      {:ok, resp} = req(ctx.client, :post, "#{ctx.host}/api/v1/route1/multiply", @headers, body)

      assert 403 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 403, "error_message" => "illegal operation"} == resp_body(resp)
    end
  end

  describe "ssl" do
    setup :http1_client
    setup :https_server

    test "handles secured connections", ctx do
      body = %{num1: 4, num2: 4} |> Jason.encode!()

      {:ok, resp} = req(ctx.client, :post, "#{ctx.host}/api/v1/route1/multiply", @headers, body)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 16} == resp_body(resp)
    end
  end
end
