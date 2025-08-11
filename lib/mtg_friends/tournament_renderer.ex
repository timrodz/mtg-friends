defmodule MtgFriends.TournamentRenderer do
  @moduledoc """
  Handles rendering and display functions for tournaments.
  
  This module contains all the rendering logic that was previously scattered
  in TournamentUtils, following the principle of separation of concerns.
  """

  @doc """
  Renders tournament status as text.
  
  ## Examples
  
      iex> MtgFriends.TournamentRenderer.render_status(:inactive)
      "Open"
      
      iex> MtgFriends.TournamentRenderer.render_status(:active)
      "In progress"
  """
  def render_status(status) do
    case status do
      :inactive -> "Open"
      :active -> "In progress"
      :finished -> "Finished"
    end
  end

  @doc """
  Renders tournament status with emoji decoration.
  """
  def render_status_with_emoji(status) do
    case status do
      :inactive -> "Open 🟢"
      :active -> "In progress 🔵"
      :finished -> "Finished 🔴"
    end
  end

  @doc """
  Renders round status as text.
  """
  def render_round_status(status) do
    case status do
      :inactive -> "Pairing players"
      :active -> "In progress"
      :finished -> "Finished"
      _ -> "??"
    end
  end

  @doc """
  Renders round status with emoji decoration.
  """
  def render_round_status_with_emoji(status) do
    case status do
      :inactive -> "Pairing players 🟩"
      :active -> "In progress 🟦"
      :finished -> "Finished 🟥"
    end
  end

  @doc """
  Renders tournament format as display text.
  """
  def render_format(format) do
    case format do
      :edh -> "Commander (EDH)"
      :standard -> "Standard"
      nil -> ""
    end
  end

  @doc """
  Renders tournament subformat as display text.
  """
  def render_subformat(subformat) do
    case subformat do
      :bubble_rounds -> "Bubble Rounds"
      :swiss -> "Swiss Rounds"
      nil -> ""
    end
  end

  @doc """
  Renders description of tournament subformat.
  """
  def render_subformat_description(subformat) do
    case subformat do
      :bubble_rounds ->
        "Pods are determined by last round standings"

      :swiss ->
        "Pods are determined by trying to make sure each participant plays every opponent at least once"

      nil ->
        ""
    end
  end

  @doc """
  Validates if a string is a valid URL.
  """
  def validate_url(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host =~ "."
  end
end