# scripts/user_cli.exs
alias Exolyte.UserDB

case System.argv() do
  ["put", id, name, pw] ->
    UserDB.put_user(id, name, pw)
    IO.puts("User #{id} added.")

  ["get", id] ->
    case UserDB.get_user(id) do
      nil -> IO.puts("User not found.")
      user -> IO.inspect(user)
    end

  ["delete", id] ->
    UserDB.delete_user(id)
    IO.puts("User #{id} deleted.")

  ["list"] ->
    UserDB.list_users()
    |> Enum.each(fn {{:user, id}, data} ->
      IO.puts("#{id}: #{inspect(data)}")
    end)

  ["reset", id] ->
    link = UserDB.create_reset_link(id)
    IO.puts(link)

  _ ->
    IO.puts("Usage: mix run scripts/user_cli.exs [put|get|delete|list] ...")
end
