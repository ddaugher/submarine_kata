defmodule SubmarineKata.CommandTest do
  use ExUnit.Case, async: true

  alias SubmarineKata.Command

  describe "parse/1" do
    test "parses forward command" do
      assert Command.parse("forward 5") == {:ok, %{type: :forward, amount: 5}}
      assert Command.parse("forward 0") == {:ok, %{type: :forward, amount: 0}}
      assert Command.parse("forward 1000") == {:ok, %{type: :forward, amount: 1000}}
    end

    test "parses down command" do
      assert Command.parse("down 3") == {:ok, %{type: :down, amount: 3}}
      assert Command.parse("down 0") == {:ok, %{type: :down, amount: 0}}
      assert Command.parse("down 500") == {:ok, %{type: :down, amount: 500}}
    end

    test "parses up command" do
      assert Command.parse("up 2") == {:ok, %{type: :up, amount: 2}}
      assert Command.parse("up 0") == {:ok, %{type: :up, amount: 0}}
      assert Command.parse("up 250") == {:ok, %{type: :up, amount: 250}}
    end

    test "handles whitespace variations" do
      assert Command.parse(" forward 5 ") == {:ok, %{type: :forward, amount: 5}}
      assert Command.parse("forward  5") == {:ok, %{type: :forward, amount: 5}}
      assert Command.parse("  down 3  ") == {:ok, %{type: :down, amount: 3}}
    end

    test "returns error for invalid direction" do
      assert Command.parse("invalid 5") == {:error, :invalid_command}
      assert Command.parse("sideways 3") == {:error, :invalid_command}
      assert Command.parse("backward 2") == {:error, :invalid_command}
    end

    test "returns error for invalid amount" do
      assert Command.parse("down abc") == {:error, :invalid_amount}
      assert Command.parse("up 3.5") == {:error, :invalid_amount}
    end

    test "returns error for malformed commands" do
      assert Command.parse("forward") == {:error, :invalid_command}
      assert Command.parse("forward 5 extra") == {:error, :invalid_command}
      assert Command.parse("") == {:error, :invalid_command}
      assert Command.parse("   ") == {:error, :invalid_command}
    end

    test "parses negative amounts" do
      assert Command.parse("forward -5") == {:ok, %{type: :forward, amount: -5}}
      assert Command.parse("down -10") == {:ok, %{type: :down, amount: -10}}
      assert Command.parse("up -1") == {:ok, %{type: :up, amount: -1}}
    end
  end

  describe "parse_multiple/1 with list" do
    test "parses multiple valid commands" do
      commands = ["forward 5", "down 3", "up 2"]
      expected = [
        %{type: :forward, amount: 5},
        %{type: :down, amount: 3},
        %{type: :up, amount: 2}
      ]

      assert Command.parse_multiple(commands) == {:ok, expected}
    end

    test "parses empty list" do
      assert Command.parse_multiple([]) == {:ok, []}
    end

    test "parses single command" do
      commands = ["forward 5"]
      expected = [%{type: :forward, amount: 5}]

      assert Command.parse_multiple(commands) == {:ok, expected}
    end

    test "returns error if any command is invalid" do
      commands = ["forward 5", "invalid 3", "up 2"]
      assert Command.parse_multiple(commands) == {:error, :invalid_command}
    end

    test "parses commands with negative amounts" do
      commands = ["forward 5", "down -3", "up 2"]
      expected = [
        %{type: :forward, amount: 5},
        %{type: :down, amount: -3},
        %{type: :up, amount: 2}
      ]
      assert Command.parse_multiple(commands) == {:ok, expected}
    end
  end

  describe "parse_multiple/1 with text" do
    test "parses multiline text" do
      text = "forward 5\ndown 3\nup 2"
      expected = [
        %{type: :forward, amount: 5},
        %{type: :down, amount: 3},
        %{type: :up, amount: 2}
      ]

      assert Command.parse_multiple(text) == {:ok, expected}
    end

    test "parses text with empty lines" do
      text = "forward 5\n\ndown 3\n\nup 2"
      expected = [
        %{type: :forward, amount: 5},
        %{type: :down, amount: 3},
        %{type: :up, amount: 2}
      ]

      assert Command.parse_multiple(text) == {:ok, expected}
    end

    test "parses single line text" do
      text = "forward 5"
      expected = [%{type: :forward, amount: 5}]

      assert Command.parse_multiple(text) == {:ok, expected}
    end

    test "parses empty text" do
      assert Command.parse_multiple("") == {:ok, []}
    end

    test "parses text with only whitespace" do
      assert Command.parse_multiple("   \n  \n  ") == {:ok, []}
    end
  end

  describe "execute/2" do
    test "executes forward command" do
      position = %{horizontal: 0, depth: 0}
      command = %{type: :forward, amount: 5}

      assert Command.execute(position, command) == %{horizontal: 5, depth: 0}
    end

    test "executes down command" do
      position = %{horizontal: 0, depth: 0}
      command = %{type: :down, amount: 3}

      assert Command.execute(position, command) == %{horizontal: 0, depth: 3}
    end

    test "executes up command" do
      position = %{horizontal: 0, depth: 10}
      command = %{type: :up, amount: 3}

      assert Command.execute(position, command) == %{horizontal: 0, depth: 7}
    end

    test "executes commands from existing position" do
      position = %{horizontal: 5, depth: 10}

      forward_cmd = %{type: :forward, amount: 3}
      assert Command.execute(position, forward_cmd) == %{horizontal: 8, depth: 10}

      down_cmd = %{type: :down, amount: 2}
      assert Command.execute(position, down_cmd) == %{horizontal: 5, depth: 12}

      up_cmd = %{type: :up, amount: 4}
      assert Command.execute(position, up_cmd) == %{horizontal: 5, depth: 6}
    end

    test "executes zero amount commands" do
      position = %{horizontal: 5, depth: 10}

      forward_cmd = %{type: :forward, amount: 0}
      assert Command.execute(position, forward_cmd) == %{horizontal: 5, depth: 10}

      down_cmd = %{type: :down, amount: 0}
      assert Command.execute(position, down_cmd) == %{horizontal: 5, depth: 10}

      up_cmd = %{type: :up, amount: 0}
      assert Command.execute(position, up_cmd) == %{horizontal: 5, depth: 10}
    end
  end

  describe "integration tests" do
    test "parse and execute kata example" do
      command_strings = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]

      assert {:ok, commands} = Command.parse_multiple(command_strings)

      expected_commands = [
        %{type: :forward, amount: 5},
        %{type: :down, amount: 5},
        %{type: :forward, amount: 8},
        %{type: :up, amount: 3},
        %{type: :down, amount: 8},
        %{type: :forward, amount: 2}
      ]

      assert commands == expected_commands

      # Execute commands and verify final position
      position = Enum.reduce(commands, %{horizontal: 0, depth: 0}, fn command, pos ->
        Command.execute(pos, command)
      end)
      assert position == %{horizontal: 15, depth: 10}
    end

    test "parse from multiline text and execute" do
      text = "forward 5\ndown 5\nforward 8\nup 3\ndown 8\nforward 2"

      assert {:ok, commands} = Command.parse_multiple(text)

      position = Enum.reduce(commands, %{horizontal: 0, depth: 0}, fn command, pos ->
        Command.execute(pos, command)
      end)
      assert position == %{horizontal: 15, depth: 10}
    end

    test "complex command sequence" do
      commands = [
        "forward 10",
        "down 5",
        "forward 3",
        "up 2",
        "down 7",
        "forward 1",
        "up 4",
        "forward 6"
      ]

      assert {:ok, parsed_commands} = Command.parse_multiple(commands)

      position = Enum.reduce(parsed_commands, %{horizontal: 0, depth: 0}, fn command, pos ->
        Command.execute(pos, command)
      end)
      assert position == %{horizontal: 20, depth: 6}
    end
  end
end
