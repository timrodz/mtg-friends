defmodule MtgFriendsWeb.ExtendedCoreComponents do
  @moduledoc """
  Import this module inside the MtgFriendsWeb module's `html_helpers` function
  """
  use Phoenix.Component

  alias MtgFriends.TournamentRenderer
  alias MtgFriendsWeb.CoreComponents
  alias MtgFriends.Utils.Date

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
        <h3 class="text-xl font-bold mb-4">{@title}</h3>
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
            "card card-border border-base-300 bg-base-100",
            @item_container_class
          ]}
        >
          <div
            :for={{col, _index} <- Enum.with_index(@item)}
            phx-click={@item_click && @item_click.(item)}
            class={[
              "p-4 text-base-content w-full",
              @item_click && "hover:cursor-pointer",
              col[:class]
            ]}
          >
            {render_slot(col, @row_item.(item))}
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
      {@label}
      <span>{@dt |> Date.render_naive_datetime_full()}</span>
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
      {@label}
      <span>{@dt |> Date.render_naive_datetime_date()}</span>
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
      "badge",
      @class
    ]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :value, :string, required: true

  def tournament_status(assigns) do
    case assigns.value do
      :inactive ->
        ~H"""
        <.badge class="badge-info badge-soft">
          <CoreComponents.icon name="hero-pencil-square" />
          {TournamentRenderer.render_status(@value)}
        </.badge>
        """

      :active ->
        ~H"""
        <.badge class="badge-success badge-soft">
          <CoreComponents.icon name="hero-power-solid" />
          {TournamentRenderer.render_status(@value)}
        </.badge>
        """

      :finished ->
        ~H"""
        <.badge class="badge-error badge-soft">
          <CoreComponents.icon name="hero-x-mark-solid" />
          {TournamentRenderer.render_status(@value)}
        </.badge>
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
        <.badge class="badge-info">
          <CoreComponents.icon name="hero-clock-solid" />
          {TournamentRenderer.render_round_status(@value)}
        </.badge>
        """

      :active ->
        ~H"""
        <.badge class="badge-success">
          <CoreComponents.icon name="hero-power-solid" />{TournamentRenderer.render_round_status(@value)}
        </.badge>
        """

      :finished ->
        ~H"""
        <.badge class="badge-secondary">
          <CoreComponents.icon name="hero-x-mark-solid" />
          {TournamentRenderer.render_round_status(@value)}
        </.badge>
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
      Round time: <span class="font-mono">{@time_left}</span>
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
      decklist when is_binary(decklist) ->
        case TournamentRenderer.validate_url(decklist) do
          true ->
            ~H"""
            <p>
              <.link
                href={@decklist}
                target="_blank"
                class="link link-primary link-hover font-mono truncate"
              >
                Decklist
              </.link>
            </p>
            """

          false ->
            ~H"""
            <p class="font-mono">{@decklist}</p>
            """
        end

      _ ->
        ~H"""
        """
    end
  end
end
