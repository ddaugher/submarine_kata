defmodule SubmarineKata.Scanner do
  @moduledoc """
  Scanner module for Part 3 - Map reconstruction from scanner data.

  This module handles:
  - Parsing JSON scanner data
  - Querying scanner data at specific coordinates
  - Building maps from 3x3 scan results
  - Rendering final maps
  """

  @doc """
  Loads scanner data from a JSON file.

  ## Examples

      iex> {:ok, data} = SubmarineKata.Scanner.load_scanner_data("files/scanner_data.json")
      iex> is_map(data)
      true

  """
  @spec load_scanner_data(String.t()) :: {:ok, map()} | {:error, any()}
  def load_scanner_data(filename) do
    case File.read(filename) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end
      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  @doc """
  Queries scanner data for a specific coordinate.

  Returns the 3x3 grid data as a list of 9 characters.

  ## Examples

      iex> scanner_data = %{"(5,5)" => ["A","B","C","D","E","F","G","H","I"]}
      iex> SubmarineKata.Scanner.query_scanner(scanner_data, 5, 5)
      ["A","B","C","D","E","F","G","H","I"]

      iex> SubmarineKata.Scanner.query_scanner(scanner_data, 1, 1)
      []

  """
  @spec query_scanner(map(), integer(), integer()) :: list(String.t())
  def query_scanner(scanner_data, x, y) do
    key = "(#{x},#{y})"
    Map.get(scanner_data, key, [])
  end

  @doc """
  Converts a 3x3 grid list to a map of relative coordinates.

  The input list represents a 3x3 grid in row order:
  [top_left, top_center, top_right, mid_left, mid_center, mid_right, bottom_left, bottom_center, bottom_right]

  Returns a map where keys are {dx, dy} offsets and values are the characters.

  ## Examples

      iex> grid = ["A","B","C","D","E","F","G","H","I"]
      iex> SubmarineKata.Scanner.grid_to_coordinates(grid)
      %{{-1,-1} => "A", {0,-1} => "B", {1,-1} => "C",
        {-1,0} => "D", {0,0} => "E", {1,0} => "F",
        {-1,1} => "G", {0,1} => "H", {1,1} => "I"}

  """
  @spec grid_to_coordinates(list(String.t())) :: map()
  def grid_to_coordinates(grid) when length(grid) == 9 do
    # Convert list index to relative coordinates
    Enum.with_index(grid)
    |> Enum.map(fn {char, index} ->
      dx = rem(index, 3) - 1  # -1, 0, 1
      dy = div(index, 3) - 1  # -1, 0, 1
      {{dx, dy}, char}
    end)
    |> Map.new()
  end

  def grid_to_coordinates(_grid), do: %{}

  @doc """
  Adds scanner data to the map at the given position.

  Takes the current map, scanner data, and position, then merges the 3x3 grid
  data into the map using absolute coordinates.

  ## Examples

      iex> current_map = %{}
      iex> scanner_data = %{"(5,5)" => ["A","B","C","D","E","F","G","H","I"]}
      iex> new_map = SubmarineKata.Scanner.add_scan_to_map(current_map, scanner_data, 5, 5)
      iex> new_map[{4,4}]  # top-left of 3x3 grid
      "A"

  """
  @spec add_scan_to_map(map(), map(), integer(), integer()) :: map()
  def add_scan_to_map(current_map, scanner_data, x, y) do
    grid = query_scanner(scanner_data, x, y)
    relative_coords = grid_to_coordinates(grid)

    # Convert relative coordinates to absolute coordinates
    absolute_coords = Enum.map(relative_coords, fn {{dx, dy}, char} ->
      {{x + dx, y + dy}, char}
    end)

    Map.merge(current_map, Map.new(absolute_coords))
  end

  @doc """
  Calculates the dimensions of the map.

  Returns {min_x, max_x, min_y, max_y} for the map bounds.

  ## Examples

      iex> map = %{{0,0} => "A", {5,3} => "B", {2,1} => "C"}
      iex> SubmarineKata.Scanner.map_dimensions(map)
      {0, 5, 0, 3}

  """
  @spec map_dimensions(map()) :: {integer(), integer(), integer(), integer()}
  def map_dimensions(map) do
    coordinates = Map.keys(map)

    if coordinates == [] do
      {0, 0, 0, 0}
    else
      {xs, ys} = Enum.unzip(coordinates)
      {Enum.min(xs), Enum.max(xs), Enum.min(ys), Enum.max(ys)}
    end
  end

  @doc """
  Renders the map as a string.

  Returns a formatted string representation of the map with proper spacing.
  Empty spaces are represented as " ".

  ## Examples

      iex> map = %{{0,0} => "A", {1,0} => "B", {0,1} => "C", {1,1} => "D"}
      iex> SubmarineKata.Scanner.render_map(map)
      "AB\\nCD\\n"

  """
  @spec render_map(map()) :: String.t()
  def render_map(map) do
    {min_x, max_x, min_y, max_y} = map_dimensions(map)

    # Build the map row by row
    for y <- min_y..max_y do
      for x <- min_x..max_x do
        Map.get(map, {x, y}, " ")
      end
      |> Enum.join("")
    end
    |> Enum.join("\n")
  end
end
