defmodule Chatterbox.RoomTest do
  use ExUnit.Case, async: true
  alias Chatterbox.{Message, Room}

  setup do
    user_1 = "user_1"
    user_2 = "user_2"
    user_roles = %{user_1 => :requester, user_2 => :responder}
    pid = start_link_supervised!({Room, %{user_roles: user_roles}})
    %{room_pid: pid}
  end

  test "Able to join the room", %{room_pid: pid} do
    assert Room.join(pid, "user_1") == {:ok, :requester}
    assert Room.join(pid, "user_2") == {:ok, :responder}
  end

  test "Not be able to join the room if the user is not on the list", %{room_pid: pid} do
    assert Room.join(pid, "user_3") == :error
  end

  test "Receive an updated copy of the conversation upon sending a message", %{room_pid: pid} do
    Room.join(pid, "user_1")
    assert Room.send_message(pid, "user_1", "This is a test message")

    assert_receive {:updated_messages,
                    [%Message{sender_id: "user_1", content: "This is a test message"}]}
  end

  test "Able to fetch updated messages", %{room_pid: pid} do
    Room.join(pid, "user_1")
    Room.send_message(pid, self(), "This is a one of the message of all time!")

    assert_receive {:updated_messages, messages}
    assert messages == Room.get_messages(pid)
  end

  test "Able to propagate offers", %{room_pid: pid} do
    Room.join(pid, "user_1")
    Room.set_offer(pid, "this is one of the offers of all time")
    assert_receive {:updated_offer, "this is one of the offers of all time"}
  end

  test "Able to propagate answers", %{room_pid: pid} do
    Room.join(pid, "user_1")
    Room.set_answer(pid, "this is one of the answers of all time")
    assert_receive {:updated_answer, "this is one of the answers of all time"}
  end

  test "Able to propagate candidate info", %{room_pid: pid} do
    Room.join(pid, "user_1")
    Room.set_candidate(pid, "one of the candidates of all time!")
    assert_receive {:updated_candidate, "one of the candidates of all time!"}
  end
end
