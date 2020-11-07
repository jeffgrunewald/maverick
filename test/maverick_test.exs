defmodule MaverickTest do
  use ExUnit.Case

  defmodule Example do
    use Maverick, scope: "/api/v1"

    @route path: "multiply", args: :required_params, error: 403
    def multiply(num1, num2), do: double(num1 * num2)

    @route path: "wrong"
    defp double(num), do: num * 2

    def interpolate(arg), do: "The cat sat on the #{arg}"

    @route path: "hello/:name", method: :get
    def hello(name), do: name

    defmacro upcase(string) do
      quote do
        String.upcase(unquote(string))
      end
    end
  end

  test "creates getters for annotated public functions" do
    assert %{
             module: MaverickTest.Example,
             function: :multiply,
             arity: 2,
             method: "POST",
             path: ["api", "v1", "multiply"],
             args: :required_params,
             error_code: 403,
             success_code: 200
           } in Example.Maverick.Router.routes()

    assert %{
             module: MaverickTest.Example,
             function: :hello,
             arity: 1,
             method: "GET",
             path: ["api", "v1", "hello", {:variable, "name"}],
             args: :params,
             error_code: 404,
             success_code: 200
           } in Example.Maverick.Router.routes()
  end

  test "ignores invalid or unannotated functions" do
    route_functions = Example.Maverick.Router.routes()

    refute function_member(route_functions, :double)
    refute function_member(route_functions, :interpolate)
    refute function_member(route_functions, :upcase)
  end

  defp function_member(routes, function) do
    Enum.any?(routes, fn %{function: func} -> func == function end)
  end
end
