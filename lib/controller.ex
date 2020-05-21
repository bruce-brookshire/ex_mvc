defmodule ExMvc.Controller do
  defmacro __using__(params) do
    %{adapter: adapter, view: view} = mapped_params = Map.new(params)

    if Map.has_key?(mapped_params, :only) and Map.has_key?(mapped_params, :except),
      do: raise("Cannot use both :only and :except, please use just one.")

    all_routes = ~w[show index update create delete]a

    except_routes = Map.get(mapped_params, :except) || []

    routes =
      (Map.get(mapped_params, :only) || all_routes)
      |> Enum.filter(fn route ->
        if route not in all_routes,
          do:
            raise("#{route} is not a supported route. The following are supported: #{all_routes}")

        true
      end)
      |> Enum.filter(&(&1 not in except_routes))

    show =
      quote do
        def show(conn, %{"id" => id}) do
          case Adapter.get_by_id(id) do
            %{} = model ->
              conn
              |> put_view(View)
              |> render("show.json", model: model)

            error ->
              IO.inspect(error)
              send_resp(conn, 422, "Unprocessable Entity")
          end
        end
      end

    index =
      quote do
        def index(conn, params) do
          case Adapter.get_by_params(params) do
            models when is_list(models) ->
              conn
              |> put_view(View)
              |> render("index.json", models: models)

            _ ->
              send_resp(conn, 404, "Params not found")
          end
        end
      end

    update =
      quote do
        def update(conn, %{"id" => id} = params) do
          case Adapter.update(id, params) do
            {:ok, %{} = model} ->
              conn
              |> put_view(View)
              |> render("show.json", model: model)

            {:error, %{errors: errors}} ->
              send_resp(conn, 422, stringify_changeset_errors(errors))

            error ->
              IO.inspect(error)
              send_resp(conn, 422, "Unprocessable Entity")
          end
        end
      end

    create =
      quote do
        def create(conn, params) do
          case Adapter.create(params) do
            {:ok, %{} = model} ->
              conn
              |> put_view(View)
              |> render("show.json", model: model)

            {:error, %{errors: errors}} ->
              send_resp(conn, 422, stringify_changeset_errors(errors))

            error ->
              IO.inspect(error)
              send_resp(conn, 422, "Unprocessable Entity")
          end
        end
      end

    delete =
      quote do
        def delete(conn, %{"id" => id}) do
          case Adapter.delete(id) do
            {:ok, _model} -> send_resp(conn, 204, "")
            {:error, _changeset} -> send_resp(conn, 404, "Not found")
          end
        end
      end

    route_functions =
      %{
        create: create,
        update: update,
        index: index,
        show: show,
        delete: delete
      }
      |> Map.take(routes)
      |> Enum.map(&elem(&1, 1))

    quote do
      use Phoenix.Controller, namespace: unquote(Application.get_env(:ex_mvc, :web_namespace))

      import Plug.Conn
      import ExMvc.Controller

      alias AppWeb.Router.Helpers, as: Routes
      alias unquote(adapter), as: Adapter
      alias unquote(view), as: View

      unquote(route_functions)

      defoverridable show: 2, update: 2, create: 2, index: 2, delete: 2
    end
  end

  def stringify_changeset_errors(errors) do
    content =
      errors
      |> Enum.map(fn {field, {message, _details}} ->
        "\"#{field}: #{message}\""
      end)
      |> Enum.join(", ")

    "{\"Errors\": [" <> content <> "]}"
  end
end
