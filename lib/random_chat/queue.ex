defmodule RandomChat.Queue do
  @moduledoc """
  This the queue module where it holds the a live view instance that does not have a pair yet.
  Once a new user joins the queue, a room will be craeted then they will be immediately paired with that user.
  """
  require OpenTelemetry.Tracer
  alias RandomChat.Room

  use GenServer

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def join(pid, user) do
    OpenTelemetry.Tracer.with_span "RandomChat.Queue.join" do
      OpenTelemetry.Tracer.set_attribute("user", user)
      span_ctx = OpenTelemetry.Tracer.start_span("RandomChat.Queue.handle_call#join")
      ctx = OpenTelemetry.Ctx.get_current()
      GenServer.call(__MODULE__, {:join, pid, user, span_ctx, ctx})
    end
  end

  # Server

  def init(_) do
    {:ok, %{queued_user: nil}}
  end

  def handle_call(
        {:join, pid, user_id, span_ctx, ctx},
        _,
        %{queued_user: queued_user} = state
      ) do
    OpenTelemetry.Ctx.attach(ctx)
    OpenTelemetry.Tracer.set_current_span(span_ctx)
    OpenTelemetry.Tracer.set_attributes(%{request: {:join, pid, user_id}, state: state})
    Process.monitor(pid)
    new_user = {pid, user_id}
    OpenTelemetry.Tracer.end_span(span_ctx)

    case queued_user do
      nil ->
        {:reply, :ok, %{state | queued_user: new_user}}

      {_, ^user_id} ->
        {:reply, {:error, :already_joined}, %{state | queued_user: new_user}}

      _ ->
        create_room(queued_user, new_user)
        {:reply, :ok, %{state | queued_user: nil}}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    with {queued_user_pid, _} <- state.queued_user,
         ^pid <- queued_user_pid do
      {:noreply, %{state | queued_user: nil}}
    else
      _ -> {:noreply, state}
    end
  end

  defp create_room({pid, user_id_1}, {pid2, user_id_2}) do
    room_id = UUID.uuid4()
    name = {:via, Registry, {RandomChat.RoomRegistry, room_id}}

    OpenTelemetry.Tracer.with_span "RandomChat.Queue.create_room" do
      OpenTelemetry.Tracer.set_attributes(%{
        "random_chat.room.id" => room_id,
        "user_id_1" => user_id_1,
        "user_id_2" => user_id_2
      })

      {:ok, _} =
        Room.start(%{user_roles: %{user_id_1 => :requester, user_id_2 => :responder}}, name: name)

      send(pid, {:room_ready, room_id})
      send(pid2, {:room_ready, room_id})
    end
  end
end
