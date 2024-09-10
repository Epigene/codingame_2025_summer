# Put the one-time game setup code that comes before `loop do` here.

# == GAME INIT ==
@surface_n = gets.to_i # the number of points used to draw the surface of Mars.
@surface_points = []

@surface_n.times do
  land_x, land_y = gets.split(" ").map(&:to_i)
  point = Point[land_x, land_y]
  debug point.to_s
  @surface_points << point
end

controller = Controller.new(@surface_points)
