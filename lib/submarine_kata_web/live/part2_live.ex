defmodule SubmarineKataWeb.Part2Live do
  use SubmarineKataWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Load the input data
    input_data = case File.read("files/input_data.txt") do
      {:ok, content} -> content
      {:error, _} -> ""
    end

    commands = String.split(input_data, "\n", trim: true)

    socket =
      socket
      |> assign(:current_step, :intro)
      |> assign(:commands, commands)
      |> assign(:current_position, %{horizontal: 0, depth: 0, aim: 0})
      |> assign(:position_history, [%{horizontal: 0, depth: 0, aim: 0}])
      |> assign(:command_index, 0)
      |> assign(:total_commands, length(commands))
      |> assign(:is_running, false)
      |> assign(:final_product, nil)
      |> assign(:execution_error, nil)
      |> assign(:statistics, %{
        forward_count: 0,
        down_count: 0,
        up_count: 0
      })

    {:ok, socket}
  end

  @impl true
  def handle_event("start_execution", _params, socket) do
    IO.puts("Start Execution button clicked!")

    if socket.assigns.is_running do
      IO.puts("Execution already running, ignoring click")
      {:noreply, socket}
    else
      # Initialize the execution
      socket =
        socket
        |> assign(:is_running, true)
        |> assign(:current_step, :executing)
        |> assign(:current_position, %{horizontal: 0, depth: 0, aim: 0})
        |> assign(:position_history, [%{horizontal: 0, depth: 0, aim: 0}])
        |> assign(:command_index, 0)
        |> assign(:execution_error, nil)
        |> assign(:final_product, nil)
        |> assign(:statistics, %{
          forward_count: 0,
          down_count: 0,
          up_count: 0
        })

      # Start the execution process
      send(self(), :next_command)
      IO.puts("Sent :next_command message")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    IO.puts("Reset button clicked!")

    socket =
      socket
      |> assign(:current_step, :intro)
      |> assign(:current_position, %{horizontal: 0, depth: 0, aim: 0})
      |> assign(:position_history, [%{horizontal: 0, depth: 0, aim: 0}])
      |> assign(:command_index, 0)
      |> assign(:is_running, false)
      |> assign(:execution_error, nil)
      |> assign(:final_product, nil)
      |> assign(:statistics, %{
        forward_count: 0,
        down_count: 0,
        up_count: 0
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info(:next_command, socket) do
    IO.puts("Received :next_command message, current command_index: #{socket.assigns.command_index}, is_running: #{socket.assigns.is_running}")

    # Only process if we're still running
    if not socket.assigns.is_running do
      IO.puts("Process stopped, ignoring :next_command message")
      {:noreply, socket}
    else
      command_index = socket.assigns.command_index
      commands = socket.assigns.commands

      if command_index >= length(commands) do
        # Execution complete
        IO.puts("Step: Complete")
        final_position = socket.assigns.current_position
        product = final_position.horizontal * final_position.depth

        # Calculate final statistics
        _stats = calculate_statistics(commands)

        socket =
          socket
          |> assign(:current_step, :complete)
          |> assign(:is_running, false)
          |> assign(:final_product, product)

        {:noreply, socket}
      else
        # Execute next command
        current_command = Enum.at(commands, command_index)
        IO.puts("Executing command #{command_index + 1}: #{current_command}")

        case execute_command(socket.assigns.current_position, current_command) do
          {:ok, new_position} ->
            # Update statistics
            stats = update_statistics(socket.assigns.statistics, current_command)

            socket =
              socket
              |> assign(:current_position, new_position)
              |> assign(:position_history, socket.assigns.position_history ++ [new_position])
              |> assign(:command_index, command_index + 1)
              |> assign(:statistics, stats)

            Process.send_after(self(), :next_command, 10)  # 10ms delay between commands
            {:noreply, socket}

          {:error, reason} ->
            socket =
              socket
              |> assign(:current_step, :error)
              |> assign(:is_running, false)
              |> assign(:execution_error, reason)

            {:noreply, socket}
        end
      end
    end
  end

  # Helper function to execute a single command using the actual SubmarineKata module
  defp execute_command(position, command_string) do
    case SubmarineKata.Command.parse(command_string) do
      {:ok, command} ->
        new_position = SubmarineKata.Command.execute(position, command)
        {:ok, new_position}
      {:error, reason} ->
        {:error, "Invalid command: #{reason}"}
    end
  end

  # Helper function to update statistics
  defp update_statistics(stats, command_string) do
    case String.split(command_string, " ", parts: 2) do
      [direction, _amount] ->
        case direction do
          "forward" ->
            %{stats | forward_count: stats.forward_count + 1}
          "down" ->
            %{stats | down_count: stats.down_count + 1}
          "up" ->
            %{stats | up_count: stats.up_count + 1}
          _ ->
            stats
        end
      _ ->
        stats
    end
  end

  # Helper function to calculate final statistics
  defp calculate_statistics(commands) do
    forward_count = commands |> Enum.count(&String.starts_with?(&1, "forward"))
    down_count = commands |> Enum.count(&String.starts_with?(&1, "down"))
    up_count = commands |> Enum.count(&String.starts_with?(&1, "up"))

    %{
      forward_count: forward_count,
      down_count: down_count,
      up_count: up_count
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Header -->
      <div class="bg-primary text-primary-content py-4">
        <div class="max-w-6xl mx-auto px-4">
          <h1 class="text-3xl font-bold">Part 2: Aim-based Navigation</h1>
          <p class="text-primary-content/80 mt-2">Execute submarine navigation commands and track position changes</p>
        </div>
      </div>

      <!-- Progress Steps -->
      <div class="max-w-6xl mx-auto px-4 py-6">
        <div class="steps w-full">
          <div class={["step", if(@current_step in [:executing, :complete, :error], do: "step-primary")]}>
            Ready
          </div>
          <div class={["step", if(@current_step in [:complete, :error], do: "step-primary")]}>
            Executing
          </div>
          <div class={["step", if(@current_step == :complete, do: "step-primary")]}>
            Complete
          </div>
        </div>
      </div>

      <!-- Content Area -->
      <div class="max-w-6xl mx-auto px-4">
        <!-- Control Panel -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Control Panel</h2>

            <div class="flex gap-4 items-center">
              <button
                phx-click="start_execution"
                disabled={@is_running}
                class={["btn btn-primary", if(@is_running, do: "loading")]}
              >
                {if @is_running, do: "Running...", else: "Start Execution"}
              </button>

              <button
                phx-click="reset"
                disabled={@is_running}
                class="btn btn-outline"
              >
                Reset
              </button>
            </div>

            <div class="stats stats-horizontal shadow-sm bg-base-200 mt-4">
              <div class="stat">
                <div class="stat-title">Total Commands</div>
                <div class="stat-value text-black">{@total_commands}</div>
                <div class="stat-desc">Navigation commands to execute</div>
              </div>
              <div class="stat">
                <div class="stat-title">Current Command</div>
                <div class="stat-value text-black">{@command_index + 1}</div>
                <div class="stat-desc">Progress through commands</div>
              </div>
              <div class="stat">
                <div class="stat-title">Status</div>
                <div class="stat-value text-black text-sm">
                  {case @current_step do
                    :intro -> "Ready"
                    :executing -> "Running"
                    :complete -> "Complete"
                    :error -> "Error"
                  end}
                </div>
                <div class="stat-desc">Execution status</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Current Position -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Current Position</h2>

            <div class="stats stats-horizontal shadow-sm bg-base-200">
              <div class="stat">
                <div class="stat-title">Horizontal</div>
                <div class="stat-value text-black">{@current_position.horizontal}</div>
                <div class="stat-desc">Forward distance</div>
              </div>
              <div class="stat">
                <div class="stat-title">Depth</div>
                <div class="stat-value text-black">{@current_position.aim}</div>
                <div class="stat-desc">Aim value</div>
              </div>
              <%= if @final_product do %>
                <div class="stat">
                  <div class="stat-title">Product</div>
                  <div class="stat-value text-black"><%= @final_product %></div>
                  <div class="stat-desc">Horizontal × Depth</div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Current Command Display -->
        <%= if @current_step in [:executing, :complete] and @command_index < @total_commands do %>
          <div class="card bg-base-100 shadow-xl mb-6">
            <div class="card-body">
              <h2 class="card-title">Current Command</h2>
              <div class="text-2xl font-mono bg-base-200 p-4 rounded">
                <%= Enum.at(@commands, @command_index) %>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Statistics -->
        <%= if @current_step in [:executing, :complete] do %>
          <div class="card bg-base-100 shadow-xl mb-6">
            <div class="card-body">
              <h2 class="card-title">Command Statistics</h2>

              <div class="stats stats-horizontal shadow-sm bg-base-200">
                <div class="stat">
                  <div class="stat-title">Forward</div>
                  <div class="stat-value text-black"><%= @statistics.forward_count %></div>
                  <div class="stat-desc">Forward commands</div>
                </div>
                <div class="stat">
                  <div class="stat-title">Down</div>
                  <div class="stat-value text-black"><%= @statistics.down_count %></div>
                  <div class="stat-desc">Down commands</div>
                </div>
                <div class="stat">
                  <div class="stat-title">Up</div>
                  <div class="stat-value text-black"><%= @statistics.up_count %></div>
                  <div class="stat-desc">Up commands</div>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Error Display -->
        <%= if @execution_error do %>
          <div class="alert alert-error">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <span>Execution Error: <%= @execution_error %></span>
          </div>
        <% end %>

        <!-- Success Message -->
        <%= if @current_step == :complete do %>
          <div class="alert alert-success">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <span>Execution Complete! Final product: <%= @final_product %></span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
