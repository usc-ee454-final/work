$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'

require 'fssm'

require './Game.rb'
class TicTacToe

  attr_accessor :choice
  attr_accessor :game

  def initialize
    @game = Game.new
    @choice = nil
  end

  def monitor
    puts "Waiting for Neural Network"
    FSSM.monitor('.', '**/*') do
    update { |b, r| 
       puts "Update in #{b} to #{r}"
       if r == "test_ttt.txt"
         return
       end
     }
    delete { |b, r| puts "Delete in #{b} to #{r}" }
    create { |b, r| puts "Create in #{b} to #{r}" }
    end
  end

  # Kicks off the game, optional parameter for who starts game: X or O
  def play
    puts "Lets Play Tic Tac Toe!"
    #while !@game.over do
    while true do
      monitor      

      IO.foreach('test_ttt.txt') do |line|
        @game.board = convert_line(line)
        # process the line of text here
      end

      puts "The board: #{@game}" 
      puts "Choosing optimal move"
      minimax(@game)
      @game.make_nn_move(@choice)
      #@game.make_move(@choice)
      #puts "The board: #{@game}"
      #break if @game.over

      puts "Writing to 'to_nn.txt'"
      target = open("to_nn.txt", 'w')
      target.truncate(0)
      target.write(convert_to_line)
      target.close

      puts "The board: #{@game}"

#      print "What would you like to do? (0-8) "
#      choice = ""
#      while choice == "" do
#        choice = $stdin.gets.chomp.to_i
#        if(@game.board[choice]!=0)
#          print "Invalid input. Try Again? "
#          choice = ""
#        end
#      end
#      @game.make_move(Move.new(@game.move_coord(choice)))

      #puts "The board: #{@game.board}"
    end
    puts "I Win!" if @game.win
    puts "You Win!" if @game.lose
    puts "Cats meow" if @game.draw
  end

  def convert_line(line)
    t_b = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    line.split("").each_with_index do |i,index|
      t_b[index] = 1 if i == "2"
      t_b[index] = -1 if i == "1"
    end 
    return t_b
  end

  def convert_to_line
    line = "" #{@cards.join("")}"
    @game.board.each { |num|
      if num == 1
        line+="2"
      elsif num == -1
        line+="1"
      else
        line+="0"
      end
    }
    return line
  end
  def score(game, depth)
    if game.win
        return 10 - depth
    elsif game.lose
        return depth - 10
    else
        return 0
    end
  end

  def minimax(game, depth=0)
    return score(game, depth) if game.over
    depth += 1
    scores = [] # an array of scores
    moves = []  # an array of moves

    # Populate the scores array, recursing as needed
    game.get_available_moves.each do |move|
        possible_game = game.get_new_state(move)
        scores.push minimax(possible_game, depth)
        moves.push move
    end

    # Do the min or the max calculation
    if game.active_turn == -1
        # This is the max calculation
        max_score_index = scores.each_with_index.max[1]
        @choice = moves[max_score_index]
        return scores[max_score_index]
    else
        # This is the min calculation
        min_score_index = scores.each_with_index.min[1]
        @choice = moves[min_score_index]
        return scores[min_score_index]
    end
  end

  #def score(game)
#    if game.win
#        return 10
#    elsif game.lose
#        return -10
#    else
#        return 0
#    end
#  end#

#  def minimax(game)
#    return score(game) if game.over
#    scores = [] # an array of scores
#    moves = []  # an array of moves#

#    # Populate the scores array, recursing as needed
#    game.get_available_moves.each do |move|
#        possible_game = game.get_new_state(move)
#        scores.push minimax(possible_game)
#        moves.push move
#    end#

#    # Do the min or the max calculation
#    if game.active_turn == -1
#        # This is the max calculation
#        max_score_index = scores.each_with_index.max[1]
#        @choice = moves[max_score_index]
#        @choice.owner = 1
#        return scores[max_score_index]
#    else
#        # This is the min calculation
#        min_score_index = scores.each_with_index.min[1]
#        @choice = moves[min_score_index]
#        @choice.owner = -1
#        return scores[min_score_index]
#    end
#end

end

if __FILE__ == $0
  ttt = TicTacToe.new
  ttt.play
end