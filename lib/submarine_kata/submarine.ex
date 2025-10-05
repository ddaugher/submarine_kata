defmodule SubmarineKata.Submarine do
  @moduledoc """
  Represents a submarine's position and movement capabilities.

  The submarine tracks horizontal position and depth, and can execute
  movement commands: forward, down, and up.
  """

  @type position :: %{horizontal: integer(), depth: integer(), aim: integer()}

  @doc """
  Creates a new submarine at the starting position (0, 0).

  ## Examples

      iex> SubmarineKata.Submarine.new()
      %{horizontal: 0, depth: 0, aim: 0}

  """
  @spec new() :: position()
  def new do
    %{horizontal: 0, depth: 0, aim: 0}
  end

  @doc """
  Creates a submarine with a specific position.

  ## Examples

      iex> SubmarineKata.Submarine.new(5, 10)
      %{horizontal: 5, depth: 10, aim: 0}

  """
  @spec new(integer(), integer()) :: position()
  def new(horizontal, depth) do
    %{horizontal: horizontal, depth: depth, aim: 0}
  end

  @spec new(integer(), integer(), integer()) :: position()
  def new(horizontal, depth, aim) do
    %{horizontal: horizontal, depth: depth, aim: aim}
  end

  @doc """
  Moves the submarine forward by the specified amount.

  In Part 2, forward movement also changes depth based on aim:
  - Increases horizontal position by amount
  - Increases depth by aim * amount

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.forward(submarine, 5)
      %{horizontal: 5, depth: 0, aim: 0}

      iex> submarine = SubmarineKata.Submarine.new(0, 0, 5)
      iex> SubmarineKata.Submarine.forward(submarine, 8)
      %{horizontal: 8, depth: 40, aim: 5}

  """
  @spec forward(position(), integer()) :: position()
  def forward(position, amount) do
    new_horizontal = position.horizontal + amount
    new_depth = position.depth + (position.aim * amount)
    %{position | horizontal: new_horizontal, depth: new_depth}
  end

  @doc """
  Moves the submarine down (increases aim) by the specified amount.

  In Part 2, down changes aim instead of depth:
  - Increases aim by amount

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.down(submarine, 5)
      %{horizontal: 0, depth: 0, aim: 5}

  """
  @spec down(position(), integer()) :: position()
  def down(position, amount) do
    new_aim = position.aim + amount
    %{position | aim: new_aim}
  end

  @doc """
  Moves the submarine up (decreases aim) by the specified amount.

  In Part 2, up changes aim instead of depth:
  - Decreases aim by amount

  ## Examples

      iex> submarine = SubmarineKata.Submarine.new(0, 0, 10)
      iex> SubmarineKata.Submarine.up(submarine, 3)
      %{horizontal: 0, depth: 0, aim: 7}

  """
  @spec up(position(), integer()) :: position()
  def up(position, amount) do
    new_aim = position.aim - amount
    %{position | aim: new_aim}
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
