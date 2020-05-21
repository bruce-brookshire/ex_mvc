# ExMvc
#### Making bootstrapping a RESTful Elixir API easier than ever

While Phoenix provides many CLI tools to expedite the writing of boilerplate code, I felt like there was a need to use metaprogramming to greatly simplify creating model, view, controller, and service layer modules. ExMvc is easy to implement, and flexible. You can override a single function and even use plugs for your controllers!

Please open an issue if you find any bugs or have any ideas to make this package better/more relevant!

# Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_mvc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_mvc, "~> 0.1.1"}
  ]
end
```

# Configuration
In your config.exs, configure ExMvc as below. Optional configuration can be done for the fields disallowed in a JSON render. See [View](#view) for default disallowed fields.

```elixir
config :ex_mvc, 
  repo: MyApp.Repo, 
  web_namespace: MyAppWeb,
  disallowed_fields: [:__meta__, :password, :another_private_field] # <-- Optional
```

# Implementation

### ModelChangeset
The model changeset module provides standard insert changeset and changesets for use by an adapter (or the service layer)

e.g:
```elixir
defmodule TestApp.User do
  use Ecto.Schema

  schema "table" do
    ...
  end

  use ExMvc.ModelChangeset, req_fields: [:username, :phone], opt_fields: [:avatar_url]
end
```

### Adapter
The adapter is an element of the service layer to help define basic fetch/update/create functionality for a model that uses ModelChangeset.

Associations are preloaded one level deep. 

e.g:
```elixir
defmodule TestApp.Users do
  use ExMvc.Adapter, model: TestApp.User
end
```

### View
The view renders a model in JSON. Any association is rendered with its fields in the object. 

By default, View behaves such that it redacts the following fields (called disallowed fields):
- `__meta__`
- `password`
- `password_hash`

Disallowed fields can be set on configuration, using the config: `disallowed_fields: [:__meta__, :password, :another_private_field]`

e.g:
```elixir
defmodule TestAppWeb.UserView do
  use ExMvc.View, model: TestApp.User
end
```

### Controller
Controllers generate GET, PUT, POST and DELETE functions for each model, using functionality provided in the adapter and view to functionally return content. Controllers also support plugs for security, and can be configured as shown below.

e.g:
```elixir
defmodule TestAppWeb.UserController do
  use ExMvc.Controller, 
    adapter: TestApp.User, 
    view: TestAppWeb.UserView, 
    plugs: (
      plug :verify_owner, :user
    )
end
```

By default, controllers will create the following functions: show/2, index/2, update/2, create/2, delete/2
This can be controlled using the :only (only create the routes specified) or :except (create all default routes except the following) options.

e.g:
```elixir
use ExMvc.Controller,
  ...,
  # Either
  only: [:show, :index, :update] # Generates: show/2, index/2, and update/2
  # Or
  except: [:create, :update] # Generates: show/2, index/2, delete/2
```
