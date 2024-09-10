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
