defmodule Chatterbox.UserTracker do
  use GenServer

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_user(user), do: GenServer.cast(__MODULE__, {:add_user, user})

  def get_pair(), do: GenServer.call(__MODULE__, :get_pair)

  def length(), do: GenServer.call(__MODULE__, :length)

  # Server Callbacks

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:add_user, %Chatterbox.User{} = user}, users) do
    {:noreply, [user | users]}
  end

  @impl true
  def handle_call(:get_pair, _from, users) do
    case get_pair(users) do
      {:ok, {rest, first_two}} ->
        {:reply, first_two, rest}

      :error ->
        {:reply, [], users}
    end
  end

  @impl true
  def handle_call(:length, _from, users) do
    {:reply, length(users), users}
  end

  defp get_pair(users) when length(users) > 1 do
    {:ok, Enum.split(users, -2)}
  end

  defp get_pair(_users) do
    :error
  end
end
