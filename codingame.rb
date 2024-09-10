require "set"
require "benchmark"

STDOUT.sync = true # DO NOT REMOVE

def debug(message)
  STDERR.puts message
end

# Point class to represent a point in 2D space
class Point
  attr_reader :x, :y

  def self.[](p1, p2)
    new(p1, p2)
  end

  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "P[#{x}, #{y}]"
  end

  def inspect
    to_s
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def eql?(other)
    self == other
  end

  def hash
    [@x, @y].hash
  end
end

# Segment class to represent a line segment in 2D space
class Segment
  attr_reader :p1, :p2

  def self.[](p1, p2)
    new(p1, p2)
  end

  # @param p1, p1 [Point]
  def initialize(p1, p2)
    @p1 = p1
    @p2 = p2
  end

  def to_s
    "S[#{p1}, #{p2}]"
  end

  def inspect
    to_s
  end

  # change in x
  def dx
    p2.x - p1.x
  end

  # change in y
  def dy
    p2.y - p1.y
  end

  # @return Integer # rounded
  def length
    Math.sqrt(dx**2 + dy**2)
  end

  # @param point [Point]
  def originates_from?(point)
    p1 == point || p2 == point
  end

  # Useful in building visibility graph and shortest flight path
  def intersect?(other_segment)
    o1 = orientation(p1, p2, other_segment.p1)
    o2 = orientation(p1, p2, other_segment.p2)
    o3 = orientation(other_segment.p1, other_segment.p2, p1)
    o4 = orientation(other_segment.p1, other_segment.p2, p2)

    # General case
    return true if o1 != o2 && o3 != o4

    # Special cases
    # p1, p2, and p3 are collinear and p3 lies on segment p1p2
    if o1 == 0 && on_segment?(p1, p2, other_segment.p1)
      return true
    end

    # p1, p2, and p4 are collinear and p4 lies on segment p1p2
    if o2 == 0 && on_segment?(p1, p2, other_segment.p2)
      return true
    end

    # p3, p4, and p1 are collinear and p1 lies on segment p3p4
    if o3 == 0 && on_segment?(other_segment.p1, other_segment.p2, p1)
      return true
    end

    # p3, p4, and p2 are collinear and p2 lies on segment p3p4
    if o4 == 0 && on_segment?(other_segment.p1, other_segment.p2, p2)
      return true
    end

    # Otherwise, the line segments do not intersect
    false
  end

  # Helper function to check if point p3 lies on line segment p1p2 (for collinear case)
  def on_segment?(p1, p2, p3)
    p3.x >= [p1.x, p2.x].min && p3.x <= [p1.x, p2.x].max &&
    p3.y >= [p1.y, p2.y].min && p3.y <= [p1.y, p2.y].max
  end

  # @return [Integer] a rounded angle the segment is facing in, in physics terms:
  # 0;0 -> 100; 1 == 1 degree
  # 0;0 -> 1; 100 == 89 degrees
  # 0;0 -> -100; 1 == 179 degrees
  # 0;0 -> 100;-1 == 359 degrees
  def angle
    # TODO
  end

  # @return [Integer 1..8] the section of pie the angle is pointing in
  def eight_sector_angle
    if dy.positive? # 1234
      if dx.positive? # 12
        if dx > dy
          1
        else
          2
        end
      else # 34
        if dx.abs > dy.abs
          4
        else
          3
        end
      end
    else # 5678
      if dx.positive? # 78
        if dx.abs > dy.abs
          8
        else
          7
        end
      else # 56
        if dx.abs > dy.abs
          5
        else
          6
        end
      end
    end
  end

  def ==(other)
    (@p1 == other.p1 && @p2 == other.p2) || (@p1 == other.p2 && @p2 == other.p1)
  end

  def eql?(other)
    self == other
  end

  def hash
    [@p1, @p2].hash
  end

  private

  # Helper function to compute the orientation of triplet (A, B, C)
  def orientation(p1, p2, p3)
    val = (p3.y - p2.y) * (p2.x - p1.x) - (p3.x - p2.x) * (p2.y - p1.y)

    if val == 0
      return 0  # collinear
    elsif val > 0
      return 1  # clockwise
    else
      return 2  # counterclockwise
    end
  end
end

# Implements a directionless and weightless graph structure with named nodes.
# Initialization gives you an empty graph. Then call #connect_nodes_bidirectionally for relevant
# connections. This will ensure nodes implicitly. Adding nodes by themselves, without connections
# is unnecessary and not supported.
class Graph
  # Key data storage.
  # Each key is a node (key == name),
  # and the value set represents the neighbouring nodes.
  # private attr_reader :structure

  def initialize
    @structure =
      Hash.new do |hash, key|
        hash[key] = {outgoing: Set.new, incoming: Set.new}
      end
  end

  # A shorthand access to underlying has node structure
  def [](node)
    structure[node]
  end

  def nodes
    structure.keys
  end

  # adds a bi-directional connection between two nodes
  def connect_nodes_bidirectionally(node1, node2)
    structure[node1][:incoming] << node2
    structure[node1][:outgoing] << node2

    structure[node2][:incoming] << node1
    structure[node2][:outgoing] << node1

    nil
  end

  # Severs all connections to and from this node
  # @return [nil]
  def remove_node(node)
    structure[node][:incoming].each do |other_node|
      structure[other_node][:outgoing] -= [node]
    end

    structure.delete(node)

    nil
  end

  # @param root/@destination [String] # names of the nodes for which to find path
  #
  # @return [Array, nil] # will return an array of nodes from root to destination, or nil if no path exists
  def dijkstra_shortest_path(root, destination)
    # When we choose the arbitrary starting parent node we mark it as visited by changing its state in the 'visited' structure.
    visited = Set.new([root])

    parent_node_list = {root => nil}

    # Then, after changing its value from FALSE to TRUE in the "visited" hash, we’d enqueue it.
    queue = [root]

    # Next, when dequeing the vertex, we need to examine its neighboring nodes, and iterate (loop) through its adjacent linked list.
    loop do
      dequeued_node = queue.shift
      # debug "dequed '#{ dequeued_node }', remaining queue: '#{ queue }'"

      if dequeued_node.nil?
        return
        # raise("Queue is empty, but destination not reached!")
      end

      neighboring_nodes = structure[dequeued_node][:outgoing]
      # debug "neighboring_nodes for #{ dequeued_node }: '#{ neighboring_nodes }'"

      neighboring_nodes.each do |node|
        # If either of those neighboring nodes hasn’t been visited (doesn’t have a state of TRUE in the “visited” array),
        # we mark it as visited, and enqueue it.
        next if visited.include?(node)

        visited << node
        parent_node_list[node] = dequeued_node

        # debug "parents: #{ parent_node_list }"

        if node == destination
          # destination reached
          path = [node]

          loop do
            parent_node = parent_node_list[path[0]]

            return path if parent_node.nil?

            path.unshift(parent_node)
            # debug "path after update: #{ path }"
          end
        else
          queue << node
        end
      end
    end
  end

  private

    def structure
      @structure
    end

    def initialize_copy(copy)
      dupped_structure =
        structure.each_with_object({}) do |(k, v), mem|
          mem[k] =
            v.each_with_object({}) do |(sk, sv), smem|
              smem[sk] = sv.dup
            end
        end

      copy.instance_variable_set("@structure", dupped_structure)

      super
    end
end

class Controller
  MAX_DELTA_FI = 15 # degrees
  MAX_DELTA_POWER = 1 # strenght of thrust
  MAX_X = 6999 # meters
  MAX_Y = 2999 # meters
  MINUMIM_LANDING_WIDTH = 1000 # m

  MAX_SAFE_HORIZONTAL_CRUISE_SPEED = 50 # ms
  MAX_SAFE_VERTICAL_CRUISE_SPEED = 8 # ms
  MAX_SAFE_HORIZONTAL_SPEED = 19 # m/s
  MAX_SAFE_VERTICAL_SPEED = 39 # m/s # 40 in rules, but it's too unsafe

  RIGHT_DIRECTIONS = [1, 2, 7, 8].to_set.freeze
  LEFT_DIRECTIONS = [3, 4, 5, 6].to_set.freeze
  LANDING_DIRECTIONS = [6, 7].to_set.freeze

  attr_reader :surface_points, :landing_segment, :blocking_segments, :previous_lander_location
  attr_reader :visibility_graph

  attr_accessor :current_lander_location, :path_to_landing
  # LEGACY aka "I see landing strip, going for it"
  attr_accessor :path_to_landing

  # MODERN, an array of nodes omitting lander's location which should be visited.
  attr_accessor :nodes_to_landing

  # Set up the lander controller by giving it the array of terrain points given before 1st turn.
  #
  # @param surface_points [Array<Point>]
  def initialize(surface_points)
    @surface_points = surface_points
    @lander_location_initialized = false

    initialize_landing_segment
    initialize_blocking_segments
    initialize_visibility_graph
  end

  # Have the lander controller provide each turn's "move" output string.
  #
  # @param line [String] the 7-integer per-turn status: "X Y hSpeed vSpeed fuel rotate power"
  #  for example "6500 2600 -20 0 1000 45 0"
  # @return [String] the output line for rotate and power to use this turn
  def call(line)
    # h_speed: the horizontal speed (in m/s), can be negative.
    # v_speed: the vertical speed (in m/s), can be negative.
    # fuel: the quantity of remaining fuel in liters.
    # rotate: the rotation angle in degrees (-90 to 90). E=0, S=90, W=180 N=270
    # power: the thrust power (0 to 4).
    x, y, h_speed, v_speed, fuel, rotate, power = line.split(" ").map(&:to_f)

    # @points -= [@previous_lander_location]
    self.current_lander_location = Point.new(x, y)
    # @points += [@current_lander_location]

    if !@lander_location_initialized
      initialize_lander_location

      self.nodes_to_landing =
        visibility_graph.dijkstra_shortest_path(current_lander_location.to_s, landing_segment.p1.to_s)[1..-1]

      debug "NODES TO LANDING: #{nodes_to_landing.to_s}"
    end

    # TODO, use a visibility graph to build the actual path. For now asuming landing is visible from lander
    # Array of sorted Segments from current lander position to preferred landing site
    @closest_point_to_land =
      if x < landing_segment.p1.x
        # landing_segment.p1
        # adding some safety margins
        Point.new(landing_segment.p1.x+50, landing_segment.p1.y+50)
      elsif landing_segment.p2.x < x
        # landing_segment.p2
        Point.new(landing_segment.p2.x-50, landing_segment.p2.y+50)
      else # on top of landing strip, just descend
        Point.new(x, landing_segment.p1.y+10)
      end

    direct_line_to_landing = Segment.new(@current_lander_location, @closest_point_to_land)

    @path_to_landing =
      if direct_line_to_landing.length < 200
        [direct_line_to_landing]
      else
        point_just_above_landing = Point.new(@closest_point_to_land.x, @closest_point_to_land.y+200)
        [
          Segment.new(@current_lander_location, point_just_above_landing),
          direct_line_to_landing
        ]
      end

    debug "Path to landing: #{path_to_landing}"

    # given that the lander can't change settings dramatically, there's only a limited number of "moves":
    # 180 degrees * 5 power levels, and only a subset of these can be used given a previous move.
    # To start, we'll keep things simple - ignore inertia and only consider 8 cardinal directions with hardcoded "move" for each:

    direction = path_to_landing.first.eight_sector_angle
    debug "Direction is: #{direction}"

    inertia_direction = Segment.new(Point.new(0, 0), Point.new(h_speed, v_speed)).eight_sector_angle
    debug "Inertia direction is: #{inertia_direction}"

    # setting breadcrumb for next round
    @previous_lander_location = @current_lander_location

    # breaking if excessive inertia
    if v_speed.abs > MAX_SAFE_VERTICAL_SPEED
      debug "UNCONTROLLED FALLING DETECTED, BREAKING!"
      return "0 4"
    end

    if _over_landing_strip = @path_to_landing.size <= 2 && (landing_segment.p1.x..landing_segment.p2.x).include?(x)
      debug "Above landing strip, time to stabilise and land!"

      if h_speed.abs > MAX_SAFE_HORIZONTAL_SPEED && LANDING_DIRECTIONS.include?(direction)
        debug "HORIZONTAL SLIP DETECTED, BREAKING!"
        if (_going_right_too_fast = RIGHT_DIRECTIONS.include?(inertia_direction))
          return "23 4"
        else
          return "-23 4"
        end
      end

      if _brace_for_impact = @path_to_landing.first.dx.abs < 400 && @path_to_landing.first.dy.abs < 300
        if v_speed > MAX_SAFE_VERTICAL_SPEED*(2/3.to_f)
          return "0 3"
        else
          return "0 2"
        end
      end

      if h_speed.positive?
        return "15 3"
      else
        return "-15 3"
      end
    else # as in keep cruisin'
      debug "Not above landing strip, keeping cruise on"
      if v_speed.abs > MAX_SAFE_VERTICAL_CRUISE_SPEED
        debug "EXCEEDING CRUISE deltaY, stabilising!"

        if (_going_down_too_fast = v_speed.negative?)
          return "0 4"
        else
          # return "0 2"
        end
      end

      unless h_speed.abs < MAX_SAFE_HORIZONTAL_SPEED
        # breaking based on inertia and estimated break path
        seconds_to_cover_ground = (@path_to_landing.first.dx.abs / h_speed.abs).round
        seconds_to_break_to_safe_speed = ((h_speed.abs - MAX_SAFE_HORIZONTAL_SPEED) /1.5).round

        debug "Traveling at current speed of #{h_speed}, covering #{@path_to_landing.first.dx.abs}m will take #{seconds_to_cover_ground}s, but breaking #{seconds_to_break_to_safe_speed}s"
        if seconds_to_break_to_safe_speed >= seconds_to_cover_ground || seconds_to_cover_ground < 10
          debug "Breaking to keep overshoot to a minumum"
          if (_going_right_too_fast = RIGHT_DIRECTIONS.include?(inertia_direction))
            return "22 4"
          else
            return "-22 4"
          end
        end
      end

      # rotate power. rotate is the desired rotation angle. power is the desired thrust power.
      case direction
      when 1
        "-30 4"
      when 2
        "-5 4"
      when 3
        "5 4"
      when 4
        "30 4"
      when 5
        "30 4"
      when 6 # landing
        "25 4"
      when 7 # landing
        "-25 4"
      when 8
        "-30 4"
      else
        raise("Unkown direction")
      end
    end
  end

  private

  def initialize_landing_segment
    @surface_points.each_cons(2) do |a, b|
      next unless (b.x - a.x >= MINUMIM_LANDING_WIDTH) && a.y == b.y

      @landing_segment = Segment[a, b]
      debug "Landing detected at #{@landing_segment}"
    end

    nil
  end

  # naturally, each pairwise surface point makes a potentially blocking segment, but to
  # disambiguate over-ground visibility from under-ground un-visibility we'll draw vertical lines
  # to 0 height also.
  def initialize_blocking_segments
    @blocking_segments = []
    @surface_points.each_cons(2) do |a, b|
      @blocking_segments << Segment[a, b]
    end

    @surface_points.each do |p|
      next if p.y.zero?

      @blocking_segments << Segment[p, Point[p.x, 0]]
    end

    nil
  end

  def initialize_visibility_graph
    graph = Graph.new

    surface_points.each do |point|
      # TODO, implement skipping of already checked pairs
      surface_points.each do |other_point|
        next if point == other_point

        next if blocking_segments.find do |segment|
          # segments that originate from either point cannot be visibility blockers for the pair
          next if segment.originates_from?(point) || segment.originates_from?(other_point)

          Segment[point, other_point].intersect?(segment)
        end

        graph.connect_nodes_bidirectionally(point.to_s, other_point.to_s)
      end
    end

    @visibility_graph = graph
  end

  # we get lander location only on first turn, not init, so we'll have to check what the lander sees
  # and build shortest path from there
  def initialize_lander_location
    surface_points.each do |point|
      next if blocking_segments.find do |segment|
        # segments that originate from either point cannot be visibility blockers for the pair
        next if segment.originates_from?(point) || segment.originates_from?(current_lander_location)

        Segment[point, current_lander_location].intersect?(segment)
      end

      @visibility_graph.connect_nodes_bidirectionally(point.to_s, current_lander_location.to_s)
    end
  end
end

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

debug "Game starts!"
# game loop
loop do
  line = gets.chomp
  debug(line)
  puts controller.call(line)
end

