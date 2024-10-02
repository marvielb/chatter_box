defmodule ChatterboxWeb.QueueLive do
  use ChatterboxWeb, :live_view

  alias Chatterbox.{Queue, User}

  def render(assigns) do
    ~H"""
    <div class="w-full text-center">
      <h1>Already in queue, waiting for a match... <%= @length %></h1>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      ChatterboxWeb.LiveMonitor.monitor(self(), __MODULE__, %{id: socket.id})
      Queue.add_user(%User{id: socket.id})
      {:ok, assign(socket, length: Queue.length())}
    else
      {:ok, assign(socket, length: 0)}
    end
  end

  def unmount(%{id: id}, _reason) do
    Queue.remove_user(id)
    :ok
  end
end
