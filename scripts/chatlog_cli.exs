# scripts/chatlog_cli.exs

IO.inspect(ChannelLogManager.update("bazchannel", %{"user_id" => "alice", "content" => "Hello!"}))