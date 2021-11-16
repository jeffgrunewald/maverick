defmodule Maverick.ExceptionTest do
  use Maverick.HttpCase

  @headers [{"content-type", "application/json"}]

  finch_client()
  start_api(Maverick.TestApi)

  describe "handles exceptions" do
    test "default fallback impl for unexpected exceptions", ctx do
      bad_body = %{num1: 2, num2: "three"} |> Jason.encode!()

      body =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/multiply", @headers, bad_body)
        |> Finch.request(ctx.finch_client)
        |> json_response(500)

      assert %{
               "error_code" => 500,
               "error_message" => "bad argument in arithmetic expression"
             } == body
    end

    test "known exception type in request handling", ctx do
      body =
        :post
        |> Finch.build(
          "#{ctx.host}/api/v1/route2/fly/me/to/the",
          [{"Content-Type", "application/x-www-form-urlencoded"}],
          "field1=value1&field2=value2"
        )
        |> Finch.request(ctx.finch_client)
        |> json_response(400)

      assert %{
               "error_code" => 400,
               "error_message" => "Unsupported media type: application/x-www-form-urlencoded"
             } == body
    end

    test "custom exception handling", ctx do
      illegal_body = %{"color" => "red"} |> Jason.encode!()

      body =
        :post
        |> Finch.build("#{ctx.host}/api/v1/route1/color_match", @headers, illegal_body)
        |> Finch.request(ctx.finch_client)
        |> json_response(406)

      assert %{"error_code" => 406, "error_message" => "no red!"} == body
    end
  end
end
