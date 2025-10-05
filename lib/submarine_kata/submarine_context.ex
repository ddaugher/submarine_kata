defmodule SubmarineKata.SubmarineContext do
  @moduledoc """
  Context module for submarine operations following Phoenix patterns.

  This module encapsulates all business logic related to submarine
  navigation and course execution, keeping controllers and other
  modules thin.
  """

  alias SubmarineKata.{Submarine, Command}

  @doc """
  Executes a course (list of commands) and returns the final position.

  ## Examples

      iex> commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
      iex> SubmarineKata.SubmarineContext.execute_course(commands)
      {:ok, %{horizontal: 15, depth: 10}}

  """
  @spec execute_course(list(String.t())) :: {:ok, Submarine.position()} | {:error, :invalid_command}
  def execute_course(command_strings) when is_list(command_strings) do
    with {:ok, commands} <- Command.parse_multiple(command_strings) do
      final_position = execute_commands(commands)
      {:ok, final_position}
    end
  end

  @doc """
  Executes a course from a multiline string and returns the final position.

  ## Examples

      iex> course_text = "forward 5\\ndown 5\\nforward 8\\nup 3\\ndown 8\\nforward 2"
      iex> SubmarineKata.SubmarineContext.execute_course_from_text(course_text)
      {:ok, %{horizontal: 15, depth: 10}}

  """
  @spec execute_course_from_text(String.t()) :: {:ok, Submarine.position()} | {:error, :invalid_command}
  def execute_course_from_text(course_text) when is_binary(course_text) do
    command_strings = String.split(course_text, "\n", trim: true)
    execute_course(command_strings)
  end

  @doc """
  Executes a course and calculates the final position product.

  ## Examples

      iex> commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
      iex> SubmarineKata.SubmarineContext.execute_course_and_calculate_product(commands)
      {:ok, 150}

  """
  @spec execute_course_and_calculate_product(list(String.t())) :: {:ok, non_neg_integer()} | {:error, :invalid_command}
  def execute_course_and_calculate_product(command_strings) do
    with {:ok, final_position} <- execute_course(command_strings) do
      product = Submarine.position_product(final_position)
      {:ok, product}
    end
  end

  @doc """
  Executes a course from text and calculates the final position product.

  ## Examples

      iex> course_text = "forward 5\\ndown 5\\nforward 8\\nup 3\\ndown 8\\nforward 2"
      iex> SubmarineKata.SubmarineContext.execute_course_from_text_and_calculate_product(course_text)
      {:ok, 150}

  """
  @spec execute_course_from_text_and_calculate_product(String.t()) :: {:ok, non_neg_integer()} | {:error, :invalid_command}
  def execute_course_from_text_and_calculate_product(course_text) do
    with {:ok, final_position} <- execute_course_from_text(course_text) do
      product = Submarine.position_product(final_position)
      {:ok, product}
    end
  end

  @doc """
  Executes a course step by step and returns the position after each command.

  ## Examples

      iex> commands = ["forward 5", "down 5"]
      iex> SubmarineKata.SubmarineContext.execute_course_with_history(commands)
      {:ok, [
        %{horizontal: 0, depth: 0},
        %{horizontal: 5, depth: 0},
        %{horizontal: 5, depth: 5}
      ]}

  """
  @spec execute_course_with_history(list(String.t())) :: {:ok, list(Submarine.position())} | {:error, :invalid_command}
  def execute_course_with_history(command_strings) when is_list(command_strings) do
    with {:ok, commands} <- Command.parse_multiple(command_strings) do
      positions = execute_commands_with_history(commands)
      {:ok, positions}
    end
  end

  # Private functions

  @spec execute_commands(list(Command.command())) :: Submarine.position()
  defp execute_commands(commands) do
    initial_position = Submarine.new()
    Enum.reduce(commands, initial_position, fn command, position ->
      Command.execute(position, command)
    end)
  end

  @spec execute_commands_with_history(list(Command.command())) :: list(Submarine.position())
  defp execute_commands_with_history(commands) do
    initial_position = Submarine.new()

    commands
    |> Enum.reduce([initial_position], fn command, positions ->
      current_position = List.first(positions)
      new_position = Command.execute(current_position, command)
      [new_position | positions]
    end)
    |> Enum.reverse()
  end
end
