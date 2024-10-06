defmodule Chatterbox.RoomTest do
  use ExUnit.Case, async: true
  alias Chatterbox.{Message, Room}

  test "Able to join the room" do
    {:ok, pid} = Room.start_link(%{allowed_user_ids: ["user_1", "user_2"]})
    assert Room.join(pid, "user_1") == :ok
    assert Room.join(pid, "user_2") == :ok
  end

  test "Not be able to join the room if the user is not on the list" do
    {:ok, pid} = Room.start_link(%{allowed_user_ids: ["user_1", "user_2"]})
    assert Room.join(pid, "user_3") == :error
  end

  test "Receive an updated copy of the conversation upon sending a message" do
    {:ok, pid} = Room.start_link(%{allowed_user_ids: ["user_1", "user_2"]})
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
