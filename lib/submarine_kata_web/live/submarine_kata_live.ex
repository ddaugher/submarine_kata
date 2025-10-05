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
      # All commands executed, move to complete
      final_socket = socket
      |> assign(:step_index, 3)
      |> assign(:current_step, :reconstructing)

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
      <!-- Header -->
      <div class="hero bg-base-100 rounded-lg shadow-lg">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="text-5xl font-bold">🚢 Submarine Kata</h1>
            <p class="py-6">
              Visualizing the submarine navigation algorithm with real-time map reconstruction
            </p>

            <div class="flex gap-4 justify-center">
              <button
                phx-click="start_visualization"
                disabled={@is_running}
                class={[
                  "btn btn-primary",
                  if(@is_running, do: "btn-disabled", else: "")
                ]}
              >
                {if @is_running, do: "Running...", else: "🚀 Start Visualization"}
              </button>

              <button
                phx-click="reset"
                class="btn btn-outline"
              >
                🔄 Reset
              </button>
            </div>
          </div>
        </div>
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
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Left Panel: Process Information -->
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
                  <div class="text-sm text-gray-600">
                    <p>📁 Loaded scanner_data.json</p>
                    <p>📊 Found #{length(@scanner_data["scanners"] || [])} scanners</p>
                    <p>🎯 Found #{length(@scanner_data["beacons"] || [])} beacons</p>
                  </div>
                  <%= if @current_step == :loading_data do %>
                    <div class="mt-4">
                      <div class="bg-gray-100 p-3 rounded max-h-48 overflow-y-auto">
                        <h4 class="font-bold text-sm mb-2">Scanner Data Sample:</h4>
                        <pre class="text-xs">{Jason.encode!(@scanner_data, pretty: true) |> String.slice(0, 500)}...</pre>
                      </div>
                    </div>
                  <% end %>

                <% :navigating -> %>
                  <div class="alert alert-info">
                    <span class="loading loading-spinner loading-sm"></span>
                    <span>Submarine is navigating through the ocean...</span>
                  </div>

                  <!-- Real-time progress -->
                  <div class="space-y-4">
                    <div class="stats stats-horizontal shadow">
                      <div class="stat">
                        <div class="stat-title">Progress</div>
                        <div class="stat-value text-primary"><%= @command_index %>/<%= @total_commands %></div>
                        <div class="stat-desc"><%= trunc(@command_index / @total_commands * 100) %>%</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title">Position</div>
                        <div class="stat-value text-secondary">
                          <%= if @current_position do %>
                            (<%= @current_position.horizontal %>, <%= @current_position.depth %>)
                          <% else %>
                            (0, 0)
                          <% end %>
                        </div>
                        <div class="stat-desc">Horizontal, Depth</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title">Map Size</div>
                        <div class="stat-value"><%= map_size(@current_map) %></div>
                        <div class="stat-desc">Cells scanned</div>
                      </div>
                    </div>

                    <div class="text-sm text-gray-600">
                      <p>📋 Current Command:</p>
                      <div class="bg-blue-100 p-2 rounded font-mono text-sm">
                        <%= if @command_index < @total_commands do %>
                          <%= Enum.at(@navigation_commands, @command_index) %>
                        <% else %>
                          All commands completed!
                        <% end %>
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
                    <div class="bg-black text-green-400 p-4 rounded font-mono text-xs max-h-96 overflow-y-auto">
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
                    <span>Map reconstruction complete! Found <%= map_size(@current_map) %> cells.</span>
                  </div>

                  <!-- Complete State - Show All Data -->
                  <div class="space-y-4 mt-4">
                    <!-- Final Results -->
                    <div class="stats shadow w-full">
                      <div class="stat">
                        <div class="stat-figure text-primary">
                          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path></svg>
                        </div>
                        <div class="stat-title">Total Cells</div>
                        <div class="stat-value text-primary"><%= map_size(@current_map) %></div>
                        <div class="stat-desc">Map reconstruction complete</div>
                      </div>

                      <div class="stat">
                        <div class="stat-figure text-secondary">
                          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                        </div>
                        <div class="stat-title">Final Position</div>
                        <div class="stat-value text-secondary">
                          <%= if @current_position do %>
                            <%= @current_position.horizontal * @current_position.depth %>
                          <% else %>
                            0
                          <% end %>
                        </div>
                        <div class="stat-desc">Product result</div>
                      </div>

                      <div class="stat">
                        <div class="stat-figure text-primary">
                          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h1.586a1 1 0 01.707.293l1.414 1.414a1 1 0 00.707.293h11.172a1 1 0 01.707.293l1.414 1.414a1 1 0 00.707.293H19a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"></path></svg>
                        </div>
                        <div class="stat-title">Navigation Steps</div>
                        <div class="stat-value"><%= @total_commands %></div>
                        <div class="stat-desc">Submarine movements</div>
                      </div>
                    </div>

                    <!-- Final Reconstructed Map -->
                    <div class="bg-gray-50 p-3 rounded">
                      <h4 class="font-bold text-sm mb-2">🗺️ Final Reconstructed Map</h4>
                      <div class="bg-black text-green-400 p-4 rounded font-mono text-xs max-h-96 overflow-y-auto">
                        <%= if map_size(@current_map) > 0 do %>
                          <%= SubmarineKata.Scanner.render_map(@current_map) %>
                        <% else %>
                          <div class="text-red-400">No map data available</div>
                        <% end %>
                      </div>
                    </div>
                  </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Right Panel: Visualization -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Visualization</h2>

            <div class="mockup-code">
              <%= case @current_step do %>
                <% :intro -> %>
                  <pre><code>Ready to visualize submarine navigation...</code></pre>

                <% :loading_data -> %>
                  <pre><code>📁 Loading scanner_data.json...</code></pre>
                  <pre><code>✅ Scanner data loaded successfully</code></pre>

                <% :navigating -> %>
                  <pre><code>🚢 Submarine starting at position (0, 0)</code></pre>
                  <pre><code>📍 Moving to position (1, 0)</code></pre>
                  <pre><code>📍 Moving to position (2, 0)</code></pre>
                  <pre><code>📡 Collecting scanner data...</code></pre>

                <% :reconstructing -> %>
                  <pre><code>🗺️ Reconstructing map...</code></pre>
                  <pre><code>📊 Processing scanner data...</code></pre>
                  <pre><code>🔍 Analyzing beacon positions...</code></pre>
                  <pre><code>✨ Map reconstruction in progress...</code></pre>

                <% :complete -> %>
                  <pre><code>✅ Navigation complete!</code></pre>
                  <pre><code>✅ Map reconstructed successfully</code></pre>
                  <pre><code>📊 Total cells: 2,103</code></pre>
                  <pre><code>🎯 Product: 352</code></pre>
              <% end %>
            </div>
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
    """
  end
end
