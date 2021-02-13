defmodule UiWeb.PageLive do
  use UiWeb, :live_view
  alias Contex.{Sparkline}

  require Logger

  @impl true
  def mount(_params, _session, socket) do
     # When page mounts, subscribe to events broadcast to the below pubsub channel
    Phoenix.PubSub.subscribe(Ui.PubSub, "sensor_reading")

    {:ok, assign(socket, temp_data: [], test_data: [1, 2, 3])}
  end

  @impl true
  def handle_info(%{queue: {head, tail}}, socket) do
    data = List.flatten([head | tail])

    test_data = data |> Enum.map(fn d -> d.temp end) |> Enum.reverse()

    {:noreply, assign(socket, temp_data: data, test_data: test_data)}
  end

  def make_plot(data) do
    Sparkline.new(data)
    |> Sparkline.draw()
  end

  def make_red_plot(data) do
    Sparkline.new(data)
    |> Sparkline.colours("#fad48e", "#ff9838")
    |> Sparkline.draw()
  end
end
