defmodule MtgFriends.DateUtils do
  @doc """
  Requires {:calendar, "~> 1.0.0"}
  """

  @date_str "%b %d, %Y"
  @time_str "%I:%M %p"

  def render_naive_datetime(dt) do
    NaiveDateTime.to_string(dt)
  end

  def render_naive_datetime_date(dt) do
    parse(dt, @date_str)
  end

  def render_naive_datetime_full(dt) do
    parse(
      dt,
      "#{@date_str} @ #{@time_str}"
    )
  end

  defp parse(dt, format) do
    Calendar.strftime(
      dt,
      format
    )
  end
end
