defmodule Maverick.ApiTest do
  use ExUnit.Case, async: true
  use SetupFinch
  use SetupServer

  @headers [{"content-type", "application/json"}]

  describe "serves the handled routes" do
    setup :finch_http1_client
    setup :http_server

    test "GET request with empty body", ctx do
      {:ok, resp} =
        :get
        |> Finch.build("#{ctx.host}/api/v1/route1/hello/steve")
        |> Finch.request(ctx.finch_client)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert "Hi there steve" == resp_body(resp)
    end

    test "POST request with custom error code", ctx do
      body = %{num1: 2, num2: 3} |> Jason.encode!()

      {:ok, resp} =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, body)
        |> Finch.request(ctx.finch_client)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 6} == resp_body(resp)
    end

    test "POST request that handles the complete Request struct", ctx do
      {:ok, resp} =
        :post
        |> Finch.build(
          "#{ctx.host}/api/v1/route2/fly/me/to/the",
          @headers ++ [{"space-rocket", "brrr"}]
        )
        |> Finch.request(ctx.finch_client)

      %{"destination" => destination} = resp |> resp_body()

      assert 200 == resp_code(resp)
      assert {"space-rocket", "BRRR"} in resp_headers(resp)
      assert destination in ["moon", "mars", "stars"]
    end

    test "PUT requests with query params", ctx do
      {:ok, resp} =
        :put
        |> Finch.build("#{ctx.host}/api/v1/route2/clock/now?timezone=Etc/UTC", @headers)
        |> Finch.request(ctx.finch_client)

      {:ok, %DateTime{} = time, _} = resp |> resp_body() |> DateTime.from_iso8601()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert :lt == DateTime.compare(time, DateTime.utc_now())
    end
  end

  describe "supplies error results" do
    setup :finch_http1_client
    setup :http_server

    test "handles unexpected routes", ctx do
      body = %{"magic_word" => "please"} |> Jason.encode!()

      {:ok, resp} =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/gimme/that/data", @headers, body)
        |> Finch.request(ctx.finch_client)

      assert 404 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 404, "error_message" => "Not Found"} == resp_body(resp)
    end

    test "handles error tuples from internal functions", ctx do
      body = %{num1: 25, num2: 2} |> Jason.encode!()

      {:ok, resp} =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, body)
        |> Finch.request(ctx.finch_client)

      assert 403 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 403, "error_message" => "illegal operation"} == resp_body(resp)
    end
  end

  describe "ssl" do
    setup :finch_http1_client
    setup :https_server

    test "handles secured connections", ctx do
      body = %{num1: 4, num2: 4} |> Jason.encode!()

      {:ok, resp} =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, body)
        |> Finch.request(ctx.finch_client)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 16} == resp_body(resp)
    end
  end

  defp resp_code(%Finch.Response{status: status_code}), do: status_code

  defp resp_headers(%Finch.Response{headers: headers}), do: headers

  defp resp_body(%Finch.Response{body: body}), do: Jason.decode!(body)

  defp resp_content_type(resp) do
    {"content-type", "application/json; charset=utf-8"} in resp_headers(resp)
  end
end
