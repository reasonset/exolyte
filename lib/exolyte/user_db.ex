defmodule Exolyte.UserDB do
  def put_user(id, name, plain_pw) do
    db = Exolyte.DB.get_db()
    normalized_id = String.downcase(id)
    hashed_pw = Bcrypt.hash_pwd_salt(plain_pw)
    CubDB.put(db, {:user, normalized_id}, %{display_name: name, password_hash: hashed_pw})
  end

  def get_user(id) do
    db = Exolyte.DB.get_db()
    normalized_id = String.downcase(id)
    CubDB.get(db, {:user, normalized_id})
  end

  def delete_user(id) do
    db = Exolyte.DB.get_db()
    CubDB.delete(db, {:user, id})
  end

  def list_users() do
    db = Exolyte.DB.get_db()
    CubDB.select(db, keys: :all)
    |> Enum.filter(fn
      {{:user, _id}, _value} -> true
      _ -> false
    end)
  end

  def authenticate(id, plain_pw) do
    case get_user(id) do
      %{password_hash: hash} ->
        if Bcrypt.verify_pass(plain_pw, hash), do: {:ok, id}, else: {:error, :unauthorized}

      _ ->
        {:error, :not_found}
    end
  end
end
