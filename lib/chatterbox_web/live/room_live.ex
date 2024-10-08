defmodule ChatterboxWeb.RoomLive do
  alias Chatterbox.Room
  use ChatterboxWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full text-center" id="queue-container" phx-hook="Queue">
      This is one of the rooms of all time: <%= @room_id %>
    </div>
    <div class="max-w-sm">
      <ul class="flex flex-col-reverse gap-1">
        <%= for message <- @messages do %>
          <li class={if message.sender_id == @user_id, do: ["self-end"]}>
            <div class={
              if(message.sender_id == @user_id,
                do: ["bg-amber-950 text-white rounded-bl-2xl"],
                else: ["bg-zinc-300 text-black rounded-br-2xl"]
              ) ++ ["rounded-t-2xl w-fit px-3 py-2"]
            }>
              <%= message.content %>
            </div>
          </li>
        <% end %>
      </ul>
      <.form for={@form} phx-submit="save">
        <.input type="text" field={@form[:message]} />
        <button>Send</button>
      </.form>
    </div>
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
      {:ok, messages} -> {:noreply, socket |> assign(user_id: user_id, messages: messages)}
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
