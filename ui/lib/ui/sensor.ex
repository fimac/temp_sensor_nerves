defmodule Ui.Sensor do
  alias Ui.SensorData

  use GenServer
  require Logger


  # Start genserver
  def start_link(_state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    Logger.info("#{inspect(pid)} sensor server started ########")
    {:ok, pid}
  end

  # Indicates this is a callback
  @impl true
  # callback fn, set state with sensor pid, and kick off sensor read intervals
  def init(_state) do
    # Start sensor process
    {:ok, sensor} = BMP280.start_link(bus_name: "i2c-1", bus_address: 0x77)
    # Open port 18 on pi.
    {:ok, alert_port} = Circuits.GPIO.open(18, :output)
    # Kick off process to read every 5 seconds
    read_sensor_process()

    {:ok, %{sensor: sensor, alert_port: alert_port}}
  end

  @impl true
  def handle_info(:read, %{sensor: sensor, alert_port: alert_port} = state) do
    read_sensor(sensor, alert_port)
    # make call to start sensor read process again.
    read_sensor_process()

    {:noreply, state}
  end

  defp read_sensor_process() do
    Process.send_after(self(), :read, 5000)
  end

  defp read_sensor(sensor, alert_port) do
    sensor
    |> BMP280.read()
    |> handle_sensor_read(sensor, alert_port)
  end

  # If error reading sensor, log error message and try again.
  defp handle_sensor_read({:error, message}, sensor, alert_port) do
    Logger.error("#{inspect(message)} - error reading sensor.... trying again..")
    read_sensor(sensor, alert_port)
  end

  defp handle_sensor_read({:ok, %{temperature_c: temp_data} = temp}, _, alert_port) when temp_data > 23.00 do
     Logger.info("#{temp_data} ---- temp data > 23.00")
     Circuits.GPIO.write(alert_port, 0)
     # TODO: Update to publish message using phoenix pubsub.
     SensorData.add_data(temp)
  end

  defp handle_sensor_read({:ok, %{temperature_c: temp_data} = temp}, _, alert_port) when temp_data < 23.00 do
     Logger.info("#{temp_data} ---- temp data < 23.00")
     Circuits.GPIO.write(alert_port, 1)
     # TODO: Update to publish message using phoenix pubsub.
     SensorData.add_data(temp)
  end
end
