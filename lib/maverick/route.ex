defmodule Maverick.Route do
  @moduledoc """
  A struct detailing a Maverick Route. The
  contents are determined at compile time
  by the annotations applied to routable functions.

  Maverick uses the routes to construct request
  handlers for each routable function at runtime.
  """

  @type args :: :params | :request | {:required_params, [atom()]}
  @type success_code :: non_neg_integer()
  @type error_code :: non_neg_integer()
  @type method :: binary()
  @type t :: %__MODULE__{
          args: args(),
          error_code: error_code(),
          function: atom(),
          method: method(),
          module: module(),
          path: Maverick.Path.path(),
          raw_path: Maverick.Path.raw_path(),
          success_code: success_code()
        }

  defstruct [
    :args,
    :error_code,
    :function,
    :method,
    :module,
    :path,
    :raw_path,
    :success_code
  ]
end
