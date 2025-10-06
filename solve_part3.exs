#!/usr/bin/env elixir

# Part 3 Solver Script
# Processes submarine navigation with scanner data collection

defmodule Part3Solver do
  def solve() do
    IO.puts("Submarine Kata Part 3 - Scanner Map Reconstruction")
    IO.puts("=" |> String.duplicate(60))

    # Load scanner data
    IO.puts("Loading scanner data...")
    case SubmarineKata.Scanner.load_scanner_data("files/scanner_data.json") do
      {:ok, scanner_data} ->
        IO.puts("Loaded scanner data with #{map_size(scanner_data)} coordinates")

        # Load input commands
        IO.puts("Loading navigation commands...")
        case File.read("files/input_data.txt") do
          {:ok, input_text} ->
            commands = String.split(input_text, "\n", trim: true)
            IO.puts("Loaded #{length(commands)} commands")

            # Execute navigation with scanning
            IO.puts("Executing navigation with scanner collection...")
            case execute_navigation_with_progress(commands, scanner_data) do
              {:ok, position, map} ->
                IO.puts("Navigation completed!")
                IO.puts("Final position: #{inspect(position)}")
                IO.puts("Map size: #{map_size(map)} cells")

                # Render and display map
                IO.puts("\nRECONSTRUCTED MAP:")
                IO.puts("=" |> String.duplicate(60))
                map_string = SubmarineKata.Scanner.render_map(map)
                IO.puts(map_string)
                IO.puts("=" |> String.duplicate(60))

                # Save map to file
                File.write!("files/reconstructed_map.txt", map_string)
                IO.puts("Map saved to files/reconstructed_map.txt")

              {:error, reason} ->
                IO.puts("Navigation error: #{inspect(reason)}")
            end
          {:error, reason} ->
            IO.puts("Error reading input file: #{inspect(reason)}")
        end
      {:error, reason} ->
        IO.puts("Error loading scanner data: #{inspect(reason)}")
    end
  end

  defp execute_navigation_with_progress(commands, scanner_data) do
    # Parse commands
    case SubmarineKata.Command.parse_multiple(commands) do
      {:ok, parsed_commands} ->
        position = SubmarineKata.Submarine.new()
        map = %{}

        # Add initial position scan
        {position, map} = scan_at_position(position, map, scanner_data)
        IO.puts("Scanned initial position: #{position.horizontal}, #{position.depth}")

        # Execute commands with progress tracking
        total_commands = length(parsed_commands)
        {final_position, final_map} = Enum.with_index(parsed_commands)
        |> Enum.reduce({position, map}, fn {command, index}, {pos, current_map} ->
          # Progress update every 100 commands
          if rem(index, 100) == 0 do
            IO.puts("Progress: #{index + 1}/#{total_commands} commands (#{trunc((index + 1) / total_commands * 100)}%)")
          end

          new_position = SubmarineKata.Command.execute(pos, command)
          scan_at_position(new_position, current_map, scanner_data)
        end)

        IO.puts("Progress: #{total_commands}/#{total_commands} commands (100%)")
        {:ok, final_position, final_map}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp scan_at_position(position, current_map, scanner_data) do
    x = position.horizontal
    y = position.depth
    updated_map = SubmarineKata.Scanner.add_scan_to_map(current_map, scanner_data, x, y)
    {position, updated_map}
  end
end

# Run the solver
Part3Solver.solve()
