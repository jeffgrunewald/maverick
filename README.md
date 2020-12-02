<img alt="Maverick" height="250px" src="assets/maverick.png?raw=true">

<!-- MDOC !-->

Web API framework with a need for speed

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
serving functions and then any public function (sorry, no macros) with the `@route` annotation will do:

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

### Route Options

The following options can configure functions annotated with the `@route` attribute:

  * `:path` - The path, as a string, at which the function should be accessible. Prefix
    elements of the path with a colon (":") if they should be treated as variables on requests,
    such as `api/customers/:customer_id` (required).

  * `:args` - The format of the argument that will be passed to the internal function, which can
    be one of `:params` (the default), `{:required_params: [atom()]}`, or `:request`. If the
    value is `params`, the argument passed to the function will be a string-keyed map merging the
    path parameters map, query parameters map, and the request body map. If the value is `{required_params, [atom()]}`,
    where the second element is a list of atoms representing keys that _must_ appear and have non-`nil` values in
    the request params map, this subset of key/value pairs will be sent as a string-keyed map. If the value is
    `:request` then the entire Maverick request struct will be sent. This is good for handling requests that need
    access to deeper elements of the HTTP request like the source IP, scheme, port, manipulating headers, etc.

  * `:method` - The HTTP method the function should respond to as an atom or a string. Defaults
    to `"POST"` (all methods are converted to uppercase strings so follow your personal tastes).

  * `:success_code` - In the event of success, the HTTP status code that will be returned (defaults
    to 200).

  * `:error_code` - In the event of an error (an explicit `{:error, term()}`), the HTTP status code
    that will be returned.

  * `:scope` - This special option is set at the module level (`use Maverick.Api, scope: "path/prefix"`),
    _not_ on the `@route` attribute, to set a shared prefix for all routes handled within the module.

### Return Values

Maverick aims to be simple to use, passing some form of map to your function (see `:args` in the above
"Route Options" section) and taking virtually any JSON-encodable term as a result to return to the client.

That said, the following are acceptable return values for your routed functions; use the simplest one
that meets your needs and it will be converted accordingly to allow the webserver to hand it back to the client:

  * `response()` - Any raw term will be assumed to be a successful request; must be encodable to JSON.

  * `{:ok, response()}` - An explicit success; the term must be encodable to JSON.

  * `{:error, response()}` - An explicit (non-exception) failure; the term must be encodable to JSON.

  * `{code(), headers(), response()}` - A 3-tuple with an explicit integer status code, map of response
    headers, and response body which, you guessed it, must be encodable to JSON.

In the absence of a full-detailed response return value, Maverick will apply the `:success_code` for
the status code of `{:ok, response()}` and implicitly successful `response()` results and the
`:error_code` for the status code of `{:error, response()}` results.

When response headers are returned, they are expected to be in the form of a map, as this is the format
in which the function will receive request headers. They will be converted to `[{String.t(), String.t()}]`
before handing back to the webserver to return to the client. If no response headers are returned, Maverick
will automatically add the `{"Content-Type", "application/json"}` header.

### Exceptions

In the event an exception is raised during handling of a request, the Handler functions will automatically
rescue and construct a response by calling functions from the the `Maverick.Exception` protocol on the exception. See the exception protocol module for implementing it for specific exceptions.

<!-- MDOC !-->

## But Why?

A full web framework with support for live content updates and server-side rendering
is great, but sometimes you just want a way to handle JSON-based service requests over
HTTP without all the bells and whistles.

Maverick aims to fill the niche between a full Phoenix Framework just for providing a
web-based API and hand-rolling a Plug API while backing your service with the super-performant
[Elli](https://github.com/elli-lib/elli) webserver.

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
