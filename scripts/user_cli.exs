# scripts/user_cli.exs
alias Exolyte.UserDB

{:ok, db} = UserDB.start_db()

case System.argv() do
  ["put", id, name, pw] ->
    UserDB.put_user(db, id, name, pw)
    IO.puts("User #{id} added.")

  ["get", id] ->
    case UserDB.get_user(db, id) do
      nil -> IO.puts("User not found.")
      user -> IO.inspect(user)
    end

  ["delete", id] ->
    UserDB.delete_user(db, id)
    IO.puts("User #{id} deleted.")

  ["list"] ->
    UserDB.list_users(db)
    |> Enum.each(fn {{:user, id}, data} ->
      IO.puts("#{id}: #{inspect(data)}")
    end)

  _ ->
    IO.puts("Usage: mix run scripts/user_cli.exs [put|get|delete|list] ...")
end
