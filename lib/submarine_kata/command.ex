defmodule SubmarineKata.Command do
  @moduledoc """
  Handles parsing and validation of submarine movement commands.

  Commands follow the format: "direction amount" where direction is
  one of: forward, down, up, and amount is an integer (positive or negative).
  """

  @type command_type :: :forward | :down | :up
  @type command :: %{type: command_type(), amount: integer()}

  @doc """
  Parses a command string into a command struct.

  ## Examples

      iex> SubmarineKata.Command.parse("forward 5")
      {:ok, %{type: :forward, amount: 5}}

      iex> SubmarineKata.Command.parse("down 3")
      {:ok, %{type: :down, amount: 3}}

      iex> SubmarineKata.Command.parse("up 2")
      {:ok, %{type: :up, amount: 2}}

      iex> SubmarineKata.Command.parse("invalid 5")
      {:error, :invalid_command}

      iex> SubmarineKata.Command.parse("forward -1")
      {:error, :invalid_amount}

  """
  @spec parse(String.t()) :: {:ok, command()} | {:error, :invalid_command | :invalid_amount}
  def parse(command_string) do
    case String.split(command_string, " ", trim: true) do
      [direction, amount_str] ->
        with {:ok, type} <- parse_direction(direction),
             {:ok, amount} <- parse_amount(amount_str) do
          {:ok, %{type: type, amount: amount}}
        end
      _ ->
        {:error, :invalid_command}
    end
  end

  @doc """
  Parses multiple command strings from a list or multiline string.

  ## Examples

      iex> commands = ["forward 5", "down 3", "up 1"]
      iex> SubmarineKata.Command.parse_multiple(commands)
      {:ok, [%{type: :forward, amount: 5}, %{type: :down, amount: 3}, %{type: :up, amount: 1}]}

      iex> command_text = "forward 5\\ndown 3\\nup 1"
      iex> SubmarineKata.Command.parse_multiple(command_text)
      {:ok, [%{type: :forward, amount: 5}, %{type: :down, amount: 3}, %{type: :up, amount: 1}]}

  """
  @spec parse_multiple(list(String.t()) | String.t()) :: {:ok, list(command())} | {:error, :invalid_command}
  def parse_multiple(command_strings) when is_list(command_strings) do
    parse_multiple_commands(command_strings)
  end

  def parse_multiple(command_text) when is_binary(command_text) do
    command_strings = String.split(command_text, "\n", trim: true)
    # Filter out empty or whitespace-only lines
    filtered_commands = Enum.filter(command_strings, fn line ->
      String.trim(line) != ""
    end)
    parse_multiple_commands(filtered_commands)
  end

  @doc """
  Executes a single command on a submarine position.

  ## Examples

      iex> position = %{horizontal: 0, depth: 0}
      iex> command = %{type: :forward, amount: 5}
      iex> SubmarineKata.Command.execute(position, command)
      %{horizontal: 5, depth: 0}

  """
  @spec execute(SubmarineKata.Submarine.position(), command()) :: SubmarineKata.Submarine.position()
  def execute(position, %{type: :forward, amount: amount}) do
    SubmarineKata.Submarine.forward(position, amount)
  end

  def execute(position, %{type: :down, amount: amount}) do
    SubmarineKata.Submarine.down(position, amount)
  end

  def execute(position, %{type: :up, amount: amount}) do
    SubmarineKata.Submarine.up(position, amount)
  end

  # Private functions

  @spec parse_direction(String.t()) :: {:ok, command_type()} | {:error, :invalid_command}
  defp parse_direction("forward"), do: {:ok, :forward}
  defp parse_direction("down"), do: {:ok, :down}
  defp parse_direction("up"), do: {:ok, :up}
  defp parse_direction(_), do: {:error, :invalid_command}

  @spec parse_amount(String.t()) :: {:ok, integer()} | {:error, :invalid_amount}
  defp parse_amount(amount_str) do
    case Integer.parse(amount_str) do
      {amount, ""} -> {:ok, amount}
      _ -> {:error, :invalid_amount}
    end
  end

  @spec parse_multiple_commands(list(String.t())) :: {:ok, list(command())} | {:error, :invalid_command}
  defp parse_multiple_commands(command_strings) do
    commands = Enum.map(command_strings, &parse/1)

    if Enum.all?(commands, fn {:ok, _} -> true; _ -> false end) do
      parsed_commands = Enum.map(commands, fn {:ok, command} -> command end)
      {:ok, parsed_commands}
    else
      {:error, :invalid_command}
    end
  end
end
