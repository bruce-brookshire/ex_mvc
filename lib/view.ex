defmodule ExMvc.View do
  defmacro __using__(model: model) do
    namespace = Application.get_env(:ex_mvc, :web_namespace)

    disallowed_fields =
      Application.get_env(:ex_mvc, :disallowed_fields) || ~w[__meta__ password password_hash]a

    quote do
      use unquote(namespace), :view

      alias unquote(model), as: Model
      alias Ecto.Association.NotLoaded

      @disallowed_fields unquote(disallowed_fields)

      def render("show.json", %{model: model}) do
        fields =
          Model.__schema__(:fields)
          |> Enum.filter(&(&1 not in unquote(disallowed_fields)))
          |> Enum.map(&{&1, Map.get(model, &1)})

        associations =
          Model.__schema__(:associations)
          |> Enum.map(&{&1, Map.get(model, &1) |> render_association()})

        (fields ++ associations)
        |> Map.new()
      end

      def render("index.json", %{models: models}) do
        render_many(models, __MODULE__, "show.json", as: :model)
      end

      defp render_association(%{__struct__: struct} = model) do
        struct.__schema__(:fields)
        |> Enum.filter(&(&1 not in unquote(disallowed_fields)))
        |> Enum.map(&{&1, Map.get(model, &1)})
        |> Map.new()
      end

      defp render_association(%{} = model) do
        Map.to_list(model)
        |> Enum.filter(&render_association/1)
        |> Map.new()
      end

      defp render_association({_name, %NotLoaded{}}), do: false
      defp render_association({field, _}) when field in @disallowed_fields, do: false
      defp render_association(_), do: true

      defoverridable render: 2
    end
  end
end
