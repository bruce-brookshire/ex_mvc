defmodule ExMvc.View do
  
  @disallowed_fields Application.get_env(:ex_mvc, :disallowed_fields) || ~w[__meta__ password password_hash]a

  alias Ecto.Association.NotLoaded

  defmacro __using__(model: model) do
    namespace = Application.get_env(:ex_mvc, :web_namespace)

    quote do
      use unquote(namespace), :view

      import ExMvc.View

      alias unquote(model), as: Model

      @disallowed_fields unquote(@disallowed_fields)

      def render("show.json", %{model: model}) do
        fields =
          Model.__schema__(:fields)
          |> Enum.filter(&(&1 not in @disallowed_fields))
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

      defoverridable render: 2
    end
  end

  def render_association(%NotLoaded{}), do: nil

  def render_association(%{__struct__: struct} = model) do
    struct.__schema__(:fields)
    |> Enum.filter(&(&1 not in @disallowed_fields))
    |> Enum.map(&{&1, Map.get(model, &1)})
    |> Map.new()
  end

  def render_association(%{} = model) do
    Map.to_list(model)
    |> Enum.filter(&render_association/1)
    |> Map.new()
  end

  def render_association(models) when is_list(models),
    do: Enum.map(models, &render_association/1)

  def render_association({_name, %NotLoaded{}}), do: false
  def render_association({field, _}) when field in @disallowed_fields, do: false
  def render_association(_), do: true
end
