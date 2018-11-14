
require_relative "../solution_strategy"

# Guess a cell assignment.
#
# If the board is not stuck, then make a guess at an arbitrary cell.
# Remember the cell and the other choices. Choose the arbitrary cell
# by looking for cells with the fewest number of choices (this
# minimizes backtracking).
#
# If the board is stuck, then restore the board to a previous state
# and make a different choice.
#
# If the board is stuck, and there are no alternatives, then we can't
# move.
#
class BacktrackingStrategy < SolutionStrategy
  def initialize(board)
    super
    @alternatives = []
    @backtrack = 0
    @max_alternatives = 0
  end

  def statistics
    super.merge(backtrack: @backtrack, max_alternatives: @max_alternatives)
  end

  def solve
    if ! board.stuck?
      cell = find_candidate_for_guessing
      remember_alternatives(cell)
      guess
    elsif @alternatives.empty?
      false
    else
      say "Backtracking (#{plural(@alternatives.size, 'alternative')} available)"
      @backtrack += 1
      guess
    end
  end

  private

  # Find a candidate cell for guessing.  The candidate must be an
  # unassigned cell.  Prefer cells with the fewest number of available
  # numbers (just to minimize backtracking).
  def find_candidate_for_guessing
    unassigned_cells.sort_by { |cell|
      [cell.available_numbers.size, to_s]
    }.first
  end

  # Return a list of unassigned cells on the board.
  def unassigned_cells
    board.cells.to_a.reject { |cell| cell.number }
  end

  # Remember the all the alternative choices for the given cell on the
  # list of alternatives.  An alternative is stored as a 3-tuple
  # consisting of the current encoded state of the board, the cell and
  # an available number.
  def remember_alternatives(cell)
    cell.available_numbers.each do |n|
      @alternatives.push([board.encoding, cell, n])
    end
    @max_alternatives = [@max_alternatives, @alternatives.size].max
  end

  # Make a guess by pulling an alternative from the list of remembered
  # alternatives and.  The state of the board at the remembered
  # alternative is restored and the choice is made for that cell.
  def guess
    state, cell, number = @alternatives.pop
    board.parse(state)
    assign(cell, number, "Guessing, #{plural(@alternatives.size, 'alternative')} remaining")
    true
  end

  # Pluralize +word+.  Assume simply adding an 's' is sufficient.
  def plural(n, word)
    if n == 1
      "#{n} #{word}"
    else
      "#{n} #{word}s"
    end
  end
end
