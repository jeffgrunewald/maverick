defmodule Maverick.PathParser do
  @moduledoc false

  # A utility module for parsing the path element of a `@route`
  # function attribute, tagging any elements with a preceding
  # colon (":") as a variable that should be extracted by the
  # Handler module for binding incoming path params to variable.
  #
  # This module is not intended for direct consumption by an
  # application implementing Maverick.

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
