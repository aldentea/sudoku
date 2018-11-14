
require_relative "../solution_strategy"

# If any cell has only one possible number that may be assigned to it,
# then assign that number.
#
class CellStrategy < SolutionStrategy
  # Find a cell with only one possibility and fill it.  Return true if
  # you are able to fill a square, otherwise return false.
  def solve
    board.cells.each do |cell|
      an = cell.available_numbers
      if an.size == 1
        assign(cell, an.to_a.first, "Cell")
        return true
      end
    end
    return false
  end
end
