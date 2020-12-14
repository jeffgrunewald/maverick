defmodule Maverick.PathTest do
  use ExUnit.Case

  describe "parse" do
    test "parses static url" do
      assert ["api", "users"] == Maverick.Path.parse("/api/users")
    end

    test "parses url with variables" do
      assert ["api", "users", {:variable, "id"}, "comments", {:variable, "comment_id"}] ==
               Maverick.Path.parse("/api/users/:id/comments/:comment_id")
    end

    test "parses the web root to an empty list" do
      assert [] == Maverick.Path.parse("/")
    end

    test "parses all allowed static path characters" do
      assert ["ApI", "v1", "2bar", "Hello-World_7", "-baz_"] ==
               Maverick.Path.parse("/ApI/v1/2bar/Hello-World_7/-baz_")
    end

    test "parses all allowed variable characters" do
      assert ["users", {:variable, "id1"}, "stuff", {:variable, "first_Name"}] ==
               Maverick.Path.parse("/users/:id1/stuff/:first_Name")
    end
  end

  describe "validate" do
    test "validates a static path" do
      assert "/api/v1/users/list" == Maverick.Path.validate("/api/v1/users/list")
    end

    test "validates a path with variables" do
      assert "/api/v1/users/:user_id/comments" ==
               Maverick.Path.validate("/api/v1/users/:user_id/comments")
    end

    test "strips extra forward slashes" do
      assert "/api/v1/users/list" == Maverick.Path.validate("api/v1////users//list")
    end
  end

  describe "invalid paths" do
    test "errors on invalid characters" do
      assert_raise Maverick.Path.ParseError, "expected only legal characters", fn ->
        Maverick.Path.parse("/api/v?/foo")
      end

      assert_raise Maverick.Path.ParseError, "expected only legal characters", fn ->
        Maverick.Path.parse("/users/:user-id")
      end
    end
  end
end
