# ExMvc
#### Making bootstrapping a RESTful Elixir API easier than ever


# Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_mvc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_mvc, "~> 0.1.0"}
  ]
end
```

# Getting started

### ModelChangeset
The model changeset module provides standard insert changeset and changesets for use by an adapter (or the service layer)

e.g:
```elixir
defmodule TestApp.User do
  use Ecto.Schema

  schema "table" do
    ...
  end

  use ExMvc.ModelChangeset, req_fields: ~w[org_group_id user_id]a
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

Disallowed fields can be set on configuration, using disallowed_fields: `[:__meta__, :password, :another_private_field]`

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
  use ExMvc.Adapter, 
    adapter: TestApp.User, 
    view: TestAppWeb.UserView, 
    plugs: (
      plug :verify_owner, :user
    )
end
```
