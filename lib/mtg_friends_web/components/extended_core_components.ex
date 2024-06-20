defmodule MtgFriendsWeb.ExtendedCoreComponents do
  @moduledoc """
  Import this module inside the MtgFriendsWeb module's `html_helpers` function
  """
  use Phoenix.Component

  alias MtgFriendsWeb.CoreComponents
  alias MtgFriends.DateUtils

  @doc ~S"""
  Renders a container with generic styling.

  ## Examples

      <.item_grid id="users" rows={@users} title="users">
        <:item :let={user}>
          <p>User ID: <%= user.id %></p>
        </:item>
      </.item_grid>
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")
  attr(:class, :string, default: nil)

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :item, required: true do
    attr(:class, :string)
  end

  def item_grid(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div id={"item-grid-#{@id}"} class={["item-grid mt-10 mb-6", @class]}>
      <%= if @title do %>
        <h3 class="text-xl font-bold mb-4"><%= @title %></h3>
      <% end %>
      <div
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        class="item-grid-contents overflow-y-auto sm:overflow-visible sm:px-0 grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-2"
      >
        <div
          :for={row <- @rows}
          id={@row_id && @row_id.(row)}
          class="item border-[1px] rounded-md bg-white hover:bg-zinc-50 hover:cursor-pointer"
        >
          <div
            :for={{col, _index} <- Enum.with_index(@item)}
            phx-click={@row_click && @row_click.(row)}
            class={[
              "item-container relative p-4 text-black flex flex-col gap-1",
              @row_click && "hover:cursor-pointer",
              col[:class]
            ]}
          >
            <%= render_slot(col, @row_item.(row)) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:dt, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :string, default: nil)

  def datetime(assigns) do
    ~H"""
    <p id="date-time" class={["icon-text", @class]}>
      <CoreComponents.icon name="hero-clock-solid" />
      <%= @label %>
      <span><%= @dt |> DateUtils.render_naive_datetime_full() %></span>
    </p>
    """
  end

  attr(:dt, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :string, default: nil)

  def date(assigns) do
    ~H"""
    <p class={["icon-text", @class]}>
      <CoreComponents.icon name="hero-calendar-solid" />
      <%= @label %>
      <span><%= @dt |> DateUtils.render_naive_datetime_date() %></span>
    </p>
    """
  end
end
