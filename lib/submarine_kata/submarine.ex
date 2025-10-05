defmodule SubmarineKata.Submarine do
  @moduledoc """
  Represents a submarine's position and movement capabilities.
  
  The submarine tracks horizontal position and depth, and can execute
  movement commands: forward, down, and up.
  """

  @type position :: %{horizontal: non_neg_integer(), depth: non_neg_integer()}

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
  @spec new(non_neg_integer(), non_neg_integer()) :: position()
  def new(horizontal, depth) when horizontal >= 0 and depth >= 0 do
    %{horizontal: horizontal, depth: depth}
  end

  @doc """
  Moves the submarine forward by the specified amount.
  
  ## Examples
  
      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.forward(submarine, 5)
      %{horizontal: 5, depth: 0}
  
  """
  @spec forward(position(), non_neg_integer()) :: position()
  def forward(position, amount) when amount >= 0 do
    %{position | horizontal: position.horizontal + amount}
  end

  @doc """
  Moves the submarine down (increases depth) by the specified amount.
  
  ## Examples
  
      iex> submarine = SubmarineKata.Submarine.new()
      iex> SubmarineKata.Submarine.down(submarine, 3)
      %{horizontal: 0, depth: 3}
  
  """
  @spec down(position(), non_neg_integer()) :: position()
  def down(position, amount) when amount >= 0 do
    %{position | depth: position.depth + amount}
  end

  @doc """
  Moves the submarine up (decreases depth) by the specified amount.
  
  ## Examples
  
      iex> submarine = SubmarineKata.Submarine.new(0, 10)
      iex> SubmarineKata.Submarine.up(submarine, 3)
      %{horizontal: 0, depth: 7}
  
  """
  @spec up(position(), non_neg_integer()) :: position()
  def up(position, amount) when amount >= 0 do
    new_depth = max(0, position.depth - amount)
    %{position | depth: new_depth}
  end

  @doc """
  Calculates the product of horizontal position and depth.
  
  ## Examples
  
      iex> submarine = SubmarineKata.Submarine.new(15, 10)
      iex> SubmarineKata.Submarine.position_product(submarine)
      150
  
  """
  @spec position_product(position()) :: non_neg_integer()
  def position_product(position) do
    position.horizontal * position.depth
  end
end
