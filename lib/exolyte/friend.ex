defmodule Exolyte.Friend do
  alias Exolyte.{ChannelDB, UserDB}

  @doc """
  Returns a deterministic DM channel ID for two users.
  Uses a string "dm:user1:user2" to ensure compatibility with file paths
  while avoiding collisions with normal channel IDs.
  """
  def dm_channel_id(user_a_id, user_b_id) do
    [u1, u2] = Enum.sort([user_a_id, user_b_id])
    "dm:#{u1}:#{u2}"
  end

  @doc """
  Adds a friend by creating a DM channel if it doesn't exist,
  adding the initiator to it, and adding the target user if they haven't blocked it.
  """
  def add_friend(user_a_id, user_b_id) do
    channel_id = dm_channel_id(user_a_id, user_b_id)

    # Create channel if it doesn't exist
    channel_result =
      case ChannelDB.get_channel(channel_id) do
        nil ->
          ChannelDB.create_channel(channel_id, "DM")

        _ ->
          :ok
      end

    case channel_result do
      :ok ->
        # Add User A to the channel
        ChannelDB.add_user(channel_id, user_a_id)

        # Check User B's blocked_channels and add if not blocked
        user_b = UserDB.get_user(user_b_id)

        if user_b do
          blocked = Map.get(user_b, "blocked_channels", MapSet.new())

          unless MapSet.member?(blocked, channel_id) do
            ChannelDB.add_user(channel_id, user_b_id)
          end
        end

        {:ok, channel_id}

      error ->
        error
    end
  end
end
