defmodule SubmarineKata do
  @moduledoc """
  Submarine Kata - A submarine navigation puzzle solution.

  This module provides the main interface for solving the submarine puzzle.
  It encapsulates submarine movement commands and course execution.
  """

  alias SubmarineKata.SubmarineContext

  @doc """
  Executes a course and returns the final position.

  ## Examples

      iex> commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
      iex> SubmarineKata.execute_course(commands)
      {:ok, %{horizontal: 15, depth: 60, aim: 10}}

  """
  @spec execute_course(list(String.t())) :: {:ok, map()} | {:error, atom()}
  def execute_course(commands) do
    SubmarineContext.execute_course(commands)
  end

  @doc """
  Executes a course and calculates the final position product.

  ## Examples

      iex> commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
      iex> SubmarineKata.execute_course_and_calculate_product(commands)
      {:ok, 900}

  """
  @spec execute_course_and_calculate_product(list(String.t())) :: {:ok, non_neg_integer()} | {:error, atom()}
  def execute_course_and_calculate_product(commands) do
    SubmarineContext.execute_course_and_calculate_product(commands)
  end

  @doc """
  Executes a course from multiline text and calculates the final position product.

  ## Examples

      iex> course_text = "forward 5\\ndown 5\\nforward 8\\nup 3\\ndown 8\\nforward 2"
      iex> SubmarineKata.execute_course_from_text_and_calculate_product(course_text)
      {:ok, 900}

  """
  @spec execute_course_from_text_and_calculate_product(String.t()) :: {:ok, non_neg_integer()} | {:error, atom()}
  def execute_course_from_text_and_calculate_product(course_text) do
    SubmarineContext.execute_course_from_text_and_calculate_product(course_text)
  end
end
