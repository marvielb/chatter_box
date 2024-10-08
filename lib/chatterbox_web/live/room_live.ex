defmodule ChatterboxWeb.RoomLive do
  alias Chatterbox.Room
  use ChatterboxWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full text-center" id="queue-container" phx-hook="Queue">
      This is one of the rooms of all time: <%= @room_id %>
    </div>
    <ul class="flex flex-col-reverse">
      <%= for message <- @messages do %>
        <li><b><%= message.sender_id %>:</b> <%= message.content %></li>
      <% end %>
    </ul>
    <.form for={@form} phx-submit="save">
      <.input type="text" field={@form[:message]} />
      <button>Send</button>
    </.form>
    """
  end

  def mount(%{"room_id" => room_id}, _session, socket) do
    socket =
      case Registry.lookup(Chatterbox.RoomRegistry, room_id) do
        [{pid, nil}] ->
          socket
          |> assign(
            room_id: room_id,
            room_pid: pid,
            form: to_form(%{"form" => %{"message" => ""}}),
            messages: []
          )

        _ ->
          socket |> push_navigate(to: ~p"/")
      end

    {:ok, socket}
  end

  def handle_event("join", %{"user_id" => user_id}, socket) do
    case Room.join(socket.assigns.room_pid, user_id) do
      :ok -> {:noreply, socket |> assign(joined: true)}
      _ -> {:noreply, socket |> push_navigate(to: ~p"/")}
    end
  end

  def handle_event("save", %{"message" => message}, socket) do
    Room.send_message(socket.assigns.room_pid, self(), message)
    {:noreply, socket |> assign(form: to_form(%{"form" => %{"message" => ""}}))}
  end

  def handle_info({:updated_messages, updated_messages}, socket) do
    {:noreply, socket |> assign(messages: updated_messages)}
  end
end
