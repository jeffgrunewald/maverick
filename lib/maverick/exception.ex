defprotocol Maverick.Exception do
  @moduledoc false

  @fallback_to_any true

  def error_code(exception)

  def fallback(exception)
end

defimpl Maverick.Exception, for: Any do
  def error_code(%{error_code: code}) when is_integer(code), do: code
  def error_code(_exception), do: 500

  def fallback(exception),
    do: %{tag: "default fallback", handler: {Maverick.Exception.Default, :response, [exception]}}
end

defmodule Maverick.Exception.Default do
  def response(%{message: message, error_code: code}) when is_integer(code) do
    Jason.encode!(%{error_code: code, error_message: message})
  end

  def response(%{message: message} = exception) do
    Jason.encode!(%{error_code: Maverick.Exception.error_code(exception), error_message: message})
  end

  def response(exception) do
    Jason.encode!(%{
      error_code: Maverick.Exception.error_code(exception),
      error_message: "unknown"
    })
  end
end

defmodule Maverick.BadRequestError do
  defexception message: "could not process the request due to client error", error_code: 400
end
