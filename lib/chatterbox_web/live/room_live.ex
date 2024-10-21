defmodule ChatterboxWeb.RoomLive do
  alias Chatterbox.Room
  use ChatterboxWeb, :live_view
  @max_chat_length 50

  def render(assigns) do
    ~H"""
    <div id="room-container" class="flex flex-col gap-2 h-full sm:flex-row" phx-hook="Webcam">
      <div class="flex flex-col gap-1 max-h-[50%] max-w-full w-fit sm:flex-1">
        <div class="bg-amber-800 max-h-[50%] sm:max-h-full rounded-lg">
          <video id="webcamVideo" class="w-full h-auto max-h-full" autoplay playsinline></video>
        </div>
        <div class="bg-amber-800 w-full max-h-[50%] sm:max-h-full rounded-lg">
          <video id="remoteVideo" class="w-full h-auto max-h-full" autoplay playsinline></video>
        </div>
      </div>
      <div
        class="flex-grow flex flex-col justify-end max-h-full overflow-auto max-w-sm"
        id="chat-container"
      >
        <ul class="flex flex-col-reverse gap-1 overflow-y-auto">
          <%= for message <- @messages do %>
            <li class={if message.sender_id == @user_id, do: ["self-end"]}>
              <div class={
                if(message.sender_id == @user_id,
                  do: ["bg-amber-950 text-white rounded-bl-2xl"],
                  else: ["bg-zinc-300 text-black rounded-br-2xl"]
                ) ++ ["rounded-t-2xl w-fit px-3 py-2  [overflow-wrap:anywhere] "]
              }>
                <%= message.content %>
              </div>
            </li>
          <% end %>
        </ul>
        <.form class="mt-5" phx-change="validate" for={@form} phx-submit="save" id="chat-form">
          <div class="flex justify-between w-full bg-zinc-100 max-h-12 py-3 px-4 rounded-md gap-3">
            <input
              maxlength={@max_chat_length}
              class="text-sm p-1 w-full bg-transparent border-transparent focus:border-transparent focus:ring-0 placeholder-stone-600 text-stone-900"
              type="text"
              name={@form[:message].name}
              value={@form[:message].value}
              phx-debounce="blur"
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
          Process.monitor(pid)

          socket
          |> assign(
            room_id: room_id,
            room_pid: pid,
            form: to_form(%{"message" => ""}),
            messages: [],
            candidate: nil,
            role: nil,
            user_id: nil,
            max_chat_length: @max_chat_length
          )

        _ ->
          socket |> push_navigate(to: ~p"/")
      end

    {:ok, socket}
  end

  def handle_event("save", %{"message" => message}, socket) do
    if String.length(message) == 0 or String.length(message) > @max_chat_length do
      {:noreply, socket}
    else
      Room.send_message(socket.assigns.room_pid, socket.assigns.user_id, message)
      {:noreply, socket |> assign(:form, to_form(%{"message" => nil}))}
    end
  end

  def handle_event("join", %{"user_id" => user_id}, socket) do
    case Room.join(socket.assigns.room_pid, user_id) do
      {:ok, role} ->
        socket =
          socket
          |> assign(user_id: user_id)
          |> assign(messages: Room.get_messages(socket.assigns.room_pid))
          |> assign(role: role)
          |> send_events(role)

        {:noreply, socket}

      _ ->
        {:noreply, socket |> push_navigate(to: ~p"/")}
    end
  end

  def handle_event("validate", params, socket) do
    form = to_form(params)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_event("offer_info", offer, socket) when socket.assigns.role == :requester do
    Room.set_offer(socket.assigns.room_pid, offer)
    {:noreply, socket}
  end

  def handle_event("answer_info", answer, socket) when socket.assigns.role == :responder do
    Room.set_answer(socket.assigns.room_pid, answer)
    {:noreply, socket}
  end

  def handle_event("candidate_info", candidate, socket) do
    Room.set_candidate(socket.assigns.room_pid, candidate)
    {:noreply, socket |> assign(candidate: candidate)}
  end

  def handle_info({:updated_messages, updated_messages}, socket) do
    {:noreply, socket |> assign(messages: updated_messages)}
  end

  def handle_info({:updated_offer, offer}, socket) do
    case socket.assigns.role do
      :responder -> {:noreply, socket |> push_event("set_offer", offer)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info({:updated_answer, answer}, socket) do
    case socket.assigns.role do
      :requester -> {:noreply, socket |> push_event("set_answer", answer)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info({:updated_candidate, candidate}, socket) do
    case socket.assigns.candidate do
      ^candidate -> {:noreply, socket}
      _ -> {:noreply, socket |> push_event("set_candidate", candidate)}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    if pid == socket.assigns.room_pid do
      {:noreply, socket |> push_navigate(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  defp send_events(socket, role) do
    case role do
      :requester ->
        socket |> push_event("create_offer", %{})

      :responder ->
        case Room.get_offer(socket.assigns.room_pid) do
          nil -> socket
          offer -> socket |> push_event("set_offer", offer)
        end
    end
  end
end
