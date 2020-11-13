defmodule Maverick.Test1 do
  use Maverick, scope: "/api/v1"

  @route path: "multiply", args: :required_params, error: 403
  def multiply(num1, num2), do: num1 * num2

  @route path: "hello/:name", method: :get
  def hello(name), do: name

  @route path: "fly/to/the/moon", args: :request
  def foobar(num1), do: num1 * 3

  @route path: "boobah/:id/clock", method: :put
  def barbaz(), do: :name
end
