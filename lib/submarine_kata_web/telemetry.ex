defmodule SubmarineKataWeb.Telemetry do
  @moduledoc """
  Telemetry supervisor for handling events during the LiveView lifecycle.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router.dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router.dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router.dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket.connected.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel.join.duration",
        tags: [:socket],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel.handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Database Time Metrics
      summary("submarine_kata.repo.query.total_time", unit: {:native, :millisecond}),
      summary("submarine_kata.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("submarine_kata.repo.query.query_time", unit: {:native, :millisecond}),
      summary("submarine_kata.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("submarine_kata.repo.query.idle_time", unit: {:native, :millisecond})
    ]
  end

  # Removed periodic_measurements as it's not needed for this application
end
