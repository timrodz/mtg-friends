defmodule MtgFriendsWeb.ExtendedCoreComponents do
  @moduledoc """
  Import this module inside the MtgFriendsWeb module's `html_helpers` function
  """
  use Phoenix.Component

  alias MtgFriends.TournamentRenderer
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
    <div id={"item-grid-#{@id}"} class={["item-grid mt-6 mb-6", @class]}>
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
            "item-container border-[1px] border-slate-200 bg-white rounded-md shadow-sm",
            @item_click && "hover:bg-slate-50 hover:cursor-pointer",
            @item_container_class
          ]}
        >
          <div
            :for={{col, _index} <- Enum.with_index(@item)}
            phx-click={@item_click && @item_click.(item)}
            class={[
              "item relative p-4 text-black flex flex-col gap-1 h-full",
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

  @doc """
  Generates a generic badge message.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "self-center inline-flex items-center rounded-md px-2 py-1 font-medium text-zinc-700 ring-1 ring-inset ring-slate-200",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :value, :string, required: true

  def tournament_status(assigns) do
    case assigns.value do
      :inactive ->
        ~H"""
        <.badge class="!ring-emerald-200"><%= TournamentRenderer.render_status(@value) %></.badge>
        """

      :active ->
        ~H"""
        <.badge class="!ring-blue-500"><%= TournamentRenderer.render_status(@value) %></.badge>
        """

      :finished ->
        ~H"""
        <.badge class="!ring-red-200"><%= TournamentRenderer.render_status(@value) %></.badge>
        """

      _ ->
        ""
    end
  end

  attr :value, :string, required: true

  def round_status(assigns) do
    case assigns.value do
      :inactive ->
        ~H"""
        <.badge class="!ring-emerald-200"><%= TournamentRenderer.render_round_status(@value) %></.badge>
        """

      :active ->
        ~H"""
        <.badge class="!ring-blue-500"><%= TournamentRenderer.render_round_status(@value) %></.badge>
        """

      :finished ->
        ~H"""
        <.badge class="!ring-red-200"><%= TournamentRenderer.render_round_status(@value) %></.badge>
        """

      _ ->
        ""
    end
  end

  attr :time_left, :string, required: true
  attr :seconds_left, :float, required: true

  def round_timer(assigns) do
    ds = assigns.seconds_left

    timer_class =
      cond do
        ds > 60 * 5 and ds <= 60 * 10 -> "rounded-lg bg-yellow-200"
        ds >= 60 and ds <= 60 * 5 -> "rounded-lg bg-orange-200"
        ds > 0 and ds < 60 -> "animate-bounce rounded-lg bg-red-200"
        ds <= 0 -> "rounded-lg bg-red-200"
        true -> ""
      end

    assigns = assign(assigns, :timer_class, timer_class)

    ~H"""
    <div class="round_countdown_timer" class={["", @timer_class]}>
      Round time: <span class="font-mono"><%= @time_left %></span>
    </div>
    """
  end

  @doc """
  Renders a participant's decklist with proper styling.
  Replaces the raw HTML generation that was in TournamentUtils.
  """
  attr :decklist, :string, required: true

  def participant_decklist(assigns) do
    case assigns.decklist do
      nil ->
        ~H"""
        <p class="text-orange-300">---</p>
        """

      decklist when is_binary(decklist) ->
        case TournamentRenderer.validate_url(decklist) do
          true ->
            ~H"""
            <span class="inline-flex items-center rounded-md bg-orange-200 px-2 py-1 text-xs font-medium text-zinc-700 ring-1 ring-inset ring-teal-900/10">
              <a href={@decklist} target="_blank">Decklist</a>
            </span>
            """

          false ->
            ~H"""
            <p><%= @decklist %></p>
            """
        end

      _ ->
        ~H"""
        <p class="text-orange-300">---</p>
        """
    end
  end
end
