defmodule MtgFriends.Repo.Migrations.ModifyMetadataForTournament do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :status, :string, default: "inactive"
      add :round_length_minutes, :integer, default: 60
      modify :format, :string, default: "edh"
      modify :subformat, :string, default: "bubble_rounds"
      remove :active
      remove :standings_raw
    end
  end

  def down do
    alter table(:tournaments) do
      remove :status
      remove :round_length_minutes
      modify :format, :string, default: "edh"
      modify :subformat, :string, default: "bubble_rounds"
      add :active, :boolean
      add :standings_raw, :string
    end
  end

  # def up do
  #   throttle_change_in_batches(&page_query/1, &do_change/1)
  # end

  # def do_change(batch_of_ids) do
  #   {_updated, results} =
  #     repo().update_all(
  #       from(t in "weather", select: t.id, where: t.id in ^batch_of_ids),
  #       [set: [approved: true]],
  #       log: :info
  #     )

  #   not_updated =
  #     MapSet.difference(MapSet.new(batch_of_ids), MapSet.new(results)) |> MapSet.to_list()

  #   Enum.each(not_updated, &handle_non_update/1)
  #   results
  # end

  # def page_query(last_id) do
  #   # Notice how we do not use Ecto schemas here.
  #   from(
  #     t in "tournaments",
  #     select: t.id,
  #     where: t.id > ^last_id,
  #     order_by: [asc: t.id],
  #     limit: @batch_size
  #   )
  # end

  # defp throttle_change_in_batches(query_fun, change_fun, last_pos \\ 0)
  # defp throttle_change_in_batches(_query_fun, _change_fun, nil), do: :ok

  # defp throttle_change_in_batches(query_fun, change_fun, last_pos) do
  #   case repo().all(query_fun.(last_pos), log: :info, timeout: :infinity) do
  #     [] ->
  #       :ok

  #     ids ->
  #       results = change_fun.(List.flatten(ids))
  #       next_page = results |> Enum.reverse() |> List.first()
  #       Process.sleep(@throttle_ms)
  #       throttle_change_in_batches(query_fun, change_fun, next_page)
  #   end
  # end

  # defp handle_non_update(id) do
  #   raise "#{inspect(id)} was not updated"
  # end
end
