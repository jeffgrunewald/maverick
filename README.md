<img alt="Maverick" height="250px" src="assets/maverick.png?raw=true">

<!-- MDOC !-->

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

### Example

With Maverick added to your application's dependencies, create a module that implements the
`use Maverick.Api` macro and pass it, at a minimum, the name of your application:

```elixir
  defmodule CoolApp.Api do
    use Maverick.Api, otp_app: :cool_app
  end
```

Then, in your application supervision tree, add your Maverick Api to the list of children:

```elixir
  children =
    [
      maybe_a_database,
      other_cool_stuff,
      {CoolApp.Api, name: :cool_app_web, port: 443},
      anything_else
    ]
```

Now it's time to annotate the functions you want served over HTTP. These can be anywhere within
your project structure that make sense to you, Maverick will compile them all into your callback
handler. While it's considered best practice to structure your code to separate domain concerns
and maintain good abstractions, in practice this organization has no effect on what functions are
available to be routed to by Maverick. Add the `use Maverick` macro to a module that will be
serving functions and then any public function with the annotation will do (no macros):

```elixir
  defmodule CoolApp.BusinessLogics do
    use Maverick, scope: "api/v1"

    @route path: "do/stuff" do
    def do_stuff(%{"stuff" => what_needs_doing}) do
      what_needs_doing |> transform_process_etc
    end
  end
```

Once the app is started, you can reach your function at the path, method, etc. configured on
the route annotation, such as: `curl -XPOST -d '{\"stuff\":\"transform-me!\"}' "http://host:port/api/v1/do/stuff"`

See the docs for more options to configure your route functions such as the path, HTTP method,
the form arguments should be received as, response codes, and return value formats.

## To Do
- [X] Make it work
- [ ] Telemetry integration via Elli handler's `handle_event/3` callback
- [ ] Implement basic auth middleware hooks in the API module
- [ ] Absinthe/GraphQL integration
- [ ] Profit?

## Installation

The package can be installed by adding `maverick` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:maverick, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/maverick](https://hexdocs.pm/maverick).
