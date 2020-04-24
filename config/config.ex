import Config

config :ex_mvc, [disallowed_fields: ~w[__meta__ password password_hash]a]