defmodule Maverick.Arguments do
  def validate(args) do
    args
  end

  def get(%Maverick.Route{} = route, %Plug.Conn{} = conn) do
    Enum.map(route.args, &arg(conn, &1))
  end

  defp arg(conn, :params), do: conn.params

  defp arg(conn, :conn), do: conn

  defp arg(conn, {parameter, :required}) do
    get_in(conn.params, List.wrap(parameter))
  end

  defp arg(conn, parameter) do
    get_in(conn.params, List.wrap(parameter))
  end
end
