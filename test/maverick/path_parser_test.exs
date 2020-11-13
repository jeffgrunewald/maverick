defmodule Maverick.PathParserTest do
  use ExUnit.Case

  test "parses static url" do
    {:ok, result, "", %{}, _, _} = Maverick.PathParser.parse("/api/users")

    assert ["api", "users"] == result
  end

  test "parses url with variables" do
    {:ok, result, "", %{}, _, _} =
      Maverick.PathParser.parse("/api/users/:id/comments/:comment_id")

    assert ["api", "users", {:variable, "id"}, "comments", {:variable, "comment_id"}] ==
             result
  end

  test "parses the web root to an empty list" do
    {:ok, result, "", %{}, _, _} = Maverick.PathParser.parse("/")

    assert [] == result
  end

  test "parses all allowed static path characters" do
    {:ok, result, "", %{}, _, _} = Maverick.PathParser.parse("/ApI/v1/2bar/Hello-World_7/-baz_")

    assert ["ApI", "v1", "2bar", "Hello-World_7", "-baz_"] == result
  end

  test "parses all allowed variable characters" do
    {:ok, result, "", %{}, _, _} = Maverick.PathParser.parse("/users/:id1/stuff/:first_Name")

    assert ["users", {:variable, "id1"}, "stuff", {:variable, "first_Name"}] == result
  end

  test "errors on invalid characters" do
    assert {:error, "expected only legal characters", _, %{}, _, _} =
             Maverick.PathParser.parse("/api/v?/foo")

    assert {:error, "expected only legal characters", _, %{}, _, _} =
             Maverick.PathParser.parse("/users/:user-id")
  end
end
