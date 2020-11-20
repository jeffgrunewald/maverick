defmodule Maverick.ApiTest do
  use ExUnit.Case

  test "api creates the handler module" do
    test_module = Maverick.TestApi.Handler

    assert [] == check_modules_available(test_module)

    start_supervised({Maverick.TestApi, []})

    assert [{test_module, true}] == check_modules_available(test_module)

    assert [handle: 2, handle: 3, handle_event: 3] == test_module.__info__(:functions)
  end

  test "serves the handled routes" do
    start_supervised({Maverick.TestApi, []})

    response =
      :hackney.get("http://localhost:4000/api/v1/hello/steve")
      |> IO.inspect(label: "HACKNEY RESP")
  end

  defp check_modules_available(check_module) do
    :code.all_available()
    |> Enum.filter(fn {mod, _, _} ->
      mod
      |> to_string()
      |> String.contains?(check_module |> to_string)
    end)
    |> Enum.map(fn {mod, _, loaded} ->
      mod =
        mod
        |> to_string()
        |> String.to_existing_atom()

      {mod, loaded}
    end)
  end
end
