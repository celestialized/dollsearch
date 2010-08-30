require 'rubygems'
require 'RMagick'
include Magick

module DollSearch	
	MAX_Y_AXIS = 50 - 4
	MAX_X_AXIS = 48
	COLOR_THRESHOLD = 35000 
	IMAGE_SIZE = 50
	MIN_EYE_WIDTH = 4
	MAX_EYE_WIDTH = 17
	
	class InvalidFileName < StandardError
	end
	
	class InvalidImage < StandardError
	end
	
	class Doll
		# Scan an image for valid doll face features
		def self.scan(image_file_name)
			raise InvalidFileName, "Invalid filename provided." unless File.exist?(image_file_name)
			
			face = Face.new
			
			if face.set_image(image_file_name)
				puts "potential doll face found"
				return true
			else
				puts "could not find doll face"
				return false
			end	

		end
	end
	
	class Face
		attr_accessor :filename, :image, :left_eye_width, :right_eye_width, :glabella_width, :glabella_start_x_position, :glabella_start_y_position
		
		def initialize
			@filename = ''
			reset_values
			@glabella_start_x_position = 0
			@glabella_start_y_position = 0
		end
		
		# Load the image into RMagick and normalize, resize and adjust threshold so that it becomes a 50px x 50px black and white image and proceed to scan
		def set_image(image_file_name)
			begin
				@image = ImageList.new(image_file_name)
				@file_name = "#{File.dirname(image_file_name)}/scanned_#{File.basename(image_file_name)}"
				@image.normalize.resize!(50,50).threshold(MaxRGB*0.55).write(@file_name)
				@image = ImageList.new(@file_name)
				return true if scan
				return false
			rescue
				raise InvalidImage, "Invalid image - could not be processed by RMagick"
			end
		end
		
		# Two possible scenarios to check for:
		# 1. Detects the length of black pixels until it arrives at a white pixel. If a white pixel is detected, then we assume that the black pixels are a potential left eye
		# 2. Conversely, if we start out with white pixels, then we run along the x axis until we find a black pixel
		# If a black pixel is found, then we reset the glabella and repeat 1. If nothing matches our requirements, we reset and continue on the next y axis. If we do find matches, we continue to check the glabella, right eye and mouth.
		def scan
			(1..MAX_Y_AXIS).each do |y|
				reset_values
				(1..MAX_X_AXIS).each do |x|

					img_pixel_color = @image.pixel_color(x, y)
					
					if img_pixel_color.red <= COLOR_THRESHOLD
										
						@left_eye_width = @left_eye_width + 1 if @glabella_width < 1
						write_to_image(x, y, 'purple')

						if @left_eye_width >= MIN_EYE_WIDTH and @left_eye_width < MAX_EYE_WIDTH and @glabella_width > @left_eye_width and @glabella_width < (@left_eye_width * 2) and @left_eye_width >= MIN_EYE_WIDTH
							return true if check_glabella(x, y)
						else
							@glabella_width = 0					
						end
					else
						# we've encountered a white pixel but cannot assume that it is a glabella
						# so we do a count of white pixels across before it encounters another black pixel
						@glabella_start_x_position = x if @glabella_width == 0
						@glabella_start_y_position = y if @glabella_width == 0
						@glabella_width = @glabella_width + 1
						write_to_image(x, y, '#eee')
					end	
				end
			end
			return false
		end

private
		
		# The glabella width has to be greater than the width and less than twice the width of a potential left eye. If these requirements are matched (from arriving at the next white pixel) then we check for a potential right eye
		def check_glabella(x, y)
			@right_eye_width = @right_eye_width + 1	
			write_to_image(x, y, 'blue')
			return true if check_right_eye
			return false						
		end
		
		# The right eye width has to be larger than the minimum requirement and less than 1.5 times the potential left eye width.
		def check_right_eye
			if @right_eye_width >= MIN_EYE_WIDTH and @right_eye_width < (@left_eye_width + 1)	
				return true if check_mouth
			end
			return false
		end
		
		# Calculate the 0.7:1 ratio down the y axis in expectation of a black pixel for the mouth.
		def check_mouth
			x = @glabella_start_x_position + (@glabella_width / 2).round
			y = ((@glabella_start_y_position + @left_eye_width + @glabella_width + @right_eye_width) * 0.7).round
			mouth_pixel_color = @image.pixel_color(x, y)
			
			if mouth_pixel_color.red <= COLOR_THRESHOLD
				debug_output(x, y)
				write_to_image(x, y, '#f00')
				return true
			end
			return false
		end
		
		# Debugging output to detect valid colored pixels found within image.
		def write_to_image(x, y, color)
			@image.pixel_color(x, y, color)
			@image.write(@file_name)
		end
		
		# reset all values
		def reset_values
			@left_eye_width = 0
			@right_eye_width = 0
			@glabella_width = 0
			@is_valid_face = false
		end
		
		# Debugging output to display current widths and positions
		def debug_output(x, y)
			puts "left eye #{@left_eye_width}"
			puts "glabella #{@glabella_width}"
			puts "right eye #{@right_eye_width}"
			puts "mouth #{x}, #{y}"
		end
	end
end
