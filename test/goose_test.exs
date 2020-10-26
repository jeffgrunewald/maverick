defmodule GooseTest do
  use ExUnit.Case

  defmodule Example do
    use Goose, scope: "/api/v1"

    @route path: "multiply", opts: [:body]
    def multiply(num1, num2), do: double(num1 * num2)

    @route path: "wrong"
    defp double(num), do: num * 2

    def interpolate(arg), do: "The cat sat on the #{arg}"

    @route path: "hello", method: :get
    def hello(), do: :world

    defmacro upcase(string) do
      quote do
        String.upcase(unquote(string))
      end
    end
  end

  test "creates getters for annotated public functions" do
    assert Example.Goose.Routes.multiply() == %{
      module: GooseTest.Example,
      function: :multiply,
      argc: 2,
      argv: ["num1", "num2"],
      method: "POST",
      path: ["api", "v1", "multiply"],
      opts: [:body]
    }

    assert Example.Goose.Routes.hello() == %{
      module: GooseTest.Example,
      function: :hello,
      argc: 0,
      argv: [],
      method: "GET",
      path: ["api", "v1", "hello"],
      opts: []
    }
  end

  test "ignores invalid or unannotated functions" do
    route_functions = Example.Goose.Routes.__info__(:functions)

    assert Enum.member?(route_functions, {:hello, 0})
    assert Enum.member?(route_functions, {:multiply, 0})

    refute Enum.member?(route_functions, {:double, 0})
    refute Enum.member?(route_functions, {:interpolate, 0})
    refute Enum.member?(route_functions, {:upcase, 0})
  end
end
