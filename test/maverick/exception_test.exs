defmodule Maverick.ExceptionTest do
  use ExUnit.Case
  use Maverick.ApiCase

  @headers [{"content-type", "application/json"}]

  setup_all :http_server

  describe "handles exceptions" do
    setup :http1_client

    test "default fallback impl for unexpected exceptions", ctx do
      bad_body = %{num1: 2, num2: "three"} |> Jason.encode!()

      {:ok, resp} =
        req(ctx.client, :post, "#{ctx.host}/api/v1/route1/multiply", @headers, bad_body)

      assert 500 == resp_code(resp)

      assert %{
               "error_code" => 500,
               "error_message" => "bad argument in arithmetic expression"
             } == resp_body(resp)
    end

    test "known exception type in request handling", ctx do
      {:ok, resp} =
        req(
          ctx.client,
          :post,
          "#{ctx.host}/api/v1/route2/fly/me/to/the",
          [{"Content-Type", "application/x-www-form-urlencoded"}],
          "field1=value1&field2=value2"
        )

      assert 400 == resp_code(resp)
      assert resp_content_type(resp)

      assert %{
               "error_code" => 400,
               "error_message" => "Unsupported media type: application/x-www-form-urlencoded"
             } == resp_body(resp)
    end

    test "custom exception handling", ctx do
      illegal_body = %{"color" => "red"} |> Jason.encode!()

      {:ok, resp} =
        req(ctx.client, :post, "#{ctx.host}/api/v1/route1/color_match", @headers, illegal_body)

      assert 406 = resp_code(resp)

      assert %{"error_code" => 406, "error_message" => "no red!"} == resp_body(resp)
    end
  end
end
