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

      def get_by_id(id) when is_binary(id), do: id |> String.to_integer() |> get_by_id()
      def get_by_id(id) when is_integer(id), do: Repo.get(Model, id) |> preload()

      def get_by_params(query_params) when is_map(query_params) do
        fields = Model.__schema__(:fields) |> Enum.map(&to_string/1)

        query_params
        |> Map.take(fields)
        |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
        |> get_by_params()
      end

      def get_by_params(query_params) when is_list(query_params) do
        from(m in Model, where: ^query_params)
        |> Repo.all()
        |> Enum.map(&preload/1)
      end

      def exists?(query_params) when is_list(query_params),
        do:
          from(m in Model, where: ^query_params)
          |> Repo.exists?()

      def update(id, %{} = params) when is_binary(id) or is_integer(id),
        do: get_by_id(id) |> __MODULE__.update(params)

      def update(%Model{} = object, %{} = params) do
        object
        |> Model.changeset(params)
        |> case do
          %{valid?: true} = changeset -> Repo.update(changeset) |> preload()
          error -> {:error, error |> IO.inspect}
        end
      end

      def create(%{} = params) do
        params
        |> Model.insert_changeset()
        |> case do
          %{valid?: true} = changeset -> Repo.insert(changeset) |> preload()
          error -> {:error, error |> IO.inspect}
        end
      end

      def delete(id) when is_binary(id), do: id |> String.to_integer() |> __MODULE__.delete()
      def delete(id) when is_integer(id), do: id |> get_by_id() |> Repo.delete()
      def delete(%Model{} = model), do: Repo.delete(model)

      defp preload({:ok, %{} = model}), do: {:ok, preload(model)}

      defp preload(%{} = model) do
        fields = Model.__schema__(:associations)

        Repo.preload(model, fields)
      end

      defp preload(error), do: error

      defoverridable create: 1, update: 2, get_by_params: 1, get_by_id: 1, exists?: 1
    end
  end
end
