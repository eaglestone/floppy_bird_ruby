require 'rubygems'
require 'gosu'

class GameWindow < Gosu::Window
	def initialize
		super(800,600,false)
		self.caption="Floppy Bird"
		@game_state = :titlescreen
		@titlefont = Gosu::Font.new(self, Gosu::default_font_name, 60)
		@scorefont = Gosu::Font.new(self, Gosu::default_font_name, 24)
		@background_image=Gosu::Image.new(self,"fbback.png",true)
    @tune = Gosu::Sample.new(self, "tune.ogg")
		@bird=Bird.new(self)
		@barrier1 = Barrier.new(self)
		@barrier2 = Barrier.new(self, 400)
		@score = @high_score = 0
    @tune.play
	end
	
	def update
		if @game_state == :playing
			@bird.update
			@barrier1.update
			@barrier2.update
		end
	end
	
	def button_down(key_id)
		#context (state) is title screen?
		if @game_state == :titlescreen
			if key_id == Gosu::KbSpace
        @game_state=:playing 
        @bird.reset
        @barrier1.initial_reset
        @barrier2.initial_reset
      end
      
			exit if key_id == Gosu::KbEscape
		end
		
		#context (state) is playing?
		if @game_state == :playing
			@game_state = :titlescreen if  key_id == Gosu::KbEscape
			@bird.boost if key_id == Gosu::KbSpace
		end
		
		#context (state) is game over?
		if @game_state == :game_over
			@game_state = :titlescreen if  key_id == Gosu::KbSpace || key_id == Gosu::KbEscape
		end
	end
	
	def draw
		@background_image.draw(0,0,0)
		do_titles if @game_state == :titlescreen
		if @game_state == :playing
			@bird.draw 
			@barrier1.draw
			@barrier2.draw
      draw_quad(0, 0, 0x80000000, 800, 0, 0x80000000, 0, 50, 0x00000000, 800, 50, 0x00000000, 5)
			@scorefont.draw("Score: #{@score}", 10,10,10,1,1,0xffFFFF00)
			@scorefont.draw("High Score: #{@high_score}" , 640,10,10,1,1,0xffFFFF00)
		end
		do_game_over if @game_state == :game_over
	end
	
	def setGameState(state)
		@game_state = state
	end
	
	def reset_score
		@score = 0
	end
	
	def increment_score
		@score += 1
	end
	
	def check_collision(y)
		@barrier1.check_collision(y)
		@barrier2.check_collision(y)
	end

	def do_titles
		@titlefont.draw("Welcome to Floppy Bird", 100,100,1,1.0,1.0,0xffd05000)
		@titlefont.draw("Press Space to start", 265,200,1,0.5,0.5,0xff507700)
		@titlefont.draw("Press Escape to quit", 265,250,1,0.5,0.5,0xff507700)
		@titlefont.draw("Sound effects from http://www.freesfx.co.uk", 570,580,1,0.2,0.2,0xff303030)
	end
	
	def do_game_over
		draw_quad(200, 80, 0xffEFE4B0, 600, 80, 0xffEFE4B0, 200, 300, 0xffEFE4B0, 600, 300, 0xffEFE4B0, 0)
		@titlefont.draw("GAME OVER!", centre_text_position(@titlefont,"GAME OVER!"),100,1,1.0,1.0,0xffd05000)
		if @score < @high_score
			message = "You scored: #{@score}. High score: #{@high_score}"
		else
			@high_score = @score
			message = "A new high score of #{@score}!!!!"
		end
    width = @titlefont.text_width(message, 0.5)
		@titlefont.draw(message,centre_text_position(@titlefont, message, 0.5),200,1,0.5,0.5,0xff000000)
	end
  
  def centre_text_position(font,text,scale=1)
    width = font.text_width(text,scale)
    return 400-(width/2)
  end
end

class Bird
	attr_accessor :y, :vertical_speed
	
	def initialize(window)
		@window=window
		@image = Gosu::Image.new(window, "bird.png")
    @images = [Gosu::Image.new(window, "bird.png"),Gosu::Image.new(window, "bird-mid.png"),Gosu::Image.new(window, "bird-down.png"),Gosu::Image.new(window, "bird-mid.png")]
    @sound = Gosu::Sample.new(window, "flap.ogg")
    @collision_sound = Gosu::Sample.new(window, "crash.ogg")
		@font = Gosu::Font.new(@window, Gosu::default_font_name, 16)
		reset
	end
	
	def reset
		@y = 300
		@vertical_speed = 0
		@window.reset_score
	end
	
	def update
		@y = @y + @vertical_speed
		
		#hit the top of the screen?
		if @y < 0 then
			@y = 0 
			@vertical_speed = 5
		end
		
		#check to see if hit a barrier
		@window.check_collision(@y)
		
		#check to see if hit the bottom
    if @y > 550 
      @window.setGameState(:game_over) 
      @collision_sound.play
    end
		
		#increment v speed for gravity effect
		@vertical_speed +=0.3
	end
	
	def boost
		@vertical_speed -=7
		@vertical_speed = -12 if @vertical_speed < -12
		@vertical_speed = 12  if @vertical_speed > 12
    @sound.play
	end
	
	def draw
    index = Gosu::milliseconds / 75 % @images.size
		@images[index].draw(50,@y,1,0.3,0.3)
	end
end

class Barrier
	def initialize(window, x_offset = 0)
		@window=window
		@x_offset = x_offset
		@image = Gosu::Image.new(window, "barrier1.png")
    @collision_sound = Gosu::Sample.new(window, "crash.ogg")
    @point_sound = Gosu::Sample.new(window, "bell.ogg")

		initial_reset
	end
	
	def initial_reset
		@y = -100 - rand(300)
		@x = 800 + @x_offset
	end
	
	def reset
		@y = -100 - rand(300)
		@x = 800
		@window.increment_score
    @point_sound.play
	end
	
	def update
		@x -= 5
		reset if @x < 1
	end
	
	def draw
		@image.draw(@x, @y,1)
	end
	
	def check_collision(bird_y)
		x_hit = y_hit = false
		x_hit =true if @x < 100
		y_hit = true if bird_y < @y + 478
		y_hit = true if bird_y > @y + 610
		if y_hit == true && x_hit == true
      @window.setGameState(:game_over) 
      @collision_sound.play
    end
	end
end

#create a window and show it to the world!
window = GameWindow.new
window.show
