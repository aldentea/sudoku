
require_relative "../solution_strategy"

# If within any group there is a number that can only be assigned to
# single cell, then assign that number to the cell.
#
class GroupStrategy < SolutionStrategy
  # Find a number that has only one possible assignment in a given
  # group.
  def solve
    board.groups.each do |group|
      group.open_cells_map.each do |number, cells|
        if cells.size == 1
          assign cells.first, number, "Group"
          return true
        end
      end
    end
    return false
  end
end
