File.mkdir_p!("priv/auth_session")
File.mkdir_p!("priv/cubdb")
File.mkdir_p!("priv/user_create")
File.mkdir_p!("priv/user_reset")

# prod.secret.exs
File.write!("config/prod.secret.exs", ~S"""
import Config

config :exolyte, :admin,
  token: "PUT_YOUR_SECRET_HERE"
""")