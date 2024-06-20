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

```elixir
mix phx.gen.live BankAccounts BankAccount bank_accounts identifier description currency user_id:references:users
mix phx.gen.live BankStatements Statement bank_statements filename status source_headers header_account_number header_description header_date header_credit header_debit header_balance bank_account_id:references:bank_accounts
mix phx.gen.live BankStatements.Entry StatementEntry bank_statement_entries date:date description debit:float credit:float balance:float bank_statement_id:references:bank_statements
```
