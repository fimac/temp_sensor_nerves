defmodule UiWeb.PageLive do
  use UiWeb, :live_view

  alias Ui.SensorData

  # Initial implementation, start read process on page load

  # @impl true
  # def mount(_params, _session, socket) do
  #   if connected?(socket), do: Process.send_after(self(), :tick, 3000)
  #   {:ok, sensor} = BMP280.start_link(bus_name: "i2c-1", bus_address: 0x77)
  #   {:ok, assign(socket, sensor: sensor, temp: %{}, time: :calendar.local_time())}
  # end


  # @impl true
  # def handle_info(:tick, %{assigns: %{sensor: sensor}} = socket) do
  #   Process.send_after(self(), :tick, 3000)
  #    {:ok, temp} =  BMP280.read(sensor)
  #    {:noreply, assign(socket, temp: temp, time: :calendar.local_time())}
  # end

  # Refactor to use Genservers to run temp read and manage temperature data

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, 8000)
    # TODO: Handle if error returned
    temp_data = SensorData.read_data()
    {:ok, assign(socket, temp_data: temp_data)}
  end


  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, 8000)
    # TODO: Handle error
    temp_data = SensorData.read_data()

    {:noreply, assign(socket, temp_data: temp_data)}
  end
end
