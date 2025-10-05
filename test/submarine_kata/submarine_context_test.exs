defmodule SubmarineKata.SubmarineContextTest do
  use ExUnit.Case, async: true

  alias SubmarineKata.SubmarineContext

  describe "execute_course/1" do
    test "executes kata example course" do
      commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]

      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 15, depth: 10}}
    end

    test "executes empty course" do
      assert SubmarineContext.execute_course([]) == {:ok, %{horizontal: 0, depth: 0}}
    end

    test "executes single command course" do
      assert SubmarineContext.execute_course(["forward 5"]) == {:ok, %{horizontal: 5, depth: 0}}
      assert SubmarineContext.execute_course(["down 3"]) == {:ok, %{horizontal: 0, depth: 3}}
      assert SubmarineContext.execute_course(["up 2"]) == {:ok, %{horizontal: 0, depth: -2}}
    end

    test "executes complex course" do
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

      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 20, depth: 6}}
    end

    test "returns error for invalid command" do
      commands = ["forward 5", "invalid 3", "up 2"]
      assert SubmarineContext.execute_course(commands) == {:error, :invalid_command}
    end

    test "handles negative amounts" do
      commands = ["forward 5", "down -3", "up 2"]
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 5, depth: -5}}
    end

    test "handles course that goes above surface" do
      commands = ["down 5", "up 10", "forward 3"]
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 3, depth: -5}}
    end
  end

  describe "execute_course_from_text/1" do
    test "executes course from multiline text" do
      text = "forward 5\ndown 5\nforward 8\nup 3\ndown 8\nforward 2"

      assert SubmarineContext.execute_course_from_text(text) == {:ok, %{horizontal: 15, depth: 10}}
    end

    test "executes course from single line text" do
      assert SubmarineContext.execute_course_from_text("forward 5") == {:ok, %{horizontal: 5, depth: 0}}
    end

    test "executes course from empty text" do
      assert SubmarineContext.execute_course_from_text("") == {:ok, %{horizontal: 0, depth: 0}}
    end

    test "executes course with empty lines" do
      text = "forward 5\n\ndown 3\n\nup 2"
      assert SubmarineContext.execute_course_from_text(text) == {:ok, %{horizontal: 5, depth: 1}}
    end

    test "returns error for invalid text" do
      text = "forward 5\ninvalid 3\nup 2"
      assert SubmarineContext.execute_course_from_text(text) == {:error, :invalid_command}
    end
  end

  describe "execute_course_and_calculate_product/1" do
    test "executes kata example and calculates product" do
      commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]

      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:ok, 150}
    end

    test "calculates product for empty course" do
      assert SubmarineContext.execute_course_and_calculate_product([]) == {:ok, 0}
    end

    test "calculates product for single command" do
      assert SubmarineContext.execute_course_and_calculate_product(["forward 5"]) == {:ok, 0}
      assert SubmarineContext.execute_course_and_calculate_product(["down 3"]) == {:ok, 0}
      assert SubmarineContext.execute_course_and_calculate_product(["forward 5", "down 3"]) == {:ok, 15}
    end

    test "calculates product for complex course" do
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

      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:ok, 120}
    end

    test "returns error for invalid course" do
      commands = ["forward 5", "invalid 3"]
      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:error, :invalid_command}
    end

    test "handles large products" do
      commands = ["forward 1000", "down 2000"]
      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:ok, 2_000_000}
    end
  end

  describe "execute_course_from_text_and_calculate_product/1" do
    test "executes course from text and calculates product" do
      text = "forward 5\ndown 5\nforward 8\nup 3\ndown 8\nforward 2"

      assert SubmarineContext.execute_course_from_text_and_calculate_product(text) == {:ok, 150}
    end

    test "calculates product from single line" do
      assert SubmarineContext.execute_course_from_text_and_calculate_product("forward 5\ndown 3") == {:ok, 15}
    end

    test "calculates product from empty text" do
      assert SubmarineContext.execute_course_from_text_and_calculate_product("") == {:ok, 0}
    end

    test "returns error for invalid text" do
      text = "forward 5\ninvalid 3"
      assert SubmarineContext.execute_course_from_text_and_calculate_product(text) == {:error, :invalid_command}
    end
  end

  describe "execute_course_with_history/1" do
    test "returns position history for kata example" do
      commands = ["forward 5", "down 5", "forward 8"]

      expected_history = [
        %{horizontal: 0, depth: 0},   # starting position
        %{horizontal: 5, depth: 0},   # after forward 5
        %{horizontal: 5, depth: 5},   # after down 5
        %{horizontal: 13, depth: 5}   # after forward 8
      ]

      assert SubmarineContext.execute_course_with_history(commands) == {:ok, expected_history}
    end

    test "returns history for empty course" do
      assert SubmarineContext.execute_course_with_history([]) == {:ok, [%{horizontal: 0, depth: 0}]}
    end

    test "returns history for single command" do
      commands = ["forward 5"]
      expected = [
        %{horizontal: 0, depth: 0},
        %{horizontal: 5, depth: 0}
      ]

      assert SubmarineContext.execute_course_with_history(commands) == {:ok, expected}
    end

    test "returns history for complex course" do
      commands = ["forward 10", "down 5", "up 2"]

      expected_history = [
        %{horizontal: 0, depth: 0},
        %{horizontal: 10, depth: 0},
        %{horizontal: 10, depth: 5},
        %{horizontal: 10, depth: 3}
      ]

      assert SubmarineContext.execute_course_with_history(commands) == {:ok, expected_history}
    end

    test "returns error for invalid course" do
      commands = ["forward 5", "invalid 3"]
      assert SubmarineContext.execute_course_with_history(commands) == {:error, :invalid_command}
    end

    test "handles course that goes above surface" do
      commands = ["down 5", "up 10"]

      expected_history = [
        %{horizontal: 0, depth: 0},
        %{horizontal: 0, depth: 5},
        %{horizontal: 0, depth: -5}
      ]

      assert SubmarineContext.execute_course_with_history(commands) == {:ok, expected_history}
    end
  end

  describe "edge cases and boundary conditions" do
    test "handles zero amounts" do
      commands = ["forward 0", "down 0", "up 0"]
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 0, depth: 0}}
    end

    test "handles large amounts" do
      commands = ["forward 1000000", "down 1000000"]
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 1000000, depth: 1000000}}
    end

    test "handles many commands" do
      commands = Enum.map(1..1000, fn i -> "forward #{rem(i, 3) + 1}" end)

      # Should not crash with many commands
      assert {:ok, final_position} = SubmarineContext.execute_course(commands)
      assert is_map(final_position)
      assert Map.has_key?(final_position, :horizontal)
      assert Map.has_key?(final_position, :depth)
    end

    test "handles commands with extra whitespace" do
      commands = ["  forward 5  ", " down 3 ", " up 2 "]
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 5, depth: 1}}
    end

    test "handles mixed case commands (should fail)" do
      commands = ["Forward 5", "DOWN 3", "Up 2"]
      assert SubmarineContext.execute_course(commands) == {:error, :invalid_command}
    end
  end

  describe "integration tests with real-world scenarios" do
    test "deep dive scenario" do
      commands = [
        "forward 100",  # Move forward
        "down 50",      # Dive deep
        "forward 200",  # Continue forward
        "down 100",     # Dive deeper
        "up 25",        # Come up slightly
        "forward 150"   # Continue forward
      ]

      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 450, depth: 125}}
      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:ok, 56_250}
    end

    test "surface exploration scenario" do
      commands = [
        "down 10",      # Dive shallow
        "forward 50",   # Explore
        "up 10",        # Surface
        "forward 100",  # Continue on surface
        "down 5",       # Shallow dive
        "forward 25"    # Final movement
      ]

      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 175, depth: 5}}
      assert SubmarineContext.execute_course_and_calculate_product(commands) == {:ok, 875}
    end

    test "zigzag pattern" do
      commands = [
        "forward 1",
        "down 1",
        "forward 1",
        "up 1",
        "forward 1",
        "down 1",
        "forward 1",
        "up 1"
      ]

      # Let's trace through this:
      # forward 1: h=1, d=0
      # down 1: h=1, d=1
      # forward 1: h=2, d=1
      # up 1: h=2, d=0
      # forward 1: h=3, d=0
      # down 1: h=3, d=1
      # forward 1: h=4, d=1
      # up 1: h=4, d=0
      assert SubmarineContext.execute_course(commands) == {:ok, %{horizontal: 4, depth: 0}}
    end
  end
end
