# Tie Breaker

Tie Breaker is a trading card game (TCG) management web application, built with Elixir, Phoenix, and Postgres. It's deployed in Fly.io

## Deployments

Deploy the application live:

```shell
fly deploy
```

## Accessing the database

[Fly connection guide](https://fly.io/docs/postgres/connecting/connecting-with-flyctl/)

Connect via `psql`

```shell
fly postgres connect -a <database-name>
```
