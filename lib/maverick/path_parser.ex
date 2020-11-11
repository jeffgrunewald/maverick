defmodule Maverick.PathParser do
  @moduledoc false

  import NimbleParsec

  url_file_safe_alphabet = [?A..?z, ?0..?9, ?-, ?_]

  static = ascii_string(url_file_safe_alphabet, min: 1)

  variable =
    ignore(ascii_char([?:]))
    |> ascii_string(url_file_safe_alphabet -- [?-], min: 1)
    |> unwrap_and_tag(:variable)

  element =
    ignore(string("/"))
    |> choice([
      variable,
      static
    ])

  path =
    choice([
      repeat(element) |> eos(),
      ignore(string("/")) |> eos()
    ])
    |> label("only legal characters")

  defparsec(:parse, path)
end
