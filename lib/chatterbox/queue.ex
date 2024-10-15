defmodule Chatterbox.Queue do
  @moduledoc """
  This the queue module where it holds the a live view instance that does not have a pair yet.
  Once a new user joins the queue, a room will be craeted then they will be immediately paired with that user.
  """
  alias Chatterbox.Room

  use GenServer

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def join(pid, user) do
    GenServer.call(__MODULE__, {:join, pid, user})
  end

  # Server

  def init(_) do
    {:ok, %{previous_view: nil}}
  end

  def handle_call({:join, pid, user_id}, _, %{previous_view: previous_view} = state) do
    Process.monitor(pid)
    view = {pid, user_id}

    case previous_view do
      nil ->
        {:reply, :ok, %{state | previous_view: view}}

      {_, ^user_id} ->
        {:reply, {:error, :already_joined}, %{state | previous_view: view}}

      _ ->
        create_room(previous_view, view)
        {:reply, :ok, %{state | previous_view: nil}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    with {previous_view_pid, _} <- state.previous_view,
         ^pid <- previous_view_pid do
      {:noreply, %{state | previous_view: nil}}
    else
      _ -> {:noreply, state}
    end
  end

  defp create_room({pid, user_id_1}, {pid2, user_id_2}) do
    room_id = UUID.uuid4()
    name = {:via, Registry, {Chatterbox.RoomRegistry, room_id}}

    {:ok, _} =
      Room.start(%{user_roles: %{user_id_1 => :requester, user_id_2 => :responder}}, name: name)

    send(pid, {:room_ready, room_id})
    send(pid2, {:room_ready, room_id})
  end
end
