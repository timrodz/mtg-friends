defmodule MtgFriends.Utils.ProfanityFilter do
  @moduledoc """
  Validates text against a list of restricted words using Expletive.
  https://github.com/xavier/expletive
  """

  @blacklist ~w(admin staff root )
  @config Expletive.configure(blacklist: Expletive.Blacklist.english() ++ @blacklist)

  def text_safe?(text) do
    not Expletive.profane?(text, @config)
  end

  def text_profane?(text) do
    Expletive.profane?(text, @config)
  end
end
