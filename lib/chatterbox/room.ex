defmodule Chatterbox.Room do
  @moduledoc """
  This module is responsible on managing messages and sending them back to the user
  """
  alias Chatterbox.Message
  use GenServer
  @prefix [:chatterbox, :room, :call]

  # Client

  def start_link(init_args, options \\ []) do
    GenServer.start_link(__MODULE__, init_args, options)
  end

  def start(init_args, options \\ []) do
    GenServer.start(__MODULE__, init_args, options)
  end

  def join(pid, user_id) do
    GenServer.call(pid, {:join, user_id})
  end

  def set_offer(pid, user_pid, offer) do
    GenServer.cast(pid, {:set_offer, user_pid, offer})
  end

  def send_message(pid, user_pid, content) do
    GenServer.cast(pid, {:send_message, user_pid, content})
  end

  # Server

  def init(args) do
    {:ok, %{messages: [], members: args.members, connected_users: %{}, offer: nil}}
  end

  def handle_cast({:send_message, user_pid, content}, state) do
    user_id = Map.get(state.connected_users, user_pid)
    message = %Message{sender_id: user_id, content: content}

    updated_messages = [message | state.messages]

    for {pid, _} <- state.connected_users do
      send(pid, {:updated_messages, updated_messages})
    end

    {:noreply, %{state | messages: updated_messages}}
  end

  def handle_cast({:set_offer, user_pid, offer}, state) do
    {_, other_user_pids} = state.connected_users |> Map.pop(user_pid)

    for {pid, _} <- other_user_pids do
      send(pid, {:updated_offer, offer})
    end

    {:noreply, %{state | offer: offer}}
  end

  def handle_call({:join, user_id}, {pid, _}, state) do
    :telemetry.execute(
      @prefix ++ [:join],
      %{},
      %{user_id: user_id, pid: pid, state: state}
    )

    is_member = user_id in (state.members |> Map.values() |> Enum.map(& &1.id))

    if is_member do
      Process.monitor(pid)

      role =
        case state.members |> Map.get(:requester) |> Map.get(:id) do
          ^user_id -> :requester
          _ -> :responder
        end

      {:reply, {:ok, state.messages, role, state.offer},
       %{state | connected_users: Map.put(state.connected_users, pid, user_id)}}
    else
      {:reply, :error, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {_, updated_connected_users} = Map.pop(state.connected_users, pid)
    {:noreply, %{state | connected_users: updated_connected_users}}
  end
end
