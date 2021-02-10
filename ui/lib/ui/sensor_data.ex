defmodule Ui.SensorData do
  @doc """
  Genserver to manage the state of the sensor data. Currently storing in memory.

  Functionality to save temp data to a queue and read from queue.

  TODO: Implement some sort of retention policy.
  """

  use GenServer
  require Logger

  def start_link(state \\ %{}) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    Logger.info("#{inspect(pid)} sensor data started #########")
    {:ok, pid}
  end

  @impl true
  # Callback fn, setting the initial state with a 0 reading and the current system time.
  def init(_state) do
    # Setup queue data structure {[], []}
    queue = :queue.new
    # TODO: Counter to keep length of queue. When counter get's to x remove oldest item from queue.
    # :queue.out(queue)
    # count = 0

    # %{queue: {[], []}}, count: 0}
    initial_state = %{queue: queue}

    {:ok, initial_state}
  end

  def add_data(temp) do
    GenServer.cast(__MODULE__, {:add_data, temp})
  end

  def read_data() do
    GenServer.call(__MODULE__, {:read_data})
  end

  @impl true
  def handle_cast({:add_data,  %BMP280.Measurement{temperature_c: temp}}, %{queue: queue}) do
    current_time = :os.system_time(:second)
    temp_data = %{temp: temp, timestamp: current_time}
    new_queue = :queue.in(temp_data, queue)

    new_state = %{queue: new_queue}

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:read_data}, _, state) do
    {:reply, state, state}
  end
end
