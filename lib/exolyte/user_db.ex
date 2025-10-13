defmodule Exolyte.UserDB do
  @name_colors [
    "#e91f60",
    "#de3cb5",
    "#b270dd",
    "#7956c6",
    "#4d4acf",
    "#4a8bcf",
    "#4acfcf",
    "#32d25f",
    "#87c744",
    "#efd939",
    "#e7823c"
  ]

  @reset_db "priv/user_reset"

  def put_user(id, name, plain_pw) do
    db = Exolyte.DB.get_db()
    normalized_id = String.downcase(id)
    hashed_pw = Bcrypt.hash_pwd_salt(plain_pw)
    user_color = Enum.random(@name_colors)

    CubDB.put(db, {:user, normalized_id}, %{
      id: normalized_id,
      display_name: name,
      password_hash: hashed_pw,
      user_color: user_color
    })
  end

  def get_user(id) do
    db = Exolyte.DB.get_db()
    normalized_id = String.downcase(id)
    CubDB.get(db, {:user, normalized_id})
  end

  def update_user(id, merging) do
    db = Exolyte.DB.get_db()
    normalized_id = String.downcase(id)
    user = CubDB.get(db, {:user, normalized_id})

    CubDB.put(db, {:user, normalized_id}, Map.merge(user, merging))
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

  def create_reset_link(user) do
    link_uuid = UUID.uuid4()
    path = Path.join([@reset_db, "#{link_uuid}.json"])
    expire = System.os_time(:second) + 60 * 60 * 24

    data = %{
      user: user,
      expire_at: expire
    }

    File.write!(path, Jason.encode!(data))

    link_uuid
  end

  def get_reset_link(link_uuid) do
    path = Path.join([@reset_db, "#{link_uuid}.json"])

    if File.exists?(path) do
      {:ok, raw} = File.read(path)
      data = Jason.decode!(raw)

      if data["expire_at"] < System.os_time(:second) do
        {:error, :expired}
      else
        {:ok, data["user"]}
      end
    else
      {:error, :not_found}
    end
  end

  def password_reset(id, plain_pw) do
    hashed_pw = Bcrypt.hash_pwd_salt(plain_pw)
    update_user(id, %{password_hash: hashed_pw})
  end
end
