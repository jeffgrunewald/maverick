defmodule Maverick.TestRoute1 do
  use Maverick, scope: "/api/v1"

  @route path: "multiply", args: {:required_params, [:num1, :num2]}, error: 403
  def multiply(%{"num1" => num1, "num2" => num2}), do: %{product: num1 * num2}

  @route path: "wrong"
  defp double(%{"num" => num}), do: num * 2

  def interpolate(arg) do
    double(%{"num" => 2})

    "The cat sat on the #{arg}"
  end

  @route path: "hello/:name", method: :get
  def hello(%{"name" => name}), do: "Hi there " <> name
end

defmodule Maverick.TestRoute2 do
  use Maverick, scope: "/api/v1"

  @route path: "fly/me/to/the", args: :request
  def come_fly_with_me(req) do
    destination = Enum.random(["moon", "mars", "stars"])

    response_header = Map.get(req.headers, "Customer-Name", "Anonymous")

    {:ok, response_header, %{"destination" => destination}}
  end

  @route path: "clock/:timezone", method: :put
  def current_time(%{"timezone" => timezone}) do
    DateTime.now(timezone)
  end

  defmacro upcase(string) do
    quote do
      String.upcase(unquote(string))
    end
  end
end
