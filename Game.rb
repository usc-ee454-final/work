require './Move.rb'

class Game
	attr_accessor :board
  attr_accessor :active_turn

  MOVES = [[0,0], [1,0], [2,0], [0,1], [1,1], [2,1], [0,2], [1,2], [2,2]]

	def initialize(board = [0, 0, 0, 0, 0, 0, 0, 0, 0], active_turn = -1)
	  @board = board
	  @active_turn = active_turn; #1 Human, -1 Computer
	end

	def get_available_moves()
		available_moves = [];
		@board.each_with_index{|taken, i| 
			available_moves << Move.new(MOVES[i]) if taken == 0
		}
		return available_moves
	end

	def get_new_state(move)
		t_board = []
		t_board.replace(@board)
		t_board[move.coord_to_pos] = @active_turn;
		t_active_turn = @active_turn * -1
		return Game.new(t_board, t_active_turn)
	end

	def make_move(move)
		@board[move.coord_to_pos] = @active_turn;
		@active_turn *= -1
	end

	def make_nn_move(move)
		@board[move.coord_to_pos] = -1;
	end

	def lose
		@board[0]==1&&@board[1]==1&&@board[2]==1 || @board[2]==1&&@board[5]==1&&@board[8]==1 || @board[8]==1&&@board[7]==1&&@board[6]==1 || 
		@board[6]==1&&@board[3]==1&&@board[0]==1 || @board[3]==1&&@board[4]==1&&@board[5]==1 || @board[1]==1&&@board[4]==1&&@board[7]==1 || 
		@board[0]==1&&@board[4]==1&&@board[8]==1 || @board[6]==1&&@board[4]==1&&@board[2]==1
	end

	def win
		@board[0]==-1&&@board[1]==-1&&@board[2]==-1 || @board[2]==-1&&@board[5]==-1&&@board[8]==-1 || @board[8]==-1&&@board[7]==-1&&@board[6]==-1 || 
		@board[6]==-1&&@board[3]==-1&&@board[0]==-1 || @board[3]==-1&&@board[4]==-1&&@board[5]==-1 || @board[1]==-1&&@board[4]==-1&&@board[7]==-1 || 
		@board[0]==-1&&@board[4]==-1&&@board[8]==-1 || @board[6]==-1&&@board[4]==-1&&@board[2]==-1
	end

	def draw()
		unless @board.include?(0)
  		return !(win || lose)
		end 
		return false
	end

	def over()
		win || lose || draw
	end

	def to_s
    puts "#{@board[0]}|#{@board[1]}|#{@board[2]}"
    puts "#{@board[3]}|#{@board[4]}|#{@board[5]}"
    puts "#{@board[6]}|#{@board[7]}|#{@board[8]}"
  end

  def move_coord(index)
  	MOVES[index]
  end

end