defmodule Ui.SensorData do

  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  # Callback fn, setting the initial state with a 0 reading and the current system time.
  def init(state) do
    # use Erlang fn to get current system time as unix timestamp
    current_time = :os.system_time(:second)

    initial_temp_data = %{temp: 0, timestamp: current_time}

    # TODO: Implement as a queue, could use Erlang queue data structure.
    # TODO: How to manage data stored in memory, how long to retain data.
    initial_state = [initial_temp_data | state]

    {:ok, initial_state}
  end

  def add_data(temp) do
    GenServer.cast(__MODULE__, {:add_data, temp})
  end

  def read_data() do
    GenServer.call(__MODULE__, {:read_data})
  end

  @impl true
  def handle_cast({:add_data,  %BMP280.Measurement{temperature_c: temp}}, state) do
    current_time = :os.system_time(:second)
    temp_data = %{temp: temp, timestamp: current_time}
    # add temp data to head of list
    new_state = [temp_data | state]

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:read_data}, _, state) do
    {:reply, state, state}
  end
end
