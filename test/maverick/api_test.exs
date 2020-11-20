defmodule Maverick.ApiTest do
  use ExUnit.Case

  test "serves the handled routes" do
    start_supervised({Maverick.TestApi, []})

    {:ok, code, headers, ref} = :hackney.get("http://localhost:4000/api/v1/hello/steve")

    assert code == 200
    assert {"Content-Type", "application/json"} in headers
    assert {:ok, "Hi there steve"} == :hackney.body(ref)
  end
end
