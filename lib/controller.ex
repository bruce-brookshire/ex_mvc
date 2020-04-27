defmodule ExMvc.Controller do
  defmacro __using__(params) do
    %{adapter: adapter, view: view} = mapped_params = Map.new(params)
    plug_block = Map.get(mapped_params, :plugs)

    quote do
      use Phoenix.Controller, namespace: unquote(Application.get_env(:ex_mvc, :web_namespace))
      import Plug.Conn
      alias AppWeb.Router.Helpers, as: Routes

      alias unquote(adapter), as: Adapter
      alias unquote(view), as: View

      unquote(plug_block)

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

      def update(conn, %{"id" => id} = params) do
        case Adapter.update(id, params) do
          {:ok, %{} = model} ->
            conn
            |> put_view(View)
            |> render("show.json", model: model)

          error ->
            IO.inspect(error)
            send_resp(conn, 422, "Unprocessable Entity")
        end
      end

      def create(conn, params) do
        case Adapter.create(params) do
          {:ok, %{} = model} ->
            conn
            |> put_view(View)
            |> render("show.json", model: model)

          error ->
            IO.inspect(error)
            send_resp(conn, 422, "Unprocessable Entity")
        end
      end

      defoverridable show: 2, update: 2, create: 2, index: 2
    end
  end
end
