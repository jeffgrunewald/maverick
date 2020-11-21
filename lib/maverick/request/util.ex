defmodule Maverick.Request.Util do
  @moduledoc false

  alias Maverick.Request

  @content_type {"Content-Type", "application/json"}

  def args(%Request{params: params}, {:required_params, required}) do
    Map.take(params, required)
  end

  def args(%Request{params: params}, :params), do: params
  def args(%Request{} = req, :request), do: req

  def content_type(), do: @content_type

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
