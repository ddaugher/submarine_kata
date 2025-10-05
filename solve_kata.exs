#!/usr/bin/env elixir

# Submarine Kata Solver
# Processes the input data file and calculates the final position and product

defmodule KataSolver do
  def solve(input_file \\ "files/input_data.txt") do
    IO.puts("🔍 Submarine Kata Solver")
    IO.puts("=" |> String.duplicate(50))

    case File.read(input_file) do
      {:ok, input_text} ->
        commands = String.split(input_text, "\n", trim: true)
        IO.puts("📊 Processing #{length(commands)} commands from #{input_file}")

        case SubmarineKata.execute_course_from_text_and_calculate_product(input_text) do
          {:ok, product} ->
            IO.puts("✅ SUCCESS!")
            IO.puts("🎯 Final product: #{product}")

            # Get detailed position information
            case SubmarineKata.execute_course(commands) do
              {:ok, position} ->
                IO.puts("📍 Final position:")
                IO.puts("   Horizontal: #{position.horizontal}")
                IO.puts("   Depth: #{position.depth}")
                IO.puts("🔢 Verification: #{position.horizontal} × #{position.depth} = #{product}")

                # Show some statistics
                show_statistics(commands, position, product)
              {:error, reason} ->
                IO.puts("❌ Error getting position: #{reason}")
            end
          {:error, reason} ->
            IO.puts("❌ ERROR: #{reason}")
        end

      {:error, reason} ->
        IO.puts("❌ Could not read file #{input_file}: #{reason}")
    end
  end

  defp show_statistics(commands, _position, product) do
    IO.puts("\n📈 Statistics:")

    # Count command types
    forward_count = commands |> Enum.count(&String.starts_with?(&1, "forward"))
    down_count = commands |> Enum.count(&String.starts_with?(&1, "down"))
    up_count = commands |> Enum.count(&String.starts_with?(&1, "up"))

    IO.puts("   Commands: #{length(commands)} total")
    IO.puts("   Forward: #{forward_count}")
    IO.puts("   Down: #{down_count}")
    IO.puts("   Up: #{up_count}")

    # Show final result
    IO.puts("\n🏆 FINAL RESULT: #{product}")
    IO.puts("=" |> String.duplicate(50))
  end
end

# Run the solver
KataSolver.solve()
