defmodule SubmarineKata.SubmarineTest do
  use ExUnit.Case, async: true

  alias SubmarineKata.Submarine

  describe "new/0" do
    test "creates a submarine at starting position" do
      submarine = Submarine.new()

      assert submarine == %{horizontal: 0, depth: 0}
    end
  end

  describe "new/2" do
    test "creates a submarine with specific position" do
      submarine = Submarine.new(5, 10)

      assert submarine == %{horizontal: 5, depth: 10}
    end

    test "creates a submarine with zero position" do
      submarine = Submarine.new(0, 0)

      assert submarine == %{horizontal: 0, depth: 0}
    end

    test "creates a submarine with large values" do
      submarine = Submarine.new(1000, 2000)

      assert submarine == %{horizontal: 1000, depth: 2000}
    end
  end

  describe "forward/2" do
    test "moves submarine forward by specified amount" do
      submarine = Submarine.new()
      new_submarine = Submarine.forward(submarine, 5)

      assert new_submarine == %{horizontal: 5, depth: 0}
    end

    test "moves submarine forward from existing position" do
      submarine = Submarine.new(10, 5)
      new_submarine = Submarine.forward(submarine, 3)

      assert new_submarine == %{horizontal: 13, depth: 5}
    end

    test "moves submarine forward by zero" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.forward(submarine, 0)

      assert new_submarine == %{horizontal: 5, depth: 10}
    end

    test "moves submarine forward by large amount" do
      submarine = Submarine.new()
      new_submarine = Submarine.forward(submarine, 1000)

      assert new_submarine == %{horizontal: 1000, depth: 0}
    end

    test "moves submarine forward by negative amount (backward)" do
      submarine = Submarine.new(10, 5)
      new_submarine = Submarine.forward(submarine, -3)

      assert new_submarine == %{horizontal: 7, depth: 5}
    end

    test "moves submarine forward by negative amount can go below zero" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.forward(submarine, -10)

      assert new_submarine == %{horizontal: -5, depth: 10}
    end
  end

  describe "down/2" do
    test "moves submarine down by specified amount" do
      submarine = Submarine.new()
      new_submarine = Submarine.down(submarine, 3)

      assert new_submarine == %{horizontal: 0, depth: 3}
    end

    test "moves submarine down from existing position" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.down(submarine, 2)

      assert new_submarine == %{horizontal: 5, depth: 12}
    end

    test "moves submarine down by zero" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.down(submarine, 0)

      assert new_submarine == %{horizontal: 5, depth: 10}
    end

    test "moves submarine down by large amount" do
      submarine = Submarine.new()
      new_submarine = Submarine.down(submarine, 500)

      assert new_submarine == %{horizontal: 0, depth: 500}
    end

    test "moves submarine down by negative amount (up)" do
      submarine = Submarine.new(0, 10)
      new_submarine = Submarine.down(submarine, -3)

      assert new_submarine == %{horizontal: 0, depth: 7}
    end

    test "moves submarine down by negative amount can go below zero" do
      submarine = Submarine.new(0, 5)
      new_submarine = Submarine.down(submarine, -10)

      assert new_submarine == %{horizontal: 0, depth: -5}
    end
  end

  describe "up/2" do
    test "moves submarine up by specified amount" do
      submarine = Submarine.new(0, 10)
      new_submarine = Submarine.up(submarine, 3)

      assert new_submarine == %{horizontal: 0, depth: 7}
    end

    test "moves submarine up from existing position" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.up(submarine, 2)

      assert new_submarine == %{horizontal: 5, depth: 8}
    end

    test "moves submarine up by zero" do
      submarine = Submarine.new(5, 10)
      new_submarine = Submarine.up(submarine, 0)

      assert new_submarine == %{horizontal: 5, depth: 10}
    end

    test "moves submarine up by large amount" do
      submarine = Submarine.new(0, 1000)
      new_submarine = Submarine.up(submarine, 500)

      assert new_submarine == %{horizontal: 0, depth: 500}
    end

    test "moves submarine up beyond surface (depth can go negative)" do
      submarine = Submarine.new(0, 5)
      new_submarine = Submarine.up(submarine, 10)

      assert new_submarine == %{horizontal: 0, depth: -5}
    end

    test "moves submarine up from surface" do
      submarine = Submarine.new(0, 0)
      new_submarine = Submarine.up(submarine, 5)

      assert new_submarine == %{horizontal: 0, depth: -5}
    end

    test "moves submarine up by negative amount (down)" do
      submarine = Submarine.new(0, 5)
      new_submarine = Submarine.up(submarine, -3)

      assert new_submarine == %{horizontal: 0, depth: 8}
    end
  end

  describe "position_product/1" do
    test "calculates product of horizontal position and depth" do
      submarine = Submarine.new(15, 10)
      product = Submarine.position_product(submarine)

      assert product == 150
    end

    test "calculates product when one value is zero" do
      submarine = Submarine.new(0, 10)
      product = Submarine.position_product(submarine)

      assert product == 0
    end

    test "calculates product with negative values" do
      submarine = Submarine.new(-5, -3)
      product = Submarine.position_product(submarine)

      assert product == 15
    end

    test "calculates product with mixed positive and negative values" do
      submarine = Submarine.new(-4, 5)
      product = Submarine.position_product(submarine)

      assert product == -20
    end

    test "calculates product when both values are zero" do
      submarine = Submarine.new(0, 0)
      product = Submarine.position_product(submarine)

      assert product == 0
    end

    test "calculates product with large values" do
      submarine = Submarine.new(1000, 2000)
      product = Submarine.position_product(submarine)

      assert product == 2_000_000
    end

    test "calculates product with single values" do
      submarine = Submarine.new(1, 1)
      product = Submarine.position_product(submarine)

      assert product == 1
    end
  end

  describe "integration tests" do
    test "example from kata: forward 5, down 5, forward 8, up 3, down 8, forward 2" do
      submarine = Submarine.new()

      # forward 5
      submarine = Submarine.forward(submarine, 5)
      assert submarine == %{horizontal: 5, depth: 0}

      # down 5
      submarine = Submarine.down(submarine, 5)
      assert submarine == %{horizontal: 5, depth: 5}

      # forward 8
      submarine = Submarine.forward(submarine, 8)
      assert submarine == %{horizontal: 13, depth: 5}

      # up 3
      submarine = Submarine.up(submarine, 3)
      assert submarine == %{horizontal: 13, depth: 2}

      # down 8
      submarine = Submarine.down(submarine, 8)
      assert submarine == %{horizontal: 13, depth: 10}

      # forward 2
      submarine = Submarine.forward(submarine, 2)
      assert submarine == %{horizontal: 15, depth: 10}

      # Final product
      product = Submarine.position_product(submarine)
      assert product == 150
    end

    test "complex movement sequence" do
      submarine = Submarine.new()

      movements = [
        {:forward, 10},
        {:down, 5},
        {:forward, 3},
        {:up, 2},
        {:down, 7},
        {:forward, 1},
        {:up, 4},
        {:forward, 6}
      ]


      final_submarine = Enum.reduce(movements, submarine, fn {action, amount}, sub ->
        case action do
          :forward -> Submarine.forward(sub, amount)
          :down -> Submarine.down(sub, amount)
          :up -> Submarine.up(sub, amount)
        end
      end)

      assert final_submarine == %{horizontal: 20, depth: 6}
      assert Submarine.position_product(final_submarine) == 120
    end
  end
end
