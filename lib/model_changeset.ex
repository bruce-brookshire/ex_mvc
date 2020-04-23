defmodule ExMVC.ModelChangeset do
  defmacro __using__(options) do
    option_map = Map.new(options)

    expand_or_return = fn
      value when is_list(value) -> value
      value -> Macro.expand(value, __CALLER__)
    end

    req_fields = (option_map[:req_fields] || []) |> expand_or_return.()
    opt_fields = (option_map[:opt_fields] || []) |> expand_or_return.()
    all_fields = req_fields ++ opt_fields

    quote do
      import Ecto.Changeset

      alias __MODULE__, as: Model

      defp req_fields, do: unquote(req_fields)
      defp all_fields, do: unquote(all_fields)

      def insert_changeset(params),
        do:
          Model.__struct__(%{})
          |> changeset(params)

      def changeset(%Model{} = changeset, params),
        do:
          changeset
          |> cast(params, all_fields())
          |> validate_required(all_fields())

      defoverridable insert_changeset: 1, changeset: 2
    end
  end
end
