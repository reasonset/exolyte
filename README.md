# exolyte

## Synopsis

Minimalist Elixir-based chat system for the web. Built for rapid prototyping and OSS exploration.

## Dependencies

* Elixir 1.18

## How to use

### Run on local

* Clone git repository `git clone https://github.com/reasonset/exolyte.git`
* `cd exolyte`
* Get dependencies `mix deps.get`
* Compile `mix compile`
* Start server `mix phx.server`

### User and Channel control

If you run the script while the server is running, **you must restart the server after the script completes.**

#### Create User

```
mix run scripts/user_cli.exs put <user_id> <display_name> <password>
```

#### Create Channel

```
mix run scripts/channel_cli.exs create <channel_id> <channel_name>
```

#### Join user to channel

```
mix run scripts/channel_cli.exs adduser <channel_id> <user_id>
```

#### Create user password reset link

```
mix run scripts/user_cli.exs reset <user_id>
```

This script returns reset link id.
Reset URL is `http(s)://<domain.tld>[:<port>]/reset/<reset_link_id>`.

Reset link expires after 24 hours passed.

### Deploy for prod

* Create secret key with `mix phx.gen.secret`
* Clone repository on prod server
* `cd`
* `mix deps.get`
* Configure the `check_origin` and `url` settings in `config/prod.exs` according to your environment.
* `SECRET_KEY_BASE=${secret_key} MIX_ENV=prod mix compile`
* `SECRET_KEY_BASE=${secret_key} MIX_ENV=prod mix phx.server`

When using Nginx or similar as a reverse proxy, you need to configure it to allow WebSocket traffic.

`systemd/exolyte.service` can be used as a Systemd service unit.
Replace the `Environment` line with the appropriate values.

## URLs

* `/mypage` -> User Mypage
* `/login` -> Login page
* `/channel/:channel_id` -> Chat channel
