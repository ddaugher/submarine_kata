defmodule SubmarineKataWeb.SubmarineKataLive do
  use SubmarineKataWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_step, :intro)
      |> assign(:navigation_data, [])
      |> assign(:map_data, %{})
      |> assign(:is_running, false)
      |> assign(:step_index, 0)
      |> assign(:scanner_data, load_scanner_data())
      |> assign(:navigation_commands, load_navigation_commands())
      |> assign(:reconstructed_map, load_reconstructed_map())
      |> assign(:current_position, nil)
      |> assign(:current_map, %{})
      |> assign(:command_index, 0)
      |> assign(:total_commands, 0)
      |> assign(:execution_error, nil)
      |> assign(:loading_progress, 0)
      |> assign(:loaded_coordinates, [])
      |> assign(:loading_substep, 0)

    {:ok, socket}
  end

  defp load_scanner_data do
    case SubmarineKata.Scanner.load_scanner_data("files/scanner_data.json") do
      {:ok, data} -> data
      {:error, _} -> %{}
    end
  end

  defp load_navigation_commands do
    case File.read("files/input_data.txt") do
      {:ok, content} ->
        content |> String.split("\n", trim: true)
      {:error, _} ->
        ["down 1", "forward 19", "up 1", "forward 9"]
    end
  end

  defp load_reconstructed_map do
    case File.read("files/reconstructed_map.txt") do
      {:ok, content} ->
        content |> String.split("\n")
      {:error, _} ->
        ["Map reconstruction failed", "Please check input files"]
    end
  end

  @impl true
  def handle_event("start_visualization", _params, socket) do
    IO.puts("🚀 Start Visualization button clicked!")

    # Prevent multiple simultaneous runs
    if socket.assigns.is_running do
      IO.puts("⚠️ Visualization already running, ignoring click")
      {:noreply, socket}
    else
      # Initialize the algorithm execution
      socket =
        socket
        |> assign(:is_running, true)
        |> assign(:current_step, :loading_data)
        |> assign(:step_index, 0)  # Reset step index to 0
        |> assign(:current_position, SubmarineKata.Submarine.new())
        |> assign(:current_map, %{})
        |> assign(:command_index, 0)
        |> assign(:total_commands, length(socket.assigns.navigation_commands))
        |> assign(:execution_error, nil)
        |> assign(:loading_progress, 0)
        |> assign(:loaded_coordinates, [])
        |> assign(:loading_substep, 0)

      # Start the visualization process
      send(self(), :next_step)
      IO.puts("📤 Sent :next_step message")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    IO.puts("🔄 Reset button clicked!")

    socket =
      socket
      |> assign(:current_step, :intro)
      |> assign(:navigation_data, [])
      |> assign(:map_data, %{})
      |> assign(:is_running, false)
      |> assign(:step_index, 0)
      |> assign(:current_position, nil)
      |> assign(:current_map, %{})
      |> assign(:command_index, 0)
      |> assign(:execution_error, nil)
      |> assign(:loading_progress, 0)
      |> assign(:loaded_coordinates, [])
      |> assign(:loading_substep, 0)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:next_step, socket) do
    IO.puts("📥 Received :next_step message, current step_index: #{socket.assigns.step_index}, is_running: #{socket.assigns.is_running}")

    # Only process if we're still running
    if not socket.assigns.is_running do
      IO.puts("⚠️ Process stopped, ignoring :next_step message")
      {:noreply, socket}
    else
      case socket.assigns.step_index do
        0 ->
          IO.puts("🔄 Step 0: Loading data (substep #{socket.assigns.loading_substep})")
          # Progressive loading of scanner data
          case socket.assigns.loading_substep do
            0 ->
              # Start loading - initialize progress
              socket =
                socket
                |> assign(:loading_progress, 0)
                |> assign(:loaded_coordinates, [])
                |> assign(:loading_substep, 1)

              Process.send_after(self(), :next_step, 300)
              {:noreply, socket}

            1 ->
              # Load first batch of coordinates
              all_coords = Map.keys(socket.assigns.scanner_data)
              batch_size = max(1, div(length(all_coords), 8))  # Load in 8 batches
              current_loaded = socket.assigns.loaded_coordinates
              new_coords = Enum.take(all_coords, length(current_loaded) + batch_size)
              progress = min(100, trunc(length(new_coords) / length(all_coords) * 100))

              socket =
                socket
                |> assign(:loaded_coordinates, new_coords)
                |> assign(:loading_progress, progress)
                |> assign(:loading_substep, if(length(new_coords) >= length(all_coords), do: 2, else: 1))

              Process.send_after(self(), :next_step, 300)
              {:noreply, socket}

            2 ->
              # Loading complete - move to next step
              socket =
                socket
                |> assign(:current_step, :loading_data)
                |> assign(:step_index, 1)
                |> assign(:loading_progress, 100)

              Process.send_after(self(), :next_step, 500)
              {:noreply, socket}
          end

        1 ->
          IO.puts("🔄 Step 1: Scanning initial position")
          # Scan at initial position (0, 0)
          {position, map} = scan_at_position(socket.assigns.current_position, socket.assigns.current_map, socket.assigns.scanner_data)

          socket =
            socket
            |> assign(:current_step, :navigating)
            |> assign(:step_index, 2)
            |> assign(:current_position, position)
            |> assign(:current_map, map)

          Process.send_after(self(), :next_step, 50)
          {:noreply, socket}

        2 ->
          IO.puts("🔄 Step 2: Executing navigation command #{socket.assigns.command_index + 1}")
          # Execute next navigation command
          case execute_next_command(socket) do
            {:ok, new_socket} ->
              Process.send_after(self(), :next_step, 10)
              {:noreply, new_socket}
            {:complete, final_socket} ->
              # Algorithm is complete, no need to send next_step
              {:noreply, final_socket}
            {:error, error_socket} ->
              {:noreply, error_socket}
          end

        3 ->
          IO.puts("🔄 Step 3: Complete")
          # Algorithm complete
          socket =
            socket
            |> assign(:current_step, :complete)
            |> assign(:step_index, 4)
            |> assign(:is_running, false)

          {:noreply, socket}

        _ ->
          # Final state - do nothing
          {:noreply, socket}
      end
    end
  end

  # Helper function to execute the next navigation command
  defp execute_next_command(socket) do
    command_index = socket.assigns.command_index
    total_commands = socket.assigns.total_commands
    commands = socket.assigns.navigation_commands

    if command_index >= total_commands do
      # All commands executed, move directly to complete
      final_socket = socket
      |> assign(:step_index, 4)
      |> assign(:current_step, :complete)
      |> assign(:is_running, false)

      {:complete, final_socket}
    else
      # Execute next command
      command_string = Enum.at(commands, command_index)

      case SubmarineKata.Command.parse(command_string) do
        {:ok, command} ->
          # Execute the command
          new_position = SubmarineKata.Command.execute(socket.assigns.current_position, command)

          # Scan at new position
          {final_position, updated_map} = scan_at_position(new_position, socket.assigns.current_map, socket.assigns.scanner_data)

          new_socket = socket
          |> assign(:command_index, command_index + 1)
          |> assign(:current_position, final_position)
          |> assign(:current_map, updated_map)

          {:ok, new_socket}

        {:error, reason} ->
          error_socket = socket
          |> assign(:execution_error, "Failed to parse command '#{command_string}': #{inspect(reason)}")
          |> assign(:is_running, false)

          {:error, error_socket}
      end
    end
  end

  # Helper function to scan at a position (same as Part 3 algorithm)
  defp scan_at_position(position, current_map, scanner_data) do
    x = position.horizontal
    y = position.depth
    updated_map = SubmarineKata.Scanner.add_scan_to_map(current_map, scanner_data, x, y)
    {position, updated_map}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <!-- Controls -->
      <div class="flex gap-4 justify-center">
        <button
          phx-click="start_visualization"
          disabled={@is_running}
          class={[
            "btn btn-primary btn-lg",
            if(@is_running, do: "btn-disabled", else: "")
          ]}
        >
          {if @is_running, do: "Running...", else: "🚀 Start Visualization"}
        </button>

        <button
          phx-click="reset"
          class="btn btn-outline btn-lg"
        >
          🔄 Reset
        </button>
      </div>

      <!-- Progress Steps -->
      <div class="steps steps-horizontal w-full">
        <div class={[
          "step",
          if(@step_index >= 1, do: "step-primary", else: "")
        ]}>
          Load Scanner Data
        </div>
        <div class={[
          "step",
          if(@step_index >= 2, do: "step-primary", else: "")
        ]}>
          Navigate Submarine
        </div>
        <div class={[
          "step",
          if(@step_index >= 3, do: "step-primary", else: "")
        ]}>
          Reconstruct Map
        </div>
        <div class={[
          "step",
          if(@step_index >= 4, do: "step-primary", else: "")
        ]}>
          Complete
        </div>
      </div>

          <!-- Content Area -->
          <div class="max-w-6xl mx-auto">
            <!-- Persistent Scanner Data Information -->
            <%= if @step_index >= 0 do %>
              <div class="card bg-base-100 shadow-xl mb-6">
                <div class="card-body">
                  <h2 class="card-title">📊 Scanner Data Information</h2>

                  <!-- Loading Status -->
                  <%= if @current_step == :loading_data do %>
                    <div class="alert bg-gray-50 border-gray-200 text-gray-700 mb-4">
                      <span class="loading loading-spinner loading-sm text-gray-600"></span>
                      <span>Loading scanner data from input files...</span>
                    </div>
                  <% end %>

                  <!-- Loading Progress Animation - Always Visible -->
                  <div class="w-full bg-gray-50 p-4 rounded-lg border border-gray-200 mb-4">
                    <div class="flex justify-between text-sm mb-2">
                      <span class="text-gray-700">Data Loading Progress</span>
                      <span class="text-gray-600">
                        <%= if @loading_progress < 100 do %>
                          Loading coordinates... <%= @loading_progress %>%
                        <% else %>
                          <%= length(@loaded_coordinates) %> coordinates loaded
                        <% end %>
                      </span>
                    </div>
                    <progress class="progress w-full" value={@loading_progress} max="100"></progress>
                    <div class="flex justify-between text-xs text-gray-500 mt-1">
                      <span><%= length(@loaded_coordinates) %> of <%= map_size(@scanner_data) %> coordinates loaded</span>
                      <span>
                        <%= cond do %>
                          <% @loading_progress < 100 and @current_step == :loading_data -> %>
                            Parsing scanner data...
                          <% @current_step == :loading_data -> %>
                            Ready to navigate
                          <% @current_step == :navigating -> %>
                            Navigation in progress
                          <% @current_step == :reconstructing -> %>
                            Map reconstruction in progress
                          <% true -> %>
                            Mission complete
                        <% end %>
                      </span>
                    </div>
                  </div>

                  <!-- Detailed Scanner Information -->
                  <div class="space-y-4">

                    <div class="stats stats-horizontal shadow-sm bg-white border border-gray-200">
                      <div class="stat bg-gray-50 rounded-lg">
                        <div class="stat-title text-gray-600">Scanner Coordinates</div>
                        <div class={["stat-value text-gray-800", if(@current_step == :loading_data and @loading_progress < 100, do: "animate-pulse")]}>
                          <%= if @current_step == :loading_data and @loading_progress < 100 do %>
                            <%= length(@loaded_coordinates) %> / <%= map_size(@scanner_data) %>
                          <% else %>
                            <%= map_size(@scanner_data) %>
                          <% end %>
                        </div>
                        <div class="stat-desc text-gray-500">
                          <%= if @current_step == :loading_data and @loading_progress < 100 do %>
                            Loading...
                          <% else %>
                            Available scan points
                          <% end %>
                        </div>
                      </div>
                      <div class="stat bg-gray-50 rounded-lg">
                        <div class="stat-title text-gray-600">Navigation Commands</div>
                        <div class={["stat-value text-gray-800", if(@current_step == :loading_data and @loading_progress < 100, do: "animate-pulse")]}><%= length(@navigation_commands) %></div>
                        <div class="stat-desc text-gray-500">Commands to execute</div>
                      </div>
                      <div class="stat bg-gray-50 rounded-lg">
                        <div class="stat-title text-gray-600">Data Size</div>
                        <div class={["stat-value text-gray-800", if(@current_step == :loading_data and @loading_progress < 100, do: "animate-pulse")]}>
                          <%= if @current_step == :loading_data and @loading_progress < 100 do %>
                            <%= trunc(byte_size(Jason.encode!(Map.take(@scanner_data, @loaded_coordinates))) / 1024) %>KB
                          <% else %>
                            <%= trunc(byte_size(Jason.encode!(@scanner_data)) / 1024) %>KB
                          <% end %>
                        </div>
                        <div class="stat-desc text-gray-500">
                          <%= if @current_step == :loading_data and @loading_progress < 100 do %>
                            Partial data loaded
                          <% else %>
                            Scanner data loaded
                          <% end %>
                        </div>
                      </div>
                    </div>

                    <div class="text-sm text-gray-600">
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="bg-blue-50 p-3 rounded">
                          <h4 class="font-bold text-sm mb-2">📊 Scanner Data Summary</h4>
                          <ul class="text-xs space-y-1">
                            <li>• Total coordinates: <%= map_size(@scanner_data) %></li>
                            <li>• Data format: 3x3 grid per coordinate</li>
                            <li>• Coverage area: Dynamic based on navigation</li>
                            <li>• Scan resolution: High precision</li>
                          </ul>
                        </div>

                        <div class="bg-green-50 p-3 rounded">
                          <h4 class="font-bold text-sm mb-2">🧭 Navigation Summary</h4>
                          <ul class="text-xs space-y-1">
                            <li>• Total commands: <%= length(@navigation_commands) %></li>
                            <li>• Command types: forward, down, up</li>
                            <li>• Starting position: (0, 0)</li>
                            <li>• Expected duration: ~<%= trunc(length(@navigation_commands) * 10 / 1000) %> seconds</li>
                          </ul>
                        </div>
                      </div>
                    </div>

                    <div class="mt-4">
                      <div class="bg-gray-100 p-3 rounded max-h-48 overflow-y-auto">
                        <h4 class="font-bold text-sm mb-2">🔍 Scanner Data Sample:</h4>
                        <pre class="text-xs"><%=
                          if @current_step == :loading_data and @loading_progress < 100 do
                            # Show progressively loaded coordinates
                            @loaded_coordinates
                            |> Enum.take(5)
                            |> Enum.map(fn coord ->
                              data = Map.get(@scanner_data, coord)
                              "#{coord}: #{inspect(data)}"
                            end)
                            |> Enum.join("\n")
                          else
                            # Show first 5 coordinates when complete
                            @scanner_data
                            |> Enum.take(5)
                            |> Enum.map(fn {coord, data} -> "#{coord}: #{inspect(data)}" end)
                            |> Enum.join("\n")
                          end
                        %></pre>
                        <div class="text-xs text-gray-500 mt-2">
                          <%= if @current_step == :loading_data and @loading_progress < 100 do %>
                            Showing <%= min(5, length(@loaded_coordinates)) %> of <%= length(@loaded_coordinates) %> loaded coordinates...
                          <% else %>
                            Showing 5 of <%= map_size(@scanner_data) %> total coordinates...
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <!-- Process Information -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">Process Information</h2>

                <div class="space-y-4">
              <%= case @current_step do %>
                <% :intro -> %>
                  <div class="alert bg-slate-50 border-slate-200 text-slate-700">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6 text-slate-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    <span>Ready to start the submarine navigation visualization!</span>
                  </div>

                <% :loading_data -> %>
                  <div class="alert bg-gray-50 border-gray-200 text-gray-700">
                    <span class="loading loading-spinner loading-sm text-gray-600"></span>
                    <span>Data loading in progress... Check scanner information above for details.</span>
                  </div>

                <% :navigating -> %>
                  <div class="alert bg-gray-50 border-gray-200 text-gray-700">
                    <span class="loading loading-spinner loading-sm text-gray-600"></span>
                    <span>🚢 Submarine is navigating through the ocean...</span>
                  </div>

                  <!-- Enhanced Visual Navigation -->
                  <div class="space-y-6">
                    <!-- Progress Bar -->
                    <div class="w-full bg-gray-50 p-4 rounded-lg border border-gray-200">
                      <div class="flex justify-between text-sm mb-2">
                        <span class="text-gray-700">Navigation Progress</span>
                        <span class="text-gray-600"><%= trunc(@command_index / @total_commands * 100) %>% Complete</span>
                      </div>
                      <progress class="progress w-full" value={@command_index} max={@total_commands}></progress>
                      <div class="flex justify-between text-xs text-gray-500 mt-1">
                        <span>Command <%= @command_index %> of <%= @total_commands %></span>
                        <span><%= @total_commands - @command_index %> remaining</span>
                      </div>
                    </div>

                    <!-- Visual Submarine Position -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Submarine Position</h3>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Horizontal</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Forward distance</div>
                          </div>

                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Depth</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Down distance</div>
                          </div>

                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Aim</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.aim %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Target angle</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Current Command with Animation -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Current Command</h3>
                        <div class="flex items-center space-x-4">
                          <div class="badge badge-lg bg-gray-600 text-white">
                            <%= if @command_index < @total_commands do %>
                              Executing
                            <% else %>
                              Complete
                            <% end %>
                          </div>
                          <div class="flex-1">
                            <div class="bg-gray-50 p-4 rounded-lg font-mono text-lg">
                              <%= if @command_index < @total_commands do %>
                                <span class="text-gray-700 font-bold"><%= Enum.at(@navigation_commands, @command_index) %></span>
                              <% else %>
                                <span class="text-gray-600 font-bold">All commands completed!</span>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Map Building Progress -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Map Reconstruction</h3>
                        <div class="stats stats-horizontal">
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Cells Scanned</div>
                            <div class="stat-value text-gray-800"><%= map_size(@current_map) %></div>
                            <div class="stat-desc text-gray-500">Map growing...</div>
                          </div>
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Scan Rate</div>
                            <div class="stat-value text-gray-800">~100/sec</div>
                            <div class="stat-desc text-gray-500">10ms per command</div>
                          </div>
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">ETA</div>
                            <div class="stat-value text-gray-800">
                              <%= trunc((@total_commands - @command_index) * 10 / 1000) %>s
                            </div>
                            <div class="stat-desc text-gray-500">Time remaining</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Mini Map Preview -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Ocean Depth View</h3>
                        <div class="bg-gray-900 p-4 rounded-lg font-mono text-green-400 text-xs max-h-[500px] overflow-y-auto border border-gray-300" style="white-space: pre;">
                          <%= if map_size(@current_map) > 0 do %>
                            <%= SubmarineKata.Scanner.render_map(@current_map) %>
                          <% else %>
                            <div class="text-yellow-400">Initializing map...</div>
                          <% end %>
                        </div>
                        <div class="text-xs text-gray-600 mt-2">
                          Real-time map reconstruction - <%= map_size(@current_map) %> cells discovered
                        </div>
                      </div>
                    </div>
                  </div>

                <% :reconstructing -> %>
                  <div class="alert bg-gray-50 border-gray-200 text-gray-700">
                    <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6 text-gray-600" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    <span>Navigation complete! Rendering final map...</span>
                  </div>
                  <div class="text-sm text-gray-600">
                    <p>🗺️ Final Map Reconstruction:</p>
                    <div class="bg-black text-green-400 p-4 rounded font-mono text-xs max-h-96 overflow-y-auto" style="white-space: pre;">
                      <%= if map_size(@current_map) > 0 do %>
                        <%= SubmarineKata.Scanner.render_map(@current_map) %>
                      <% else %>
                        <div class="text-red-400">No map data available</div>
                      <% end %>
                    </div>
                  </div>

                <% :complete -> %>
                  <div class="alert bg-emerald-50 border-emerald-200 text-emerald-800">
                    <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6 text-emerald-600" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    <span>🎉 Mission Complete! Map reconstruction finished with <%= map_size(@current_map) %> cells discovered.</span>
                  </div>

                  <!-- Keep All Visual Elements + Final Results -->
                  <div class="space-y-6">
                    <!-- Final Progress Bar (100% Complete) -->
                    <div class="w-full bg-gray-50 p-4 rounded-lg border border-gray-200">
                      <div class="flex justify-between text-sm mb-2">
                        <span class="text-gray-700">Navigation Progress</span>
                        <span class="text-gray-600">100% Complete</span>
                      </div>
                      <progress class="progress w-full" value={@total_commands} max={@total_commands}></progress>
                      <div class="flex justify-between text-xs text-gray-500 mt-1">
                        <span>Command <%= @total_commands %> of <%= @total_commands %></span>
                        <span>Mission accomplished</span>
                      </div>
                    </div>

                    <!-- Final Submarine Position -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Final Submarine Position</h3>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Final Horizontal</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Total forward distance</div>
                          </div>

                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Final Depth</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Total down distance</div>
                          </div>

                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Final Aim</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.aim %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Final target angle</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Mission Complete Status -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Mission Status</h3>
                        <div class="flex items-center space-x-4">
                          <div class="badge badge-lg bg-gray-600 text-white">
                            Complete
                          </div>
                          <div class="flex-1">
                            <div class="bg-gray-50 p-4 rounded-lg font-mono text-lg">
                              <span class="text-gray-700">All <%= @total_commands %> commands executed successfully</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Final Results Summary -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Final Results</h3>
                        <div class="stats stats-horizontal">
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Total Cells</div>
                            <div class="stat-value text-gray-800"><%= map_size(@current_map) %></div>
                            <div class="stat-desc text-gray-500">Map reconstruction complete</div>
                          </div>
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Final Product</div>
                            <div class="stat-value text-gray-800">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal * @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc text-gray-500">Horizontal × Depth</div>
                          </div>
                          <div class="stat bg-gray-50 rounded-lg">
                            <div class="stat-title text-gray-600">Commands Executed</div>
                            <div class="stat-value text-gray-800"><%= @total_commands %></div>
                            <div class="stat-desc text-gray-500">Navigation complete</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Complete Map Display -->
                    <div class="card bg-white shadow-sm border border-gray-200">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-gray-800">Complete Ocean Map</h3>
                        <div class="bg-gray-900 p-4 rounded-lg font-mono text-green-400 text-xs max-h-[800px] overflow-y-auto border border-gray-300" style="white-space: pre;">
                          <%= if map_size(@current_map) > 0 do %>
                            <%= SubmarineKata.Scanner.render_map(@current_map) %>
                          <% else %>
                            <div class="text-red-400 text-center py-4">No map data available</div>
                          <% end %>
                        </div>
                        <div class="text-sm text-gray-600 mt-2">
                          Complete map reconstruction - <%= map_size(@current_map) %> cells discovered and mapped
                        </div>
                      </div>
                    </div>
                  </div>
              <% end %>
            </div>
          </div>
        </div>

          <!-- Error Display -->
          <%= if @execution_error do %>
            <div class="alert bg-red-50 border-red-200 text-red-800">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              <span>Execution Error: {@execution_error}</span>
            </div>
          <% end %>
        </div>
    </div>
    """
  end
end
