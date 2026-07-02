defmodule Exolyte.Settings do
  use Agent
  require Logger

  @settings_file "priv/settings.json"

  @default_settings %{
    "allow_user_invites" => false,
    "allow_channel_creation" => true,
    "instance_name" => "Exolyte Instance"
  }

  def start_link(_opts) do
    Agent.start_link(fn -> load_settings() end, name: __MODULE__)
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  def update(new_settings) do
    Agent.get_and_update(__MODULE__, fn current_settings ->
      # Merge new settings with existing settings, ensuring keys are strings
      updated_settings =
        current_settings
        |> Map.merge(new_settings)
        |> ensure_boolean("allow_user_invites")
        |> ensure_boolean("allow_channel_creation")

      save_settings(updated_settings)
      {updated_settings, updated_settings}
    end)
  end

  defp load_settings do
    case File.read(@settings_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, decoded} ->
            Map.merge(@default_settings, decoded)
          {:error, _} ->
            Logger.warning("Failed to decode settings.json, using defaults.")
            @default_settings
        end
      {:error, _} ->
        Logger.info("settings.json not found, initializing with default settings.")
        save_settings(@default_settings)
        @default_settings
    end
  end

  defp save_settings(settings) do
    case Jason.encode(settings, pretty: true) do
      {:ok, json} ->
        # Ensure priv directory exists
        File.mkdir_p!(Path.dirname(@settings_file))
        File.write!(@settings_file, json)
      {:error, reason} ->
        Logger.error("Failed to encode settings: #{inspect(reason)}")
    end
  end

  # Helper to ensure checkboxes which may come as "true"/"false" strings are properly cast to boolean
  defp ensure_boolean(map, key) do
    case Map.get(map, key) do
      "true" -> Map.put(map, key, true)
      "false" -> Map.put(map, key, false)
      _ -> map # If it's already a boolean or nil, keep it
    end
  end
end
