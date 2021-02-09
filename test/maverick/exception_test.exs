defmodule Maverick.ExceptionTest do
  use ExUnit.Case

  @host "http://localhost:4000"
  @headers [{"content-type", "application/json"}]

  setup_all do
    start_supervised!({Plug.Cowboy, scheme: :http, plug: Maverick.TestApi, options: [port: 4000]})

    :ok
  end

  describe "handles exceptions" do
    test "default fallback impl for unexpected exceptions" do
      bad_body = %{num1: 2, num2: "three"} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/route1/multiply", @headers, bad_body)

      assert 500 == resp_code(resp)

      assert %{
               "error_code" => 500,
               "error_message" => "bad argument in arithmetic expression"
             } == resp_body(resp)
    end

    test "known exception type in request handling" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/route2/fly/me/to/the",
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

    test "custom exception handling" do
      illegal_body = %{"color" => "red"} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/route1/color_match", @headers, illegal_body)

      assert 406 = resp_code(resp)

      assert %{"error_code" => 406, "error_message" => "no red!"} == resp_body(resp)
    end
  end

  defp resp_code({:ok, status_code, _headers, _ref}), do: status_code

  defp resp_headers({:ok, _status_code, headers, _ref}), do: headers

  defp resp_body({:ok, _status_code, _headers, ref}) do
    {:ok, body} = :hackney.body(ref)
    Jason.decode!(body)
  end

  defp resp_content_type(resp) do
    {"content-type", "application/json"} in resp_headers(resp)
  end
end
