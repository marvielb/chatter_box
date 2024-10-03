defmodule Chatterbox.Queue do
  use GenServer

  def monitor(pid, meta) do
    GenServer.call(__MODULE__, {:monitor, pid, meta})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{previous_user: nil}}
  end

  def handle_call({:monitor, pid, meta}, _, %{previous_user: previous_user} = state) do
    Process.monitor(pid)
    user = {pid, meta}

    case previous_user do
      nil ->
        {:reply, :ok, %{state | previous_user: user}}

      _ ->
        create_room(previous_user, user)
        {:reply, :ok, %{state | previous_user: nil}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {pidPrevious, _} = state.previous_user

    if pidPrevious == pid do
      {:noreply, %{state | previous_user: nil}}
    else
      {:noreply, state}
    end
  end

  defp create_room({pid, meta}, {pid2, meta2}) do
    room_id = "#{meta.id} - #{meta2.id}"
    send(pid, {:room_ready, room_id})
    send(pid2, {:room_ready, room_id})
    IO.inspect("Room created! #{meta.id} - #{meta2.id}")
  end
end
