defmodule Chatterbox.UserTrackerTest do
  use ExUnit.Case, async: false

  alias Hex.API.User
  alias Chatterbox.{User, UserTracker}

  setup do
    UserTracker.start_link(nil)
    :ok
  end

  test "adds user" do
    user = %User{id: "test"}
    UserTracker.add_user(user)
    length = UserTracker.length()
    assert length == 1
  end

  test "returns empty list if there is only 1 user" do
    user = %User{id: "test"}
    UserTracker.add_user(user)
    _ = UserTracker.length()
    pair = UserTracker.get_pair()
    assert pair == []
  end

  test "returns a list of users if more than 1 user" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    UserTracker.add_user(user)
    UserTracker.add_user(user2)
    length = UserTracker.length()
    assert length == 2
    assert [user2, user] == UserTracker.get_pair()
  end

  test "gets first two user inserted first" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    user3 = %User{id: "test3"}
    UserTracker.add_user(user)
    UserTracker.add_user(user2)
    UserTracker.add_user(user3)
    length = UserTracker.length()
    assert length == 3
    assert [user2, user] == UserTracker.get_pair()
    assert UserTracker.length() == 1
    assert UserTracker.get_pair() == []
  end

  test "gets first two user inserted first then another pair again" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    user3 = %User{id: "test3"}
    user4 = %User{id: "test4"}
    UserTracker.add_user(user)
    UserTracker.add_user(user2)
    UserTracker.add_user(user3)
    UserTracker.add_user(user4)
    length = UserTracker.length()
    assert length == 4
    assert [user2, user] == UserTracker.get_pair()
    assert UserTracker.length() == 2
    assert UserTracker.get_pair() == [user4, user3]
  end
end
