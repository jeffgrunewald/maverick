defmodule Maverick.Server do
  @callback child_spec(Maverick.api(), keyword()) :: Supervisor.child_spec()
end
