defmodule MtgFriends.Utils.Date do
  @doc """
  Requires {:calendar, "~> 1.0.0"}
  """

  @date_str "%b %d, %Y"
  @time_str "%I:%M %p"
  @one_minute 60
  @one_hour 3600

  def render_naive_datetime(dt) do
    NaiveDateTime.to_string(dt)
  end

  def render_naive_datetime_date(dt) do
    parse_date(dt, @date_str)
  end

  def render_naive_datetime_full(dt) do
    parse_date(
      dt,
      "#{@date_str} @ #{@time_str}"
    )
  end

  defp parse_date(dt, format) do
    Calendar.strftime(
      dt,
      format
    )
  end

  def to_hh_mm_ss(seconds) when seconds >= @one_hour do
    h = div(seconds, @one_hour)

    m =
      seconds
      |> rem(@one_hour)
      |> div(@one_minute)
      |> pad_int()

    s =
      seconds
      |> rem(@one_hour)
      |> rem(@one_minute)
      |> pad_int()

    "#{h}:#{m}:#{s}"
  end

  def to_hh_mm_ss(seconds) do
    m = div(seconds, @one_minute)

    s =
      seconds
      |> rem(@one_minute)
      |> pad_int()

    "#{m}:#{s}"
  end

  defp pad_int(int, padding \\ 2) do
    int
    |> Integer.to_string()
    |> String.pad_leading(padding, "0")
  end
end
