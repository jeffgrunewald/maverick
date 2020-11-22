# Maverick

Web API framework with a need for speed

## But Why?

A full web framework with support for live content updates and server-side rendering
is great, but sometimes you just want a way to handle JSON-based service requests over
HTTP without all the bells and whistles.

Maverick aims to fill the niche between a full Phoenix Framework just for providing a
web-based API and hand-rolling a Plug API while backing your service with the super-performant
Elli webserver.

## Use

Maverick builds the webserver handler by reading annotations on functions you want to
expose as part of your API. To publish a function, add `use Maverick` to your module and
the `@route` attribute to the relevant functions. Pass a keyword list of options to the
route attribute including the `:path` and you're off to the races.

Once you add the `Maverick.Api` to your application supervision tree and start the app,
Maverick compiles your routes into an Elli handler module and sends incoming requests
to your functions, taking care to wrap the return values accordingly.

## To Do
- [X] Make it work
- [ ] Telemetry integration via Elli handler's `handle_event/3` callback
- [ ] Implement basic auth middleware hooks in the API module
- [ ] Absinthe/GraphQL integration
- [ ] Profit?

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `maverick` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:maverick, "~> 0.1.0"}
  ]
end
```

Once published, the docs can be found at [https://hexdocs.pm/maverick](https://hexdocs.pm/maverick).
