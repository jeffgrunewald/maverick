defmodule MaverickTest do
  use ExUnit.Case

  defmodule Example do
    use Maverick, scope: "/api/v1"

    @route path: "multiply", args: :required_params, error: 403
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
    assert Example.Maverick.Routes.multiply() == %{
             module: MaverickTest.Example,
             function: :multiply,
             arity: 2,
             method: "POST",
             path: ["api", "v1", "multiply"],
             args: :required_params,
             error_code: 403,
             success_code: 200
           }

    assert Example.Maverick.Routes.hello() == %{
             module: MaverickTest.Example,
             function: :hello,
             arity: 0,
             method: "GET",
             path: ["api", "v1", "hello"],
             args: :params,
             error_code: 404,
             success_code: 200
           }
  end

  test "ignores invalid or unannotated functions" do
    route_functions = Example.Maverick.Routes.__info__(:functions)

    assert Enum.member?(route_functions, {:hello, 0})
    assert Enum.member?(route_functions, {:multiply, 0})

    refute Enum.member?(route_functions, {:double, 0})
    refute Enum.member?(route_functions, {:interpolate, 0})
    refute Enum.member?(route_functions, {:upcase, 0})
  end
end
