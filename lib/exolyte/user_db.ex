defmodule Exolyte.UserDB do
  @db_path "priv/cubdb"

  def start_db do
    CubDB.start_link(data_dir: @db_path)
  end

  def put_user(db, id, name, plain_pw) do
    normalized_id = String.downcase(id)
    hashed_pw = Bcrypt.hash_pwd_salt(plain_pw)
    CubDB.put(db, {:user, normalized_id}, %{display_name: name, password_hash: hashed_pw})
  end

  def get_user(db, id) do
    normalized_id = String.downcase(id)
    CubDB.get(db, {:user, normalized_id})
  end

  def delete_user(db, id) do
    CubDB.delete(db, {:user, id})
  end

  def list_users(db) do
    CubDB.select(db, keys: :all)
    |> Enum.filter(fn {{:user, _id}, _value} -> true; _ -> false end)
  end

  def authenticate(db, id, plain_pw) do
    case get_user(db, id) do
      %{password_hash: hash} ->
        if Bcrypt.verify_pass(plain_pw, hash), do: {:ok, id}, else: {:error, :unauthorized}

      _ ->
        {:error, :not_found}
    end
  end
end
