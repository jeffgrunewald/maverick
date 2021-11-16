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

  @doc """
  Takes an OTP app name and a root scope and returns a
  list of all routes the app defines as %__MODULE__ structs.
  """
  @spec list_routes(Maverick.api(), Maverick.root_scope()) :: [t()]
  def list_routes(api, root_scope) do
    api.list_modules()
    |> filter_router_modules()
    |> collect_route_info()
    |> prepend_root_scope(root_scope)
  end

  defp filter_router_modules({:ok, modules}) do
    Enum.filter(modules, fn module ->
      module
      |> to_string()
      |> String.ends_with?(".Maverick.Router")
    end)
  end

  defp collect_route_info(modules) do
    Enum.reduce(modules, [], fn module, acc ->
      acc ++ apply(module, :routes, [])
    end)
  end

  defp prepend_root_scope(routes, root_scope) do
    root_path = Maverick.Path.parse(root_scope)

    root_raw_path =
      case root_scope do
        "/" -> ""
        _ -> Maverick.Path.validate(root_scope)
      end

    Enum.map(routes, fn %Maverick.Route{path: path, raw_path: raw_path} = route ->
      %Maverick.Route{
        route
        | path: root_path ++ path,
          raw_path: root_raw_path <> raw_path
      }
    end)
  end
end
