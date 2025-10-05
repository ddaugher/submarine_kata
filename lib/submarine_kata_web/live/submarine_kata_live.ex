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

    # Initialize the algorithm execution
    socket =
      socket
      |> assign(:is_running, true)
      |> assign(:current_step, :loading_data)
      |> assign(:current_position, SubmarineKata.Submarine.new())
      |> assign(:current_map, %{})
      |> assign(:command_index, 0)
      |> assign(:total_commands, length(socket.assigns.navigation_commands))
      |> assign(:execution_error, nil)

    # Start the visualization process
    send(self(), :next_step)
    IO.puts("📤 Sent :next_step message")
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
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

    {:noreply, socket}
  end

  @impl true
  def handle_info(:next_step, socket) do
    IO.puts("📥 Received :next_step message, current step_index: #{socket.assigns.step_index}")

    case socket.assigns.step_index do
      0 ->
        IO.puts("🔄 Step 0: Loading data")
        # Data is already loaded, move to scanning initial position
        socket =
          socket
          |> assign(:current_step, :loading_data)
          |> assign(:step_index, 1)

        Process.send_after(self(), :next_step, 50)
        {:noreply, socket}

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
            <!-- Process Information -->
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title">Process Information</h2>

                <div class="space-y-4">
              <%= case @current_step do %>
                <% :intro -> %>
                  <div class="alert alert-info">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    <span>Ready to start the submarine navigation visualization!</span>
                  </div>

                <% :loading_data -> %>
                  <div class="alert alert-warning">
                    <span class="loading loading-spinner loading-sm"></span>
                    <span>Loading scanner data from input files...</span>
                  </div>

                  <!-- Detailed Loading Activity -->
                  <div class="space-y-4">
                    <div class="steps steps-vertical lg:steps-horizontal">
                      <div class="step step-primary">📁 Loading scanner_data.json</div>
                      <div class="step step-primary">📋 Loading input_data.txt</div>
                      <div class="step step-primary">🔍 Parsing navigation commands</div>
                      <div class="step step-primary">🚢 Initializing submarine</div>
                    </div>

                    <div class="stats stats-horizontal shadow">
                      <div class="stat">
                        <div class="stat-title">Scanner Coordinates</div>
                        <div class="stat-value text-primary"><%= map_size(@scanner_data) %></div>
                        <div class="stat-desc">Available scan points</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title">Navigation Commands</div>
                        <div class="stat-value text-secondary"><%= length(@navigation_commands) %></div>
                        <div class="stat-desc">Commands to execute</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title">Data Size</div>
                        <div class="stat-value text-accent"><%= trunc(byte_size(Jason.encode!(@scanner_data)) / 1024) %>KB</div>
                        <div class="stat-desc">Scanner data loaded</div>
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
                        <h4 class="font-bold text-sm mb-2">🔍 Scanner Data Sample (First 5 coordinates):</h4>
                        <pre class="text-xs"><%=
                          @scanner_data
                          |> Enum.take(5)
                          |> Enum.map(fn {coord, data} -> "#{coord}: #{inspect(data)}" end)
                          |> Enum.join("\n")
                        %></pre>
                        <div class="text-xs text-gray-500 mt-2">
                          Showing 5 of <%= map_size(@scanner_data) %> total coordinates...
                        </div>
                      </div>
                    </div>
                  </div>

                <% :navigating -> %>
                  <div class="alert alert-info">
                    <span class="loading loading-spinner loading-sm"></span>
                    <span>🚢 Submarine is navigating through the ocean...</span>
                  </div>

                  <!-- Enhanced Visual Navigation -->
                  <div class="space-y-6">
                    <!-- Progress Bar -->
                    <div class="w-full">
                      <div class="flex justify-between text-sm mb-2">
                        <span>Navigation Progress</span>
                        <span><%= trunc(@command_index / @total_commands * 100) %>% Complete</span>
                      </div>
                      <progress class="progress progress-primary w-full" value={@command_index} max={@total_commands}></progress>
                      <div class="flex justify-between text-xs text-gray-500 mt-1">
                        <span>Command <%= @command_index %> of <%= @total_commands %></span>
                        <span><%= @total_commands - @command_index %> remaining</span>
                      </div>
                    </div>

                    <!-- Visual Submarine Position -->
                    <div class="card bg-gradient-to-r from-blue-100 to-cyan-100 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg">🚢 Submarine Position</h3>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-primary">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 4m0 13V4m-6 3l6-3"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Horizontal</div>
                            <div class="stat-value text-primary">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Forward distance</div>
                          </div>

                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-secondary">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Depth</div>
                            <div class="stat-value text-secondary">
                              <%= if @current_position do %>
                                <%= @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Down distance</div>
                          </div>

                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-accent">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Aim</div>
                            <div class="stat-value text-accent">
                              <%= if @current_position do %>
                                <%= @current_position.aim %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Target angle</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Current Command with Animation -->
                    <div class="card bg-gradient-to-r from-purple-100 to-pink-100 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg">📋 Current Command</h3>
                        <div class="flex items-center space-x-4">
                          <div class="badge badge-lg badge-primary animate-pulse">
                            <%= if @command_index < @total_commands do %>
                              Executing
                            <% else %>
                              Complete
                            <% end %>
                          </div>
                          <div class="flex-1">
                            <div class="bg-white p-4 rounded-lg shadow font-mono text-lg">
                              <%= if @command_index < @total_commands do %>
                                <span class="text-blue-600 font-bold"><%= Enum.at(@navigation_commands, @command_index) %></span>
                              <% else %>
                                <span class="text-green-600 font-bold">🎉 All commands completed!</span>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Map Building Progress -->
                    <div class="card bg-gradient-to-r from-green-100 to-teal-100 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg">🗺️ Map Reconstruction</h3>
                        <div class="stats stats-horizontal">
                          <div class="stat">
                            <div class="stat-figure text-green-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Cells Scanned</div>
                            <div class="stat-value text-green-600"><%= map_size(@current_map) %></div>
                            <div class="stat-desc">Map growing...</div>
                          </div>
                          <div class="stat">
                            <div class="stat-figure text-blue-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Scan Rate</div>
                            <div class="stat-value text-blue-600">~100/sec</div>
                            <div class="stat-desc">10ms per command</div>
                          </div>
                          <div class="stat">
                            <div class="stat-figure text-purple-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">ETA</div>
                            <div class="stat-value text-purple-600">
                              <%= trunc((@total_commands - @command_index) * 10 / 1000) %>s
                            </div>
                            <div class="stat-desc">Time remaining</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Mini Map Preview -->
                    <div class="card bg-gray-900 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-white">🌊 Ocean Depth View</h3>
                        <div class="bg-black p-4 rounded-lg font-mono text-green-400 text-xs max-h-[500px] overflow-y-auto" style="white-space: pre;">
                          <%= if map_size(@current_map) > 0 do %>
                            <%= SubmarineKata.Scanner.render_map(@current_map) %>
                          <% else %>
                            <div class="text-yellow-400">🔄 Initializing map...</div>
                          <% end %>
                        </div>
                        <div class="text-xs text-gray-400 mt-2">
                          Real-time map reconstruction - <%= map_size(@current_map) %> cells discovered
                        </div>
                      </div>
                    </div>
                  </div>

                <% :reconstructing -> %>
                  <div class="alert alert-success">
                    <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
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
                  <div class="alert alert-success">
                    <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    <span>🎉 Mission Complete! Map reconstruction finished with <%= map_size(@current_map) %> cells discovered.</span>
                  </div>

                  <!-- Keep All Visual Elements + Final Results -->
                  <div class="space-y-6">
                    <!-- Final Progress Bar (100% Complete) -->
                    <div class="w-full">
                      <div class="flex justify-between text-sm mb-2">
                        <span>Navigation Progress</span>
                        <span class="text-green-600 font-bold">100% Complete ✅</span>
                      </div>
                      <progress class="progress progress-success w-full" value={@total_commands} max={@total_commands}></progress>
                      <div class="flex justify-between text-xs text-gray-500 mt-1">
                        <span>Command <%= @total_commands %> of <%= @total_commands %></span>
                        <span class="text-green-600">Mission accomplished! 🚢</span>
                      </div>
                    </div>

                    <!-- Final Submarine Position -->
                    <div class="card bg-gradient-to-r from-green-100 to-blue-100 shadow-lg border-2 border-green-400">
                      <div class="card-body">
                        <h3 class="card-title text-lg">🚢 Final Submarine Position</h3>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-primary">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-1.447-.894L15 4m0 13V4m-6 3l6-3"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Final Horizontal</div>
                            <div class="stat-value text-primary">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Total forward distance</div>
                          </div>

                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-secondary">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Final Depth</div>
                            <div class="stat-value text-secondary">
                              <%= if @current_position do %>
                                <%= @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Total down distance</div>
                          </div>

                          <div class="stat bg-white rounded-lg shadow">
                            <div class="stat-figure text-accent">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Final Aim</div>
                            <div class="stat-value text-accent">
                              <%= if @current_position do %>
                                <%= @current_position.aim %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Final target angle</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Mission Complete Status -->
                    <div class="card bg-gradient-to-r from-purple-100 to-pink-100 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg">🎉 Mission Status</h3>
                        <div class="flex items-center space-x-4">
                          <div class="badge badge-lg badge-success animate-pulse">
                            Complete ✅
                          </div>
                          <div class="flex-1">
                            <div class="bg-white p-4 rounded-lg shadow font-mono text-lg">
                              <span class="text-green-600 font-bold">🎉 All <%= @total_commands %> commands executed successfully!</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Final Results Summary -->
                    <div class="card bg-gradient-to-r from-green-100 to-teal-100 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg">🏆 Final Results</h3>
                        <div class="stats stats-horizontal">
                          <div class="stat">
                            <div class="stat-figure text-green-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Total Cells</div>
                            <div class="stat-value text-green-600"><%= map_size(@current_map) %></div>
                            <div class="stat-desc">Map reconstruction complete</div>
                          </div>
                          <div class="stat">
                            <div class="stat-figure text-blue-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Final Product</div>
                            <div class="stat-value text-blue-600">
                              <%= if @current_position do %>
                                <%= @current_position.horizontal * @current_position.depth %>
                              <% else %>
                                0
                              <% end %>
                            </div>
                            <div class="stat-desc">Horizontal × Depth</div>
                          </div>
                          <div class="stat">
                            <div class="stat-figure text-purple-600">
                              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                              </svg>
                            </div>
                            <div class="stat-title">Commands Executed</div>
                            <div class="stat-value text-purple-600"><%= @total_commands %></div>
                            <div class="stat-desc">Navigation complete</div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Complete Map Display -->
                    <div class="card bg-gray-900 shadow-lg">
                      <div class="card-body">
                        <h3 class="card-title text-lg text-white">🗺️ Complete Ocean Map</h3>
                        <div class="bg-black p-4 rounded-lg font-mono text-green-400 text-xs max-h-[600px] overflow-y-auto" style="white-space: pre;">
                          <%= if map_size(@current_map) > 0 do %>
                            <%= SubmarineKata.Scanner.render_map(@current_map) %>
                          <% else %>
                            <div class="text-red-400">No map data available</div>
                          <% end %>
                        </div>
                        <div class="text-xs text-gray-400 mt-2">
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
            <div class="alert alert-error">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
              <span>Execution Error: {@execution_error}</span>
            </div>
          <% end %>
        </div>
    </div>
    """
  end
end
