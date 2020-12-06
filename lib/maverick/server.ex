defmodule Maverick.Server do
  @callback child_spec(Maverick.api(), keyword()) :: Supervisor.child_spec()
  @callback router_contents(routes :: [map]) :: Macro.t()
end
