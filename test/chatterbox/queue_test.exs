defmodule Chatterbox.QueueTest do
  use ExUnit.Case, async: false

  alias Hex.API.User
  alias Chatterbox.{User, Queue}

  setup do
    Queue.start_link(nil)
    :ok
  end

  test "adds user" do
    user = %User{id: "test"}
    Queue.add_user(user)
    length = Queue.length()
    assert length == 1
  end

  test "removes user" do
    user = %User{id: "test"}
    Queue.add_user(user)
    length = Queue.length()
    assert length == 1
    Queue.remove_user("test")
    length = Queue.length()
    assert length == 0
  end

  test "returns empty list if there is only 1 user" do
    user = %User{id: "test"}
    Queue.add_user(user)
    _ = Queue.length()
    pair = Queue.get_pair()
    assert pair == []
  end

  test "returns a list of users if more than 1 user" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    Queue.add_user(user)
    Queue.add_user(user2)
    length = Queue.length()
    assert length == 2
    assert [user2, user] == Queue.get_pair()
  end

  test "gets first two user inserted first" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    user3 = %User{id: "test3"}
    Queue.add_user(user)
    Queue.add_user(user2)
    Queue.add_user(user3)
    length = Queue.length()
    assert length == 3
    assert [user2, user] == Queue.get_pair()
    assert Queue.length() == 1
    assert Queue.get_pair() == []
  end

  test "gets first two user inserted first then another pair again" do
    user = %User{id: "test"}
    user2 = %User{id: "test2"}
    user3 = %User{id: "test3"}
    user4 = %User{id: "test4"}
    Queue.add_user(user)
    Queue.add_user(user2)
    Queue.add_user(user3)
    Queue.add_user(user4)
    length = Queue.length()
    assert length == 4
    assert [user2, user] == Queue.get_pair()
    assert Queue.length() == 2
    assert Queue.get_pair() == [user4, user3]
  end
end
