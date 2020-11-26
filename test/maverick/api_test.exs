defmodule Maverick.ApiTest do
  use ExUnit.Case

  @host "http://localhost:4000"

  setup_all do
    start_supervised({Maverick.TestApi, []})

    :ok
  end

  describe "serves the handled routes" do
    test "GET request with empty body" do
      resp = :hackney.get("#{@host}/api/v1/hello/steve")

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert "Hi there steve" == resp_body(resp)
    end

    test "POST request with custom error code" do
      body = %{num1: 2, num2: 3} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/multiply", [], body)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 6} == resp_body(resp)
    end

    test "POST request that handles the complete Request struct" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/fly/me/to/the",
          [{"Space-Rocket", "brrr"}],
          ""
        )

      %{"destination" => destination} = resp |> resp_body()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert {"Space-Rocket", "BRRR"} in resp_headers(resp)
      assert destination in ["moon", "mars", "stars"]
    end

    test "PUT requests with query params" do
      resp = :hackney.put("#{@host}/api/v1/clock/now?timezone=Etc/UTC")

      {:ok, %DateTime{} = time, _} = resp |> resp_body() |> DateTime.from_iso8601()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert :lt == DateTime.compare(time, DateTime.utc_now())
    end
  end

  describe "supplies error results" do
    test "returns errors from exceptions in internal function" do
      bad_body = %{num1: 2, num2: "three"} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/multiply", [], bad_body)

      assert 500 == resp_code(resp)

      assert %{
               "error_code" => 500,
               "error_message" => "bad argument in arithmetic expression"
             } == resp_body(resp)
    end

    test "handles unexpected routes" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/gimme/that/data",
          [],
          %{"magic_word" => "please"} |> Jason.encode!()
        )

      assert 404 == resp_code(resp)
      assert resp_content_type(resp)
      assert "Not Found" == resp_body(resp)
    end

    test "handles malformed requests" do
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
