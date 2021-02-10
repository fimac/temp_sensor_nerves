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
    {:ok, alert_port} = Circuits.GPIO.open(26, :output)
    # Kick off process to read every 5 seconds
    read_sensor()

    {:ok, %{sensor: sensor, alert_port: alert_port}}
  end

  @impl true
  def handle_info(:read, %{sensor: sensor, alert_port: alert_port} = state) do
    # TODO: handle if error returned.
    {:ok, %{temperature_c: temp_data} = temp} =  BMP280.read(sensor)
    # iex> BMP280.read(bmp)
    # {:ok,
    #  %BMP280.Measurement{
    #    altitude_m: 13.842046523689644,
    #    dew_point_c: 18.438691684856007,
    #    humidity_rh: 51.59938493850065,
    #    pressure_pa: 99836.02154563366,
    #    temperature_c: 29.444089211523533
    #  }}


    # # If alert port is off and over max temp, turn PORT ON
    if temp_data > 22.00 and Circuits.GPIO.read(alert_port) == 0, do: Circuits.GPIO.write(alert_port, 1)
    # # If alert port is on and under max temp, turn PORT OFF
    if temp_data < 22.00 and Circuits.GPIO.read(alert_port) == 1, do: Circuits.GPIO.write(alert_port, 0)

    # call sensor_data genserver cast to update sensor data state async
    SensorData.add_data(temp)

    # make call to read sensor again
    read_sensor()

    {:noreply, state}
  end

  defp read_sensor() do
    Process.send_after(self(), :read, 5000)
  end
end
