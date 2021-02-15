defmodule Ui.SensorData do
  @doc """
  Genserver to manage the state of the sensor data. Currently storing in memory.

  Functionality to save temp data to a queue and read from queue.

  Retains the last 10 readings in memory.
  """

  use GenServer
  require Logger

  def start_link(state \\ %{}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    Logger.info("#{inspect(pid)} sensor data started #########")
    {:ok, pid}
  end

  @impl true
  # Callback fn, setting the initial state with a map that has a queue and a counter
  def init(_state) do
    # Setup queue data structure {[], []}
    queue = :queue.new
    # Count to keep track of length of queue.
    count = 0

    # %{queue: {[], []}}, count: 0}
    initial_state = %{queue: queue, count: count}

    {:ok, initial_state}
  end

  def add_data(temp) do
    GenServer.cast(__MODULE__, {:add_data, temp})
  end

  def read_data() do
    GenServer.call(__MODULE__, {:read_data})
  end

  # if count is greater than 10, queue out, then queue in.

  @impl true
  def handle_cast({:add_data,  %BMP280.Measurement{temperature_c: temp}}, %{queue: queue, count: count}) do
    current_time = :os.system_time(:second)
    temp_data = %{temp: temp, timestamp: current_time}

    new_count = handle_count(count)

    new_queue = handle_queue(queue, new_count, temp_data)

    new_state = %{queue: new_queue, count: new_count}

    # Send data to influxDB
    token = Application.get_env(:firmware, :influx_token)
    local_host_ip = Application.get_env(:firmware, :local_host_ip)
    influx_org = Application.get_env(:firmware, :influx_org)
    influx_bucket = Application.get_env(:firmware, :influx_bucket)

    url = "http://#{local_host_ip}:8086/api/v2/write?org=#{influx_org}&bucket=#{influx_bucket}&precision=s"

    headers = ["Authorization": "Token #{token}", "Content-Type": "raw"]
    # eg "temp,host=pi1 temp=35.43234543 1613217504"
    body = "temp,host=pi1 temp=#{temp_data.temp} #{temp_data.timestamp}"
    # TODO - Handle response
    HTTPoison.post(url, body, headers)

    # Broadcast new state
    Phoenix.PubSub.broadcast(Ui.PubSub, "sensor_reading", new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:read_data}, _, state) do
    {:reply, state, state}
  end

  defp handle_queue(queue, count, temp_data) when count > 10 do
    # remove tail item
    {{:value, _}, q} = :queue.out(queue)
    # return new queue with item added
    :queue.in(temp_data, q)
  end

  defp handle_queue(queue, _count, temp_data) do
    :queue.in(temp_data, queue)
  end

  defp handle_count(count) when count <= 15 do
    count + 1
  end

  defp handle_count(count) do
    count
  end
end
