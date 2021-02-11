defmodule Ui.Sensor do
  alias Ui.SensorData

  use GenServer
  require Logger

  # TODO: Move out to separate module

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
    # Open port 26 on pi.
    {:ok, alert_port} = Circuits.GPIO.open(18, :output)
    # Kick off process to read every 5 seconds
    read_sensor()

    {:ok, %{sensor: sensor, alert_port: alert_port}}
  end

  @impl true
  def handle_info(:read, %{sensor: sensor, alert_port: alert_port} = state) do
    # TODO: handle if error returned. {:error, :i2c_nak}
    {:ok, %{temperature_c: temp_data} = temp} =  BMP280.read(sensor)


    # # When max temp is reached, turn PORT OFF
    if temp_data > 21.00 do
      Logger.info("#{temp_data} ---- temp data > 21.00")
      Circuits.GPIO.write(alert_port, 0)
    end
    # # When under max temp, turn PORT ON
    if temp_data < 21.00 do
      Logger.info("#{temp_data} ---- temp data < 21.00")
      Circuits.GPIO.write(alert_port, 1)
    end

    # call sensor_data genserver cast to update sensor data state async
    SensorData.add_data(temp)
    # TODO: Update to publish message using phoenix pubsub.

    # make call to read sensor again
    read_sensor()

    {:noreply, state}
  end

  defp read_sensor() do
    Process.send_after(self(), :read, 5000)
  end
end
