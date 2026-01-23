defmodule MtgFriendsWeb.ApiSpec do
  @moduledoc """
  OpenAPI Specification for the MtgFriends API.

  ## Security Warning
  Do NOT use `OpenApiSpex.resolve_schema_modules/1` with untrusted data or modify this module
  to load specs dynamically from external sources at runtime. This practice can lead to atom
  table exhaustion as schemas are converted to atoms.
  """
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, Server, SecurityScheme}
  alias MtgFriendsWeb.{Endpoint, Router}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "Tie Breaker API",
        version: to_string(Application.spec(:mtg_friends, :vsn))
      },
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{"authorization" => %SecurityScheme{type: "http", scheme: "bearer"}}
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
