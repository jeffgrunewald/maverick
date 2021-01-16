defmodule Maverick.ApiTest do
  use ExUnit.Case

  @host "http://localhost:4000"

  @headers [{"content-type", "application/json"}]

  describe "serves the handled routes" do
    setup do
      start_supervised!(
        {Plug.Cowboy, scheme: :http, plug: Maverick.TestApi, options: [port: 4000]}
      )

      :ok
    end

    test "GET request with empty body" do
      resp = :hackney.get("#{@host}/api/v1/route1/hello/steve")

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert "Hi there steve" == resp_body(resp)
    end

    test "POST request with custom error code" do
      body = %{num1: 2, num2: 3} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/route1/multiply", @headers, body)

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"product" => 6} == resp_body(resp)
    end

    test "POST request that handles the complete Request struct" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/route2/fly/me/to/the",
          @headers ++ [{"space-rocket", "brrr"}],
          ""
        )

      %{"destination" => destination} = resp |> resp_body()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert {"space-rocket", "brrr"} in resp_headers(resp)
      assert destination in ["moon", "mars", "stars"]
    end

    test "PUT requests with query params" do
      resp = :hackney.put("#{@host}/api/v1/route2/clock/now?timezone=Etc/UTC", @headers)

      {:ok, %DateTime{} = time, _} = resp |> resp_body() |> DateTime.from_iso8601()

      assert 200 == resp_code(resp)
      assert resp_content_type(resp)
      assert :lt == DateTime.compare(time, DateTime.utc_now())
    end
  end

  describe "supplies error results" do
    setup do
      start_supervised!(
        {Plug.Cowboy, scheme: :http, plug: Maverick.TestApi, options: [port: 4000]}
      )

      :ok
    end

    test "handles unexpected routes" do
      resp =
        :hackney.post(
          "#{@host}/api/v1/route1/gimme/that/data",
          @headers,
          %{"magic_word" => "please"} |> Jason.encode!()
        )

      assert 404 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 404, "error_message" => "Not Found"} == resp_body(resp)
    end

    test "handles error tuples from internal functions" do
      body = %{num1: 25, num2: 2} |> Jason.encode!()
      resp = :hackney.post("#{@host}/api/v1/route1/multiply", @headers, body)

      assert 403 == resp_code(resp)
      assert resp_content_type(resp)
      assert %{"error_code" => 403, "error_message" => "illegal operation"} == resp_body(resp)
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
