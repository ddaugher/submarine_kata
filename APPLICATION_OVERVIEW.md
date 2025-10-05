# Application Overview - Submarine Kata

## Overview

This document provides a comprehensive overview of the Submarine Kata application, including usage patterns, examples, and operational guidelines.

## Version History

- **Part 1** - Basic submarine navigation with forward/down/up commands
- **Part 2** - *[To be implemented]* - Enhanced navigation with aim-based commands  
- **Part 3** - *[To be implemented]* - Advanced submarine operations

## Application Purpose

The Submarine Kata application solves navigation puzzles for a submarine that can move in three dimensions:
- **Horizontal movement**: Forward motion
- **Depth movement**: Up and down motion (with surface boundary)

The application processes a series of navigation commands and calculates the final position and product for submarine navigation scenarios.

## Core Concepts

### 1. Submarine Position
A submarine has two position coordinates:
- **Horizontal Position**: Distance traveled forward (non-negative integer)
- **Depth**: Distance below surface (non-negative integer, where 0 = surface)

### 2. Navigation Commands
Three types of movement commands:
- **`forward X`**: Move forward X units (increases horizontal position)
- **`down X`**: Dive down X units (increases depth)
- **`up X`**: Surface up X units (decreases depth, cannot go below 0)

### 3. Course Execution
A course is a sequence of commands that the submarine follows to reach a final position.

## Usage Patterns

### 1. Basic Course Execution

Execute a simple course and get the final position:

```elixir
commands = ["forward 5", "down 3", "forward 2"]
{:ok, position} = SubmarineKata.execute_course(commands)
# Returns: {:ok, %{horizontal: 7, depth: 3}}
```

### 2. Position Product Calculation

Execute a course and calculate the product of horizontal position × depth:

```elixir
commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
{:ok, product} = SubmarineKata.execute_course_and_calculate_product(commands)
# Returns: {:ok, 150}
```

### 3. Text-based Course Input

Parse and execute a course from multiline text:

```elixir
course_text = """
forward 5
down 5
forward 8
up 3
down 8
forward 2
"""

{:ok, product} = SubmarineKata.execute_course_from_text_and_calculate_product(course_text)
# Returns: {:ok, 150}
```

### 4. Error Handling

Handle invalid commands gracefully:

```elixir
invalid_commands = ["forward 5", "invalid 3", "up 2"]
result = SubmarineKata.execute_course(invalid_commands)
# Returns: {:error, :invalid_command}
```

## Complete Examples

### Example 1: Basic Navigation

```elixir
# Simple forward and dive sequence
commands = ["forward 10", "down 5", "forward 3"]
{:ok, position} = SubmarineKata.execute_course(commands)

IO.puts("Final position: #{inspect(position)}")
# Output: Final position: %{horizontal: 13, depth: 5}

# Calculate the product
product = position.horizontal * position.depth
IO.puts("Product: #{product}")
# Output: Product: 65
```

### Example 2: Kata Example

```elixir
# The classic submarine kata example
kata_commands = [
  "forward 5",
  "down 5", 
  "forward 8",
  "up 3",
  "down 8",
  "forward 2"
]

{:ok, product} = SubmarineKata.execute_course_and_calculate_product(kata_commands)
IO.puts("Kata result: #{product}")
# Output: Kata result: 150
```

### Example 3: Complex Navigation

```elixir
# Complex course with multiple direction changes
complex_course = [
  "forward 100",  # Move forward 100 units
  "down 50",      # Dive to depth 50
  "forward 200",  # Continue forward 200 more units
  "down 100",     # Dive deeper to depth 150
  "up 25",        # Come up slightly to depth 125
  "forward 150"   # Final forward movement
]

{:ok, position} = SubmarineKata.execute_course(complex_course)
IO.puts("Complex navigation result: #{inspect(position)}")
# Output: Complex navigation result: %{horizontal: 450, depth: 125}

{:ok, product} = SubmarineKata.execute_course_and_calculate_product(complex_course)
IO.puts("Product: #{product}")
# Output: Product: 56250
```

### Example 4: Surface Exploration

```elixir
# Course that goes to surface and back down
surface_course = [
  "down 10",      # Dive to depth 10
  "forward 50",   # Explore at depth
  "up 10",        # Surface (depth 0)
  "forward 100",  # Continue on surface
  "down 5",       # Shallow dive to depth 5
  "forward 25"    # Final movement
]

{:ok, position} = SubmarineKata.execute_course(surface_course)
IO.puts("Surface exploration: #{inspect(position)}")
# Output: Surface exploration: %{horizontal: 175, depth: 5}
```

## Error Scenarios

### Invalid Commands

```elixir
# Invalid direction
invalid_direction = ["forward 5", "sideways 3", "up 2"]
result = SubmarineKata.execute_course(invalid_direction)
# Returns: {:error, :invalid_command}

# Invalid amount
invalid_amount = ["forward 5", "down -3", "up 2"]  
result = SubmarineKata.execute_course(invalid_amount)
# Returns: {:error, :invalid_command}
```

### Malformed Input

```elixir
# Malformed command strings
malformed = ["forward", "down 3", "up 2"]
result = SubmarineKata.execute_course(malformed)
# Returns: {:error, :invalid_command}

# Empty course
result = SubmarineKata.execute_course([])
# Returns: {:ok, %{horizontal: 0, depth: 0}}
```

## Advanced Usage Patterns

### 1. Course Validation

```elixir
defmodule CourseValidator do
  def validate_course(commands) do
    case SubmarineKata.execute_course(commands) do
      {:ok, position} -> 
        {:ok, position, position.horizontal * position.depth}
      {:error, reason} -> 
        {:error, reason}
    end
  end
end

# Usage
commands = ["forward 5", "down 3"]
case CourseValidator.validate_course(commands) do
  {:ok, position, product} ->
    IO.puts("Valid course: #{inspect(position)}, product: #{product}")
  {:error, reason} ->
    IO.puts("Invalid course: #{reason}")
end
```

### 2. Course Comparison

```elixir
defmodule CourseComparator do
  def compare_courses(course1, course2) do
    with {:ok, pos1} <- SubmarineKata.execute_course(course1),
         {:ok, pos2} <- SubmarineKata.execute_course(course2) do
      product1 = pos1.horizontal * pos1.depth
      product2 = pos2.horizontal * pos2.depth
      
      cond do
        product1 > product2 -> :course1_better
        product2 > product1 -> :course2_better
        true -> :equal
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
```

### 3. Course Optimization

```elixir
defmodule CourseOptimizer do
  def find_optimal_product(courses) do
    courses
    |> Enum.map(&SubmarineKata.execute_course_and_calculate_product/1)
    |> Enum.filter(fn {status, _} -> status == :ok end)
    |> Enum.map(fn {:ok, product} -> product end)
    |> Enum.max(fn -> 0 end)
  end
end
```

## Performance Characteristics

### Time Complexity
- **Single Command**: O(1) - Constant time execution
- **Course Execution**: O(n) - Linear time based on number of commands
- **Command Parsing**: O(1) per command - Constant time parsing

### Space Complexity
- **Position Storage**: O(1) - Fixed size position structure
- **Command Storage**: O(n) - Linear space for command list
- **Memory Usage**: Minimal - Immutable data structures

### Benchmarks

```elixir
# Large course performance
large_course = for i <- 1..10000, do: "forward #{rem(i, 3) + 1}"

# Execution time: ~1ms for 10,000 commands
{:ok, _position} = SubmarineKata.execute_course(large_course)
```

## Integration Examples

### 1. File-based Course Input

```elixir
defmodule FileCourseLoader do
  def load_course_from_file(filename) do
    case File.read(filename) do
      {:ok, content} ->
        course_lines = String.split(content, "\n", trim: true)
        SubmarineKata.execute_course_from_text_and_calculate_product(content)
      {:error, reason} ->
        {:error, {:file_error, reason}}
    end
  end
end

# Usage
{:ok, product} = FileCourseLoader.load_course_from_file("course.txt")
```

### 2. Interactive Course Builder

```elixir
defmodule InteractiveCourseBuilder do
  def build_course() do
    IO.puts("Enter commands (one per line, empty line to finish):")
    
    commands = 
      IO.stream(:stdio, :line)
      |> Enum.take_while(&(&1 != "\n"))
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
    
    SubmarineKata.execute_course_and_calculate_product(commands)
  end
end
```

## Testing and Validation

### Manual Testing

```elixir
# Quick test in IEx
iex> commands = ["forward 5", "down 5", "forward 8", "up 3", "down 8", "forward 2"]
iex> {:ok, product} = SubmarineKata.execute_course_and_calculate_product(commands)
iex> product
150
```

### Automated Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/submarine_kata/submarine_test.exs

# Run with coverage
mix test --cover
```

## Future Enhancements (Parts 2 & 3)

### Part 2: Enhanced Navigation
- **Aim-based Commands**: `aim X` commands for depth targeting
- **Enhanced State**: Track aim alongside position
- **Complex Maneuvers**: More sophisticated navigation patterns

### Part 3: Advanced Operations
- **Multi-Submarine**: Coordinate multiple submarines
- **Mission Planning**: Complex course optimization
- **Real-time Tracking**: Live position monitoring
- **Data Persistence**: Save and load course data

---

*This document will be updated as new features are added in Parts 2 and 3.*
