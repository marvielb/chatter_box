defmodule ChatterboxWeb.QueueLive do
  use ChatterboxWeb, :live_view

  alias Chatterbox.Queue
  alias Chatterbox.User

  def render(assigns) do
    ~H"""
    <div class="w-full text-center" id="queue-container" phx-hook="Queue">
      <%= if @already_joined do %>
        <h1>You are already in a queue. Please use the initial tab instead of this one.</h1>
      <% else %>
        <h1>Already in queue, waiting for a match... <%= @room_id %></h1>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, room_id: "", already_joined: false)}
  end

  def handle_event("join", %{"user_id" => user_id}, socket) do
    case Queue.join(self(), %User{id: user_id}) do
      :ok -> {:noreply, socket}
      {:error, :already_joined} -> {:noreply, assign(socket, already_joined: true)}
    end
  end

  def handle_info({:room_ready, room_id}, socket) do
    {:noreply, assign(socket, room_id: room_id)}
  end
end
