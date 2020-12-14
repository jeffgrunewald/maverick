defmodule Mix.Tasks.Mvk.Routes do
  @moduledoc """
  Prints all routes for the default or a given Maverick Api

    #> mix mvk.routes
    #> mix mvk.routes MyApp.Alternative.Api

  The default router is drawn from the root name of the application
  (the `:app` key in your Mixfile) converted to Elixir "Module-case"
  and concatenated with `.Api` similar to the Ecto Repo convention
  of `MyApp.Repo` being used to name the module implementing `Ecto.Repo`.
  """

  use Mix.Task

  @doc false
  @impl true
  def run(args, app_base \\ app_base()) do
    Mix.Task.run("compile", args)

    api =
      case OptionParser.parse(args, switches: []) do
        {_, [passed_api], _} ->
          Module.concat([passed_api])

        {_, [], _} ->
          app_base
          |> to_string()
          |> Macro.camelize()
          |> Module.concat("Api")
      end

    :application.ensure_started(app_base)

    routes = api.list_routes() |> stringify_routes()

    :application.stop(app_base)

    column_widths = column_widths(routes)

    routes
    |> Enum.map_join("", &format_route(&1, column_widths))
    |> fn print_routes -> "\n" <> print_routes end.()
    |> Mix.shell().info()
  end

  defp app_base() do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
  end

  defp stringify_routes(routes) do
    Enum.map(routes, fn route ->
      %Maverick.Route{function: func, method: method, module: mod, args: args, raw_path: path} =
        route

      %{
        function: inspect(func),
        method: method,
        module: inspect(mod),
        args: inspect(args),
        path: path
      }
    end)
  end

  defp column_widths(routes) do
    Enum.reduce(routes, {0, 0, 0, 0}, fn route, acc ->
      %{function: func, method: method, module: mod, path: path} = route
      {method_len, path_len, mod_len, func_len} = acc

      {
        max(method_len, String.length(method)),
        max(path_len, String.length(path)),
        max(mod_len, String.length(mod)),
        max(func_len, String.length(func))
      }
    end)
  end

  defp format_route(route, column_widths) do
    %{args: args, function: func, method: method, module: mod, path: path} = route
    {method_len, path_len, mod_len, func_len} = column_widths

      String.pad_leading(method, method_len) <>
      "  " <>
      String.pad_trailing(path, path_len) <>
      "  " <>
      String.pad_trailing(mod, mod_len) <>
      "  " <>
      String.pad_trailing(func, func_len) <>
      "  " <>
      args <> "\n"
  end
end
