defmodule ExMVC.View do
  defmacro __using__(params) do
    %{
      single_atom: single_atom,
      plural_atom: plural_atom,
      model: model
    } = params |> Map.new()

    quote do
      use Application.get_env(:ex_mvc, :web_namespace), :view

      alias unquote(model), as: Model
      alias Ecto.Association.NotLoaded

      @disallowed_fields Application.get_env(:ex_mvc, :disallowed_fields)
                           

      def single_atom, do: unquote(single_atom)
      def plural_atom, do: unquote(plural_atom)

      def render("show.json", %{unquote(single_atom) => model}) do
        fields = Model.__schema__(:fields) |> Enum.map(&{&1, Map.get(model, &1)})

        associations =
          Model.__schema__(:associations)
          |> Enum.map(&{&1, render_association(Map.get(model, &1))})

        (fields ++ associations)
        |> Map.new()
      end

      def render("index.json", %{unquote(plural_atom) => models}) do
        render_many(models, __MODULE__, "show.json", as: single_atom())
      end

      defp render_association(%{} = model),
        do: model |> Map.to_list() |> Enum.filter(&render_association/1) |> Map.new()

      defp render_association({_name, %NotLoaded{}}), do: false
      defp render_association({field, _}) when field in @disallowed_fields, do: false
      defp render_association(_), do: true

      defoverridable render: 2
    end
  end
end
