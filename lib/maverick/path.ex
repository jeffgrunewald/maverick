defmodule Maverick.Path do
  @moduledoc """
  Provides functionality for parsing paths to lists of path
  nodes, identifying path variables for pattern matching on
  incoming requests.
  """

  @type path_node :: String.t() | {:variable, String.t()}
  @type path :: [path_node]
  @type raw_path :: String.t()

  import NimbleParsec

  @doc """
  Parse a path string to a list of path nodes. A path node is either
  a `String.t()` or a tuple of `{:variable, String.t()}`. Nodes
  beginning with a colon character (":") will parse to a variable
  tuple. At runtime, variable tuples are used to construct the
  path params portion of a Maverick request.
  """
  @spec parse(String.t()) :: path()
  def parse(string) do
    case parse_path("/" <> string) do
      {:ok, result, _, _, _, _} ->
        result

      {:error, label, path, _, _, _} ->
        raise __MODULE__.ParseError, message: label, path: path
    end
  end

  @doc """
  Reads a path string and validates as a Maverick-compatible path,
  including any colon (":") characters signifying a path variable.
  Strips any extraneous forward slashes from the result.
  """
  @spec validate(String.t()) :: raw_path()
  def validate(string) do
    case parse_raw_path("/" <> string) do
      {:ok, [result], _, _, _, _} ->
        "/" <> result

      {:error, label, path, _, _, _} ->
        raise __MODULE__.ParseError, message: label, path: path
    end
  end

  url_file_safe_alphabet = [?A..?z, ?0..?9, ?-, ?_]

  root_slash = ignore(repeat(string("/"))) |> eos()

  separator = ignore(times(string("/"), min: 1))

  static = ascii_string(url_file_safe_alphabet, min: 1)

  variable =
    ignore(ascii_char([?:]))
    |> ascii_string(url_file_safe_alphabet -- [?-], min: 1)
    |> unwrap_and_tag(:variable)

  node =
    separator
    |> choice([
      variable,
      static
    ])

  path =
    choice([
      repeat(node) |> eos(),
      root_slash
    ])
    |> label("only legal characters")

  defparsecp(:parse_path, path)

  raw_node =
    separator
    |> ascii_string(url_file_safe_alphabet ++ [?:], min: 1)

  raw_path =
    choice([
      repeat(raw_node) |> eos(),
      root_slash
    ])
    |> reduce({Enum, :join, ["/"]})
    |> label("only legal characters")

  defparsecp(:parse_raw_path, raw_path)

  defmodule ParseError do
    @moduledoc """
    The path could not be parsed due to illegal character(s)
    """

    defexception message: "expected only legal characters", path: []
  end
end
