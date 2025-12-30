defmodule MtgFriendsWeb.ApiSpecParamsTest do
  use ExUnit.Case, async: false
  alias MtgFriendsWeb.ApiSpec

  describe "API Spec Generation" do
    test "spec generates successfully without errors" do
      assert %OpenApiSpex.OpenApi{} = ApiSpec.spec()
    end

    test "spec generation does not leak atoms significantly" do
      # Force garbage collection to get a stable baseline
      :erlang.garbage_collect()
      initial_atom_count = :erlang.system_info(:atom_count)

      # Generate the spec multiple times
      for _ <- 1..5 do
        ApiSpec.spec()
      end

      # Force GC again
      :erlang.garbage_collect()
      final_atom_count = :erlang.system_info(:atom_count)

      # We allow a very small variance, but ideally it should be 0 for purely static specs.
      # However, some runtime optimizations or lazy loading might cause a tiny increase perfectly validly.
      # A large increase would indicate dynamic atom creation per call.
      diff = final_atom_count - initial_atom_count

      # Should be very low. Setting a conservative limit of 50 to catch egregious leaks.
      # If this flakes, we can adjust, but for static specs it should be near zero.
      assert diff < 50,
             "API Spec generation leaked #{diff} atoms, possible dynamic atom creation detected!"
    end
  end
end
