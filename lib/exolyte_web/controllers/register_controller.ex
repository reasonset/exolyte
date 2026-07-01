defmodule ExolyteWeb.RegisterController do
  use ExolyteWeb, :controller

  plug :put_layout, html: {ExolyteWeb.Layouts, :root}

  def new(conn, %{"link_uuid" => link_uuid}) do
    case Exolyte.UserDB.get_user_link(link_uuid) do
      {:ok, ^link_uuid} ->
        render(conn, :new, link_uuid: link_uuid, error_message: nil)

      _ ->
        conn
        |> put_flash(:error, "Invalid or expired registration link.")
        |> redirect(to: "/login")
    end
  end

  def create(conn, %{"link_uuid" => link_uuid, "user" => user_params}) do
    case Exolyte.UserDB.get_user_link(link_uuid) do
      {:ok, ^link_uuid} ->
        user_id = Map.get(user_params, "user_id", "")
        password = Map.get(user_params, "password", "")
        display_name = Map.get(user_params, "display_name", "") |> String.trim()
        
        display_name = if display_name == "", do: user_id, else: display_name

        with :ok <- validate_user_id(user_id),
             :ok <- validate_password(password),
             :ok <- check_user_exists(user_id) do
          
          # Create the user
          Exolyte.UserDB.put_user(user_id, display_name, password)
          
          # Invalidate the link
          Exolyte.UserDB.delete_user_link(link_uuid)

          # Log them in and redirect
          conn
          |> put_session(:user_id, user_id)
          |> put_flash(:info, "Account created successfully!")
          |> redirect(to: "/mypage")
        else
          {:error, reason} ->
            render(conn, :new, link_uuid: link_uuid, error_message: reason)
        end

      _ ->
        conn
        |> put_flash(:error, "Invalid or expired registration link.")
        |> redirect(to: "/login")
    end
  end

  defp validate_user_id(user_id) do
    if Regex.match?(~r/^[a-z][a-z0-9_]{1,18}[a-z0-9]$/, user_id) do
      :ok
    else
      {:error, "User ID must be 3-20 characters long, start with a lowercase letter, end with a lowercase letter or number, and contain only lowercase letters, numbers, and underscores."}
    end
  end

  defp validate_password(password) do
    if String.length(password) >= 8 do
      :ok
    else
      {:error, "Password must be at least 8 characters long."}
    end
  end

  defp check_user_exists(user_id) do
    case Exolyte.UserDB.get_user(user_id) do
      nil -> :ok
      _ -> {:error, "User ID is already taken."}
    end
  end
end
