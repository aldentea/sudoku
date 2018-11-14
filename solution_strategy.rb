

# Base class for solution strategies.
#
# Provides:
# * Access to board
# * verbose controlled output
# * Cell assignment (with statistics)
#
class SolutionStrategy
  def initialize(board)
    @board = board
    @assignments = 0
  end

  def statistics
    { assignments: @assignments }
  end

  private

  def say(*args)
    @board.say(*args)
  end

  def board
    @board
  end

  def assign(cell, number, msg)
    say "Put #{number} at #{cell} (#{msg})"
    cell.number = number
    @assignments += 1
  end
end

