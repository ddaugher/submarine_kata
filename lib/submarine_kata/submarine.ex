defmodule SubmarineKata.Submarine do
  @moduledoc """
  Represents a submarine's position and movement capabilities.

  The submarine tracks horizontal position and depth, and can execute
  movement commands: forward, down, and up.
  """

  @type position :: %{horizontal: integer(), depth: integer()}

  @doc """
  Creates a new submarine at the starting position (0, 0).

  ## Examples

      iex> SubmarineKata.Submarine.new()
      %{horizontal: 0, depth: 0}

  """
  @spec new() :: position()
  def new do
    %{horizontal: 0, depth: 0}
  end

  @doc """
  Creates a submarine with a specific position.

  ## Examples

      iex> SubmarineKata.Submarine.new(5, 10)
      %{horizontal: 5, depth: 10}

  """
  @spec new(integer(), integer()) :: position()
  def new(horizontal, depth) do
    %{horizontal: horizontal, depth: depth}
  end

  @doc """
  Moves the submarine forward by the specified amount.

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.forward(submarine, 5)
      %{horizontal: 5, depth: 0}

  """
  @spec forward(position(), integer()) :: position()
  def forward(position, amount) do
    new_horizontal = position.horizontal + amount
    %{position | horizontal: new_horizontal}
  end

  @doc """
  Moves the submarine down (increases depth) by the specified amount.

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.down(submarine, 3)
      %{horizontal: 0, depth: 3}

  """
  @spec down(position(), integer()) :: position()
  def down(position, amount) do
    new_depth = position.depth + amount
    %{position | depth: new_depth}
  end

  @doc """
  Moves the submarine up (decreases depth) by the specified amount.

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new(0, 10)
      iex> SubmarineKata.Submarine.up(submarine, 3)
      %{horizontal: 0, depth: 7}

  """
  @spec up(position(), integer()) :: position()
  def up(position, amount) do
    new_depth = position.depth - amount
    %{position | depth: new_depth}
  end

  @doc """
  Calculates the product of horizontal position and depth.

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new(15, 10)
      iex> SubmarineKata.Submarine.position_product(submarine)
      150

  """
  @spec position_product(position()) :: integer()
  def position_product(position) do
    position.horizontal * position.depth
  end
end
