# MtgFriends

To start your Phoenix server:

- Create an `.env` file with the valid configs at the root of this directory, and run `source .env` afterwards
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

## Deployments

TODO: Connect Github Actions to Fly

Deploy the application live:

```shell
fly deploy
```

## Accessing the database

https://fly.io/docs/postgres/connecting/connecting-with-flyctl/

Connect via `psql`

```shell
fly postgres connect -a <database-name>
```
