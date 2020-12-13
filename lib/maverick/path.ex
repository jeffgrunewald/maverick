defmodule Maverick.Path do
  @moduledoc """
  Provides functionality for parsing paths to lists of path
  nodes, identifying path variables for pattern matching on
  incoming requests.
  """

  import NimbleParsec

  @doc """
  Parse a path string to a list of path nodes. A path node is either
  a `String.t()` or a tuple of `{:variable, String.t()}`. Nodes
  beginning with a colon character (":") will parse to a variable
  tuple. At runtime, variable tuples are used to construct the
  path params portion of a Maverick request.
  """
  def parse(string) do
    case ("/" <> string) |> parse_path() do
      {:ok, result, _, _, _, _} ->
        result

      {:error, label, path, _, _, _} ->
        raise __MODULE__.ParseError, message: label, path: path
    end
  end

  url_file_safe_alphabet = [?A..?z, ?0..?9, ?-, ?_]

  static = ascii_string(url_file_safe_alphabet, min: 1)

  variable =
    ignore(ascii_char([?:]))
    |> ascii_string(url_file_safe_alphabet -- [?-], min: 1)
    |> unwrap_and_tag(:variable)

  element =
    ignore(times(string("/"), min: 1))
    |> choice([
      variable,
      static
    ])

  path =
    choice([
      repeat(element) |> eos(),
      ignore(repeat(string("/"))) |> eos()
    ])
    |> label("only legal characters")

  defparsecp(:parse_path, path)

  defmodule ParseError do
    @moduledoc """
    The path could not be parsed due to illegal character(s)
    """

    defexception message: "expected only legal characters", path: []
  end
end
