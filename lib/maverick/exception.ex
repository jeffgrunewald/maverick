defprotocol Maverick.Exception do
  @moduledoc """
  A protocol that allows associating http status codes with
  specific exceptions and providing a fallback operation in the
  form of an {module, function, arguments} tuple to attempt recovery.

  By default, the protocol looks for an implementation on the given
  exception, then checkds for the `:error_code` field, or else returns
  500 and falls back to returning a JSON-encoded map with the error code
  and a descriptive error message.
  """

  @fallback_to_any true

  @type fallback :: %{tag: String.t(), handler: {module(), atom(), list()}}

  @doc """
  Receives an exception and returns an HTTP status code.
  """
  @spec error_code(t) :: 100..999
  def error_code(exception)

  @doc """
  Receives an exception and returns the fallback operation, represented by
  a map with an identifying `tag` (primarily for debugging and logging) and
  a 3-tuple with the module, function, and arguments to execute to attempt
  recovery.
  """
  @spec fallback(t) :: fallback()
  def fallback(exception)
end

defimpl Maverick.Exception, for: Any do
  def error_code(%{error_code: code}) when is_integer(code), do: code
  def error_code(_exception), do: 500

  def fallback(exception),
    do: %{
      tag: "default fallback",
      handler: {Maverick.Exception.DefaultFallback, :response, [exception]}
    }
end

defmodule Maverick.Exception.DefaultFallback do
  @moduledoc """
  The default fallback operation for the `Maverick.Exception` protocol. Returns
  a JSON-encoded map providing descriptive code and message outlining the problem
  encountered.
  """

  @doc """
  Receives an exception and parses it for a `:message` and `:error_code` field,
  returning a JSON-encoded map detailing the code and message.
  """
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
  @moduledoc """
  The request failed to process due to client error.
  """

  defexception message: "could not process the request due to client error", error_code: 400
end

defimpl Maverick.Exception, for: Plug.Parsers.UnsupportedMediaTypeError do
  def error_code(_), do: 400

  def fallback(exception) do
    %{
      tag: :unsupported_media_type,
      handler: {__MODULE__, :handler, [exception]}
    }
  end

  def handler(exception) do
    Jason.encode!(%{
      error_code: 400,
      error_message: "Unsupported media type: #{exception.media_type}"
    })
  end
end
