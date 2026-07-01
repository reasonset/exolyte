defmodule Exolyte.Notification do
  @ntfy_setting Application.compile_env(:exolyte, :ntfy)

  def ntfy_to(topic) do
    if (topic && @ntfy_setting["enable"]) do
      IO.puts("TOPIC ON")
    else
      IO.puts("TOPIC OFF")
    end
  end
end
