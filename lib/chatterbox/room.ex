defmodule Chatterbox.Room do
  @moduledoc """
  This module is responsible on managing messages and sending them back to the user
  """
  alias Chatterbox.Message
  use GenServer

  # Client

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def join(pid, user_id) do
    GenServer.call(pid, {:join, user_id})
  end

  def send_message(pid, user_pid, content) do
    GenServer.cast(pid, {:send_message, user_pid, content})
  end

  # Server

  def init(args) do
    {:ok, %{messages: [], allowed_user_ids: args.allowed_user_ids, connected_users: %{}}}
  end

  def handle_cast(
        {:send_message, user_pid, content},
        %{connected_users: connected_users, messages: messages} = state
      ) do
    user_id = Map.get(connected_users, user_pid)
    message = %Message{sender_id: user_id, content: content}

    updated_messages = [message | messages]

    for {pid, _} <- connected_users do
      send(pid, {:updated_messages, updated_messages})
    end

    {:noreply, %{state | messages: updated_messages}}
  end

  def handle_call(
        {:join, user_id},
        {pid, _},
        %{allowed_user_ids: allowed_user_ids, connected_users: connected_users} = state
      ) do
    if user_id in allowed_user_ids do
      Process.monitor(pid)
      {:reply, :ok, %{state | connected_users: Map.put(connected_users, pid, user_id)}}
    else
      {:reply, :error, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {_, updated_connected_users} = Map.pop(state.connected_users, pid)
    {:noreply, %{state | connected_users: updated_connected_users}}
  end
end
