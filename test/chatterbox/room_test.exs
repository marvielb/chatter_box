defmodule Chatterbox.RoomTest do
  use ExUnit.Case, async: true
  alias Chatterbox.{Message, Room, User}

  setup do
    user_1 = %User{id: "user_1"}
    user_2 = %User{id: "user_2"}
    %{members: %{requester: user_1, responder: user_2}}
  end

  test "Able to join the room", %{members: members} do
    {:ok, pid} = Room.start_link(%{members: members})
    assert Room.join(pid, "user_1") == :ok
    assert Room.join(pid, "user_2") == :ok
  end

  test "Not be able to join the room if the user is not on the list", %{members: members} do
    {:ok, pid} = Room.start_link(%{members: members})
    assert Room.join(pid, "user_3") == :error
  end

  test "Receive an updated copy of the conversation upon sending a message", %{members: members} do
    {:ok, pid} = Room.start_link(%{members: members})
    assert Room.join(pid, "user_1") == :ok
    assert Room.send_message(pid, self(), "This is a test message")

    receive do
      {:updated_messages, value} ->
        assert value == [%Message{sender_id: "user_1", content: "This is a test message"}]
    after
      1_000 -> raise "No messages received"
    end
  end
end
