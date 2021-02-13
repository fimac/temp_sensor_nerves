defmodule UiWeb.PageLive do
  use UiWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
     # When page mounts, subscribe to events broadcast to the below pubsub channel
    Phoenix.PubSub.subscribe(Ui.PubSub, "sensor_reading")

    {:ok, assign(socket, temp_data: [])}
  end

  @impl true
  def handle_info(%{queue: {head, tail}}, socket) do
    data = List.flatten([head | tail])
    {:noreply, assign(socket, temp_data: data)}
  end
end
