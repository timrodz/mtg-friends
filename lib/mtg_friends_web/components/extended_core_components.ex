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

      <.item_grid id="users" items={@users} title="users">
        <:item :let={user}>
          <p>User ID: <%= user.id %></p>
        </:item>
      </.item_grid>
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:items, :list, required: true)
  attr(:item_id, :any, default: nil, doc: "the function for generating the item id")
  attr(:item_click, :any, default: nil, doc: "the function for handling phx-click on each item")
  attr(:class, :string, default: nil)
  attr(:grid_class, :string, default: nil)
  attr(:item_container_class, :string, default: nil)

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each item before calling the :col and :action slots"
  )

  slot :item, required: true do
    attr(:class, :string)
  end

  def item_grid(assigns) do
    assigns =
      with %{items: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, item_id: assigns.item_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div id={"item-grid-#{@id}"} class={["item-grid mt-10 mb-6", @class]}>
      <%= if @title do %>
        <h3 class="text-xl font-bold mb-4"><%= @title %></h3>
      <% end %>
      <div
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @items) && "stream"}
        class={[
          "item-grid overflow-y-auto sm:overflow-visible sm:px-0 grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6",
          @grid_class
        ]}
      >
        <div
          :for={item <- @items}
          id={@item_id && @item_id.(item)}
          class={[
            "item-container border-[1px] border-slate-200 bg-white rounded-md hover:bg-slate-50 hover:cursor-pointer",
            @item_container_class
          ]}
        >
          <div
            :for={{col, _index} <- Enum.with_index(@item)}
            phx-click={@item_click && @item_click.(item)}
            class={[
              "item relative p-4 text-black flex flex-col gap-1",
              @item_click && "hover:cursor-pointer",
              col[:class]
            ]}
          >
            <%= render_slot(col, @row_item.(item)) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:dt, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:no_icon, :boolean, default: false)

  def datetime(assigns) do
    ~H"""
    <p id="date-time" class={["icon-text", @class]}>
      <CoreComponents.icon :if={not @no_icon} name="hero-clock-solid" />
      <%= @label %>
      <span><%= @dt |> DateUtils.render_naive_datetime_full() %></span>
    </p>
    """
  end

  attr(:dt, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:no_icon, :boolean, default: false)

  def date(assigns) do
    ~H"""
    <p class={["icon-text", @class]}>
      <CoreComponents.icon :if={not @no_icon} name="hero-calendar-solid" />
      <%= @label %>
      <span><%= @dt |> DateUtils.render_naive_datetime_date() %></span>
    </p>
    """
  end
end
