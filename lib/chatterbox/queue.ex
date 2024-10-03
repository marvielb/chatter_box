defmodule Chatterbox.Queue do
  @moduledoc """
  This the queue module where it holds the a live view instance that does not have a pair yet.
  Once a new user joins the queue, a room will be craeted then they will be immediately paired with that user.
  """

  use GenServer

  def join(pid, user) do
    GenServer.call(__MODULE__, {:join, pid, user})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{previous_view: nil}}
  end

  def handle_call({:join, pid, user}, _, %{previous_view: previous_view} = state) do
    Process.monitor(pid)
    view = {pid, user}

    case previous_view do
      nil ->
        {:reply, :ok, %{state | previous_view: view}}

      _ ->
        create_room(previous_view, view)
        {:reply, :ok, %{state | previous_view: nil}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {previous_view_pid, _} = state.previous_view

    if previous_view_pid == pid do
      {:noreply, %{state | previous_view: nil}}
    else
      {:noreply, state}
    end
  end

  defp create_room({pid, user}, {pid2, user2}) do
    room_id = "#{user.id} - #{user2.id}"
    send(pid, {:room_ready, room_id})
    send(pid2, {:room_ready, room_id})
  end
end
