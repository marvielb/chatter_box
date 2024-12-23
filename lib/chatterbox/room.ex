defmodule Chatterbox.Room do
  defmodule State do
    @moduledoc """
    Encapsulates the room's state
    """
    defstruct [:messages, :user_roles, :connected_users, :offer, :answer]
  end

  @moduledoc """
  This module is responsible on managing messages and sending them back to the user.
  Also holds information about the WebRTC info for both users and able to propagate it to one another.
  """
  alias Chatterbox.Message
  alias Chatterbox.User
  use GenServer

  @max_messages 100

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

  def set_offer(pid, offer) do
    GenServer.cast(pid, {:set_offer, offer})
  end

  def set_answer(pid, answer) do
    GenServer.cast(pid, {:set_answer, answer})
  end

  def set_candidate(pid, candidate) do
    GenServer.cast(pid, {:set_candidate, candidate})
  end

  def send_message(pid, user_id, content) do
    GenServer.cast(pid, {:send_message, user_id, content})
  end

  def get_messages(pid) do
    GenServer.call(pid, :get_messages)
  end

  def get_offer(pid) do
    GenServer.call(pid, :get_offer)
  end

  # Server

  def init(args) do
    no_user_check_duration = args[:no_user_check_duration] || 5000
    Process.send_after(self(), :no_user_check, no_user_check_duration)
    {:ok, %State{messages: [], user_roles: args.user_roles, connected_users: %{}}}
  end

  def handle_call({:join, user_id}, {pid, _}, %State{} = state) do
    case Map.get(state.user_roles, user_id) do
      nil ->
        {:reply, :error, state}

      role ->
        Process.monitor(pid)

        {:reply, {:ok, role},
         %{state | connected_users: Map.put(state.connected_users, pid, %User{id: user_id})}}
    end
  end

  def handle_call(:get_messages, _, %State{} = state) do
    {:reply, state.messages, state}
  end

  def handle_call(:get_offer, _, %State{} = state) do
    {:reply, state.offer, state}
  end

  def handle_cast({:send_message, user_id, content}, state) do
    message = %Message{sender_id: user_id, content: content}

    updated_messages =
      if Enum.count(state.messages) < @max_messages do
        [message | state.messages]
      else
        [message | List.delete_at(state.messages, -1)]
      end

    for {pid, _} <- state.connected_users do
      send(pid, {:updated_messages, updated_messages})
    end

    {:noreply, %{state | messages: updated_messages}}
  end

  def handle_cast({:set_offer, offer}, %State{} = state) do
    for {pid, _} <- state.connected_users do
      send(pid, {:updated_offer, offer})
    end

    {:noreply, %{state | offer: offer}}
  end

  def handle_cast({:set_answer, answer}, %State{} = state) do
    for {pid, _} <- state.connected_users do
      send(pid, {:updated_answer, answer})
    end

    {:noreply, %{state | answer: answer}}
  end

  def handle_cast({:set_candidate, candidate}, %State{} = state) do
    for {pid, _} <- state.connected_users do
      send(pid, {:updated_candidate, candidate})
    end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_info(:no_user_check, %State{} = state) do
    if map_size(state.connected_users) < 2 do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end
end
