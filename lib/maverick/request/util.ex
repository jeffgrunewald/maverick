defmodule Maverick.Request.Util do
  @moduledoc false

  # This module provides utility functions that are needed to handle
  # Maverick requests and responses but is not intended for direct
  # consumption by the application implementing Maverick.

  alias Maverick.Request

  @content_type {"Content-Type", "application/json"}

  @doc """
  Extract the specific argument type from the incoming `%Maverick.Request{}`
  that should be passed to an internal function from its `handle/3` routing
  function based on the expected type from the function's `@route` attributed

  ## Options

    * `:params` - the default value; the merged map of all params in the
      `%Maverick.Request{}` (path params, query params, and request body)
      will be passed.
    * `:required params` - a map consisting of the specific key/value pairs
      specified by the atom-keyed list in the `@route` attribute.
    * `:request` - the entire `%Maverick.Request{}` will be passed to the function.
  """
  def args(%Request{params: params}, {:required_params, required}) do
    Map.take(params, required)
  end

  def args(%Request{params: params}, :params), do: params
  def args(%Request{} = req, :request), do: req

  @doc """
  Convenience for setting the "Content-Type" header value to "application/json"
  """
  def content_type(), do: @content_type

  @doc """
  Converts the return value of an internal function to a 3-tuple suitable as a
  return value for the Elli `c:handle/2` consisting of the HTTP status response
  code, a list of headers, and a JSON-encoded response body.
  """
  def wrap_response({code, headers, response}, _, _) when is_integer(code) do
    {code, wrap_headers(headers), Jason.encode!(response)}
  end

  def wrap_response({:ok, headers, response}, success, _) do
    {success, wrap_headers(headers), Jason.encode!(response)}
  end

  def wrap_response({:ok, response}, success, _) do
    {success, [content_type()], Jason.encode!(response)}
  end

  def wrap_response({:error, response}, _, error) do
    {error, [content_type()], Jason.encode!(response)}
  end

  def wrap_response(response, success, _) do
    {success, [content_type()], Jason.encode!(response)}
  end

  defp wrap_headers(headers) do
    [
      content_type()
      | headers
        |> Map.drop(["Content-Type", "content-type"])
        |> Enum.into([])
    ]
  end
end
