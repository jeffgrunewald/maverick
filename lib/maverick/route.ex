defmodule Maverick.Route do
  defstruct [:module, :function, :args, :method, :path, :success_code, :error_code]
end
