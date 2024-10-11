defmodule ChatterboxWeb.RoomLive do
  alias Chatterbox.Room
  use ChatterboxWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 h-full sm:flex-row">
      <div
        id="videos-container"
        class="flex flex-col gap-1 max-h-full max-w-full w-full h-full sm:flex-1"
      >
        <div class="bg-amber-800 w-full h-full rounded-lg">&nbsp</div>
        <div class="bg-amber-800 w-full h-full rounded-lg">&nbsp</div>
      </div>
      <div
        class="flex-grow flex flex-col justify-end max-h-full overflow-auto max-w-sm"
        id="chat-container"
        phx-hook="Queue"
      >
        <ul class="flex flex-col-reverse gap-1 overflow-y-auto">
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
        <.form class="mt-5" phx-change="validate" for={@form} phx-submit="save" id="chat-form">
          <div class="flex justify-between w-full bg-zinc-100 max-h-12 py-3 px-4 rounded-md gap-3">
            <input
              class="text-sm p-1 w-full bg-transparent border-transparent focus:border-transparent focus:ring-0 placeholder-stone-600 text-stone-900"
              type="text"
              name={@form[:message].name}
              value={@form[:message].value}
              placeholder="Type a message"
            />
            <button>
              <svg
                width="19"
                height="16"
                viewBox="0 0 19 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M0.674349 15.5L18.166 8L0.674349 0.5L0.666016 6.33333L13.166 8L0.666016 9.66667L0.674349 15.5Z"
                  fill="#D0D0D0"
                />
              </svg>
            </button>
          </div>
        </.form>
      </div>
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
            form: to_form(%{"message" => ""}),
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
    if String.length(message) == 0 do
      {:noreply, socket}
    else
      Room.send_message(socket.assigns.room_pid, self(), message)
      {:noreply, socket |> assign(:form, to_form(%{"message" => nil}))}
    end
  end

  def handle_event("validate", params, socket) do
    form = to_form(params)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_info({:updated_messages, updated_messages}, socket) do
    {:noreply, socket |> assign(messages: updated_messages)}
  end
end
