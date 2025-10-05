defmodule SubmarineKata.NavigationWithScanner do
  @moduledoc """
  Navigation with scanner module for Part 3.

  This module combines Part 2 submarine navigation with scanner data collection
  to build a map of the submarine's surroundings.
  """

  alias SubmarineKata.{Command, Scanner, Submarine}

  @doc """
  Executes a course while collecting scanner data at each position.

  Returns the final position and the reconstructed map.

  ## Examples

      iex> commands = ["forward 5", "down 5", "forward 8"]
      iex> scanner_data = %{"(5,5)" => ["A","B","C","D","E","F","G","H","I"]}
      iex> {:ok, position, map} = SubmarineKata.NavigationWithScanner.execute_course_with_scanning(commands, scanner_data)
      iex> position
      %{horizontal: 13, depth: 40, aim: 5}

  """
  @spec execute_course_with_scanning(list(String.t()), map()) ::
    {:ok, map(), map()} | {:error, :invalid_command}
  def execute_course_with_scanning(commands, scanner_data) do
    case Command.parse_multiple(commands) do
      {:ok, parsed_commands} ->
        position = Submarine.new()
        map = %{}

        # Add initial position scan
        {position, map} = scan_at_position(position, map, scanner_data)

        # Execute commands and scan at each position
        {final_position, final_map} = Enum.reduce(parsed_commands, {position, map}, fn command, {pos, current_map} ->
          new_position = Command.execute(pos, command)
          scan_at_position(new_position, current_map, scanner_data)
        end)

        {:ok, final_position, final_map}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Executes a course from text while collecting scanner data.

  ## Examples

      iex> course_text = "forward 5\\ndown 5\\nforward 8"
      iex> scanner_data = %{"(5,5)" => ["A","B","C","D","E","F","G","H","I"]}
      iex> {:ok, position, map} = SubmarineKata.NavigationWithScanner.execute_course_from_text_with_scanning(course_text, scanner_data)
      iex> position
      %{horizontal: 13, depth: 40, aim: 5}

  """
  @spec execute_course_from_text_with_scanning(String.t(), map()) ::
    {:ok, map(), map()} | {:error, :invalid_command}
  def execute_course_from_text_with_scanning(course_text, scanner_data) do
    commands = String.split(course_text, "\n", trim: true)
    execute_course_with_scanning(commands, scanner_data)
  end

  @doc """
  Loads scanner data and executes a course from the input file.

  This is the main function for Part 3 that:
  1. Loads scanner data from JSON file
  2. Executes the course from input_data.txt
  3. Collects scanner data at each position
  4. Returns the final map

  ## Examples

      iex> {:ok, position, map} = SubmarineKata.NavigationWithScanner.execute_part3()
      iex> is_map(position)
      true

  """
  @spec execute_part3() :: {:ok, map(), map()} | {:error, any()}
  def execute_part3 do
    with {:ok, scanner_data} <- Scanner.load_scanner_data("files/scanner_data.json"),
         {:ok, input_text} <- File.read("files/input_data.txt") do
      execute_course_from_text_with_scanning(input_text, scanner_data)
    end
  end

  @doc """
  Executes Part 3 and renders the final map as a string.

  This is the main entry point for Part 3 that returns the printable map.

  ## Examples

      iex> {:ok, position, map_string} = SubmarineKata.NavigationWithScanner.execute_part3_and_render()
      iex> is_binary(map_string)
      true

  """
  @spec execute_part3_and_render() :: {:ok, map(), String.t()} | {:error, any()}
  def execute_part3_and_render do
    case execute_part3() do
      {:ok, position, map} ->
        map_string = Scanner.render_map(map)
        {:ok, position, map_string}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helper function to scan at a position and update the map
  @spec scan_at_position(map(), map(), map()) :: {map(), map()}
  defp scan_at_position(position, current_map, scanner_data) do
    x = position.horizontal
    y = position.depth
    updated_map = Scanner.add_scan_to_map(current_map, scanner_data, x, y)
    {position, updated_map}
  end
end
