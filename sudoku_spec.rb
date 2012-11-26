require 'simplecov'
require 'fileutils'
SimpleCov.start

require 'rspec/given'
require 'sudoku'

AllNumbers = Set[1,2,3,4,5,6,7,8,9]

describe Cell do

  def create_group_with(cell, *numbers)
    g = Group.new
    g << cell
    numbers.each do |n|
      c = Cell.new
      c.number = n
      g << c
    end
    g
  end

  Given(:cell) { Cell.new("C25") }

  Then { cell.to_s.should == "C25" }
  Then { cell.inspect.should ==  "C25" }
  Then { cell.number.should be_nil }
  Then { cell.available_numbers.should == AllNumbers }

  context 'when setting the number' do
    When { cell.number = 4 }
    Then { cell.number.should == 4 }
    Then { cell.available_numbers.should == Set[] }
  end

  context 'when setting number to zero' do
    When { cell.number = 0 }
    Then { cell.number.should be_nil }
    Then { cell.available_numbers.should == AllNumbers }
  end

  context 'within a group' do
    When { create_group_with(cell, 3, 4, 5) }
    Then { cell.available_numbers.should == AllNumbers - Set[3, 4, 5] }
  end
end

describe Group do
  Given(:group) { Group.new }

  Given(:cells) { (1..10).map { |i| Cell.new("C#{i}") } }
  Given { cells.each do |c| group << c end }

  context "with no numbers assigned" do
    Then { group.numbers.should == Set[] }
    Then { group.open_numbers.should == AllNumbers }
    Then { group.cells_open_for(1).should == Set[*cells] }
    Then {
      group.open_cells_map.should == Hash[ AllNumbers.map { |n| [n, Set[*cells]] } ]
    }
  end

  context 'with some numbers' do
    Given {
      [3,6].each do |i| cells[i].number = i end
    }

    Given(:except36) { Set[*cells] - Set[cells[3], cells[6]] }

    Then { group.numbers.should == Set[3,6] }
    Then { group.open_numbers.should == AllNumbers - group.numbers }
    Then { group.cells_open_for(3).should == Set[] }
    Then { group.cells_open_for(1).should == Set[*cells] - Set[cells[3], cells[6]] }

    Then {
      group.open_cells_map.should == Hash[ [1,2,4,5,7,8,9].map { |n| [n, except36] } ]
    }
  end

  context 'with all numbers' do
    Given {
      (1..9).each do |i| cells[i].number = i end
    }
    Then { group.numbers.should == AllNumbers }
    Then { group.open_numbers.should == Set[] }
    Then { group.cells_open_for(1).should == Set[] }
    Then { group.open_cells_map.should == {} }
  end
end

module Puzzles
  Wiki =
    "53  7    " +
    "6  195   " +
    " 98    6 " +
    "8   6   3" +
    "4  8 3  1" +
    "7   2   6" +
    " 6    28 " +
    "   419  5" +
    "    8  79"

  WikiEncoding = Wiki.gsub(/ /, '.')

  WikiSolution =
    "534678912" +
    "672195348" +
    "198342567" +
    "859761423" +
    "426853791" +
    "713924856" +
    "961537284" +
    "287419635" +
    "345286179"

  Medium =
    " 4   7 3 " +
    "  85  1  " +
    " 15 3  9 " +
    "5   7 21 " +
    "  6   8  " +
    " 81 6   9" +
    " 2  4 57 " +
    "  7  29  " +
    " 5 7   8 "

  MediumSolution =
    "942187635" +
    "368594127" +
    "715236498" +
    "593478216" +
    "476921853" +
    "281365749" +
    "829643571" +
    "137852964" +
    "654719382"

  Evil =
    "  53 694 " +
    " 3 1    6" +
    "       3 " +
    "7  9     " +
    " 1  3  2 " +
    "     2  7" +
    " 6       " +
    "8    7 5 " +
    " 436 81  "

  EvilSolution =
    "285376941" +
    "439125786" +
    "176849235" +
    "752981364" +
    "618734529" +
    "394562817" +
    "567213498" +
    "821497653" +
    "943658172"

  Impossible =
    "4 53 694 " +
    " 3 1    6" +
    "       3 " +
    "7  9     " +
    " 1  3  2 " +
    "     2  7" +
    " 6       " +
    "8    7 5 " +
    " 436 81  "

end

describe Board do
  Given(:board) { Board.new }

  Then { board.inspect.should =~ %r(^<Board \.{81}>$) }
  Then { board.cells.size.should == 9 * 9 }
  Then { board.groups.size.should == 3 * 9 }
  Then {
    board.cells.each do |cell|
      cell.available_numbers.should == Set[*(1..9)]
    end
  }

  describe "#parse" do
    Given(:puzzle) { Puzzles::Wiki }

    When(:result) { board.parse(puzzle) }

    context "with a good encoding" do
      Invariant { result.should_not have_failed }

      context "and standard line encoding" do
        Then { board.encoding.should == Puzzles::WikiEncoding }
      end

      context "and dots instead of spaces" do
        Given(:puzzle) { Puzzles::Wiki.gsub(/ /, '.') }
        Then { board.encoding.should == Puzzles::WikiEncoding }
      end

      context "and DOS line encodings" do
        Given(:puzzle) { Puzzles::Wiki.gsub(/\n/, "\r\n") }
        Then { board.encoding.should == Puzzles::WikiEncoding }
      end

      context "and comments" do
        Given(:puzzle) { "# Standard Wiki example\n\n" + Puzzles::Wiki }
        Then { board.encoding.should == Puzzles::WikiEncoding }
      end
    end

    context "with a bad encoding" do
      context "that is short" do
        Given(:puzzle) { Puzzles::Wiki[0...-1] }
        Then { result.should have_failed(Board::ParseError, /too short/i) }
      end

      context "that is long" do
        Given(:puzzle) { Puzzles::Wiki + "." }
        Then { result.should have_failed(Board::ParseError, /too long/i) }
      end

      context "that has invalid characters" do
        Given(:puzzle) { p = Puzzles::Wiki.dup; p[39] = "x"; p }
        Then { result.should have_failed(Board::ParseError, /invalid.*char/i) }
      end
    end
  end

  describe "solving" do
    Given(:strategies) { [ CellStrategy, GroupStrategy, BacktrackingStrategy] }
    Given(:board) { Board.new.parse(puzzle) }
    Given { board.strategies = strategies.map { |sc| sc.new(board) } }

    When(:result) { board.solve }

    context "unsuccessfully" do
      Given(:puzzle) { Puzzles::Impossible }
      Then { result.should have_failed(Board::SolutionError, /no.*solution/i) }
    end

    context "successfully" do
      Invariant { board.should be_solved }
      Invariant { result.should_not have_failed }

      context "with the wiki puzzle" do
        Given(:puzzle) { Puzzles::Wiki }
        Then { board.encoding.should == Puzzles::WikiSolution }
      end

      context "with the medium puzzle" do
        Given(:puzzle) { Puzzles::Medium }
        Then { board.encoding.should == Puzzles::MediumSolution }
      end

      context 'with the Evil Puzzle' do
        Given(:puzzle) { Puzzles::Evil }
        Then { board.encoding.should == Puzzles::EvilSolution }
      end

      context "with only the Guessing strategy" do
        Given(:strategies) { [ BacktrackingStrategy ] }
        Given(:puzzle) { Puzzles::Evil }
        Then { board.encoding.should == Puzzles::EvilSolution }
      end

    end
  end
end

describe "Sudoku Solver" do
  SOLUTION_PATTERN = Puzzles::WikiSolution.chars.to_a.join('\s+')

  def run_top_level
    old_stdout = $stdout
    $stdout = output_string
    begin
      yield
    ensure
      $stdout = old_stdout
    end
  end

  TMP_PUZZLE = 'tmp/puzzle.sud'

  after do
    FileUtils.rm_r 'tmp' rescue nil
  end

  Given(:puzzle_file) {
    FileUtils.mkdir("tmp") rescue nil
    open(TMP_PUZZLE, "w") { |f| f.puts(puzzle) }
    TMP_PUZZLE
  }
  Given(:output_string) { StringIO.new }
  Given(:output) { output_string.string }
  Given(:args) { [puzzle_file, '-v'] }

  Given(:solver) { SudokuSolver.new }

  When(:result) { run_top_level { solver.run(args) } }

  describe 'solve a puzzle' do
    Given(:puzzle) { Puzzles::Wiki }
    Then { output.should =~ /#{SOLUTION_PATTERN}/ }
  end

  describe 'failing to solve a puzzle' do
    Given(:puzzle) { Puzzles::Impossible }
    Then { output.should =~ /no +solution +found/i }
  end

  describe 'complain if no file given' do
    Given(:args) { [] }
    Then { result.should have_failed(SystemExit) }
    Then { output.should =~ /Usage:/ }
  end

  describe "argument handling" do
    When(:result) { run_top_level { solver.run(args) } }

    context "no arguments" do
      Given(:args) { [ '--' ] }
      Then { solver.verbose.should be_false }
      Then { solver.statistics.should be_false }
      Then {
        solver.strategy_classes.should == [
          CellStrategy, GroupStrategy, BacktrackingStrategy
        ]
      }
    end

    context "with verbose" do
      Given(:args) { ['-v'] }
      Then { solver.verbose.should be_true }
    end

    context "with strategies" do
      Given(:args) { ['-sc'] }
      Then { solver.strategy_classes.should == [CellStrategy] }
    end

    context "with strategies" do
      Given(:args) { ['-sg'] }
      Then { solver.strategy_classes.should == [GroupStrategy] }
    end

    context "with strategies" do
      Given(:args) { ['-sb'] }
      Then { solver.strategy_classes.should == [BacktrackingStrategy] }
    end

    context "with strategies" do
      Given(:args) { ['-sgb'] }
      Then { solver.strategy_classes.should == [GroupStrategy, BacktrackingStrategy] }
    end

    context "with bad option" do
      Given(:args) { ['-x'] }
      Then { result.should have_failed(SystemExit) }
      Then { output.should =~ /(unrecognized|unknown).*-x/i }
    end

  end
end
