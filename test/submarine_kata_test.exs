defmodule SubmarineKataTest do
  use ExUnit.Case, async: true
  doctest SubmarineKata

  describe "execute_course/1" do
    test "executes kata example course" do
      commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]

      assert SubmarineKata.execute_course(commands) == {:ok, %{horizontal: 15, depth: 10}}
    end

    test "executes empty course" do
      assert SubmarineKata.execute_course([]) == {:ok, %{horizontal: 0, depth: 0}}
    end

    test "returns error for invalid course" do
      commands = ["forward 5", "invalid 3"]
      assert SubmarineKata.execute_course(commands) == {:error, :invalid_command}
    end
  end

  describe "execute_course_and_calculate_product/1" do
    test "executes kata example and calculates product" do
      commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]

      assert SubmarineKata.execute_course_and_calculate_product(commands) == {:ok, 150}
    end

    test "calculates product for empty course" do
      assert SubmarineKata.execute_course_and_calculate_product([]) == {:ok, 0}
    end

    test "returns error for invalid course" do
      commands = ["forward 5", "invalid 3"]
      assert SubmarineKata.execute_course_and_calculate_product(commands) == {:error, :invalid_command}
    end
  end

  describe "execute_course_from_text_and_calculate_product/1" do
    test "executes course from text and calculates product" do
      course_text = "forward 5\ndown 5\nforward 8\nup 3\ndown 8\nforward 2"

      assert SubmarineKata.execute_course_from_text_and_calculate_product(course_text) == {:ok, 150}
    end

    test "calculates product from empty text" do
      assert SubmarineKata.execute_course_from_text_and_calculate_product("") == {:ok, 0}
    end

    test "returns error for invalid text" do
      course_text = "forward 5\ninvalid 3"
      assert SubmarineKata.execute_course_from_text_and_calculate_product(course_text) == {:error, :invalid_command}
    end
  end
end
