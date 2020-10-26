defmodule Example do
  use Goose, scope: "/api/v1"

  @route path: "multiply", opts: [:body]
  def multiply(num1, num2), do: double(num1 * num2)

  @route path: "wrong"
  defp double(num), do: num * 2

  def interpolate(arg), do: "The cat sat on the #{arg}"

  @route path: "hello", method: :get
  def hello(), do: :word

  defmacro upcase(string) do
    quote do
      String.upcase(unquote(string))
    end
  end
end
