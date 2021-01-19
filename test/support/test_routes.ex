defmodule Maverick.TestRoute1 do
  use Maverick, scope: "/route1"

  @route path: "multiply", args: {:required_params, [:num1, :num2]}, error: 403
  def multiply(%{"num1" => num1, "num2" => num2}) do
    case num1 * num2 do
      50 -> {:error, "illegal operation"}
      prod -> %{product: prod}
    end
  end

  @route path: "wrong"
  defp double(%{"num" => num}), do: num * 2

  def interpolate(arg) do
    double(%{"num" => 2})

    "The cat sat on the #{arg}"
  end

  @route path: "hello/:name", method: :get
  def hello(%{"name" => name}), do: "Hi there " <> name

  @route path: "color_match"
  def color_match(%{"color" => "red"}) do
    raise NoRedError
  end

  def color_match(%{"color" => color}) do
    color_matches = %{
      "green" => "light_blue",
      "yellow" => "dark_blue",
      "brown" => "indigo",
      "orange" => "purple",
      "blue" => "light_green",
      "red" => "something"
    }

    match =
      case Map.get(color_matches, color) do
        nil -> "black"
        match -> match
      end

    %{"match" => match}
  end
end

defmodule Maverick.TestRoute2 do
  use Maverick, scope: "/route2"

  @route path: "fly/me/to/the", args: :conn
  def come_fly_with_me(conn) do
    destination = Enum.random(["moon", "mars", "stars"])

    response_header =
      conn.req_headers
      |> Map.new()
      |> Map.update("Space-Rocket", "BLASTOFF", fn val -> String.upcase(val) end)
      |> Map.drop(["Content-Length"])

    {:ok, response_header, %{"destination" => destination}}
  end

  @route path: "clock/now", method: :put
  def current_time(%{"timezone" => timezone}) do
    {:ok, time} = DateTime.now(timezone)
    time
  end

  defmacro upcase(string) do
    quote do
      String.upcase(unquote(string))
    end
  end
end
