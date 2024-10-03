defmodule ChatterboxWeb.QueueLive do
  use ChatterboxWeb, :live_view

  alias Chatterbox.Queue

  def render(assigns) do
    ~H"""
    <div class="w-full text-center">
      <h1>Already in queue, waiting for a match... <%= @room_id %></h1>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Queue.monitor(self(), %{id: socket.id})
    end

    {:ok, assign(socket, room_id: "hehe")}
  end

  def handle_info({:room_ready, room_id}, socket) do
    {:noreply, assign(socket, room_id: room_id)}
  end
end
