defmodule ExMvc.Adapter do
  # :local_dependency, path: "path/to/local_dependency"

  # web_namespace
  # repo
  # disallowed_fields
  defmacro __using__(model: model) do
    repo = Application.get_env(:ex_mvc, :repo)
    quote do
      alias unquote(repo)
      alias unquote(model), as: Model

      import Ecto.Query

      def get_by_id(id), do: Repo.get(Model, id) |> preload()

      def index(query_params) when is_list(query_params),
        do:
          from(m in Model, where: ^query_params)
          |> Repo.all()
          |> Enum.map(&preload/1)

      def exists?(query_params) when is_list(query_params),
        do:
          from(m in Model, where: ^query_params)
          |> Repo.exists?()

      def update(id, %{} = params) when is_integer(id),
        do: get_by_id(id) |> __MODULE__.update(params)

      def update(%Model{} = object, %{} = params),
        do: object |> Model.changeset(params) |> Repo.update() |> preload()

      def create(%{} = params),
        do: params |> Model.insert_changeset() |> Repo.insert() |> preload()

      defp preload({:ok, %{} = model}), do: {:ok, preload(model)}

      defp preload(%{} = model) do
        fields = Model.__schema__(:associations)

        Repo.preload(model, fields)
      end

      defp preload(error), do: error

      defoverridable create: 1, update: 2, index: 1, get_by_id: 1
    end
  end
end
