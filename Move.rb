class Move
	attr_accessor :x   
	attr_accessor :y
	attr_accessor :owner

	def initialize(coord)
		@x = coord[0];
		@y = coord[1];
		@owner = 1;
	end

	def coord_to_pos
		return 3*@y + @x
	end

end

#00|01|02
#10|11|12
#20|21|22  
   