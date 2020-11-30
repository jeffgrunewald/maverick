defmodule Maverick.ExceptionTest do
  use ExUnit.Case

  @host "http://localhost:4000"

  setup_all do
    start_supervised({Maverick.TestApi, []})

    :ok
  end

  describe "handles exceptions" do
    test "default fallback impl for unexpected exceptions" do
      bad_body = %{num1: 2, num2: "three"} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/multiply", [], bad_body)

      assert 500 == resp_code(resp)

      assert %{
               "error_code" => 500,
               "error_message" => "bad argument in arithmetic expression"
             } == resp_body(resp)
    end

    test "known exception type in request handling" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/fly/me/to/the",
          [{"Content-Type", "application/x-www-form-urlencoded"}],
          "field1=value1&field2=value2"
        )

      assert 400 == resp_code(resp)
      assert resp_content_type(resp)

      assert %{
               "error_code" => 400,
               "error_message" =>
                 "Invalid request body : unexpected byte at position 0: 0x66 ('f')"
             } == resp_body(resp)
    end
  end

  defp resp_code({:ok, status_code, _headers, _ref}), do: status_code

  defp resp_headers({:ok, _status_code, headers, _ref}), do: headers

  defp resp_body({:ok, _status_code, _headers, ref}) do
    {:ok, body} = :hackney.body(ref)
    Jason.decode!(body)
  end

  defp resp_content_type(resp) do
    {"Content-Type", "application/json"} in resp_headers(resp)
  end
end
