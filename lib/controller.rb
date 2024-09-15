class Controller
  MAX_DELTA_FI = 15 # degrees
  MAX_DELTA_POWER = 1 # strenght of thrust
  MAX_X = 6999 # meters
  MAX_Y = 2999 # meters
  MINUMIM_LANDING_WIDTH = 1000 # m

  MARS_G = 3.711 # m/s^2
  MAX_SAFE_HORIZONTAL_CRUISE_SPEED = 50 # ms
  MAX_SAFE_VERTICAL_CRUISE_SPEED = 8 # ms
  MAX_SAFE_HORIZONTAL_SPEED = 19 # m/s
  MAX_SAFE_VERTICAL_SPEED = 36 # m/s # 40 in rules, but it's too unsafe

  RIGHT_DIRECTIONS = [1, 2, 7, 8].to_set.freeze
  LEFT_DIRECTIONS = [3, 4, 5, 6].to_set.freeze
  LANDING_DIRECTIONS = [6, 7].to_set.freeze

  attr_reader :surface_points, :landing_segment, :blocking_segments, :previous_lander_location
  attr_reader :visibility_graph

  attr_accessor :nodes_to_landing
  attr_accessor :x, :y, :h_speed, :v_speed, :fuel, :rotate, :power
  attr_accessor :current_lander_location, :current_path_segment, :direction, :inertia_direction

  # Set up the lander controller by giving it the array of terrain points given before 1st turn.
  #
  # @param surface_points [Array<Point>]
  def initialize(surface_points)
    @surface_points = surface_points
    @lander_location_initialized = false

    collate_surface_points
    initialize_landing_segment
    initialize_blocking_segments
    initialize_visibility_graph
  end

  def collate_surface_points
    points_to_remove = []

    @surface_points.each_cons(3) do |a, b, c|
      next unless Segment.orientation(a, b, c).zero?

      points_to_remove << b
    end

    debug("Detected these points as redundant to constructing the surface: #{points_to_remove}")

    @surface_points -= points_to_remove
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
    @x, @y, @h_speed, @v_speed, @fuel, @rotate, @power = line.split(" ").map(&:to_f)

    self.current_lander_location = Point[x, y]
    initialize_original_route
    remove_reached_node

    debug("Remaining path nodes: #{nodes_to_landing}")

    @current_path_segment = Segment[current_lander_location, nodes_to_landing.first]

    # given that the lander can't change settings dramatically, there's only a limited number of "moves":
    # 180 degrees * 5 power levels, and only a subset of these can be used given a previous move.
    # To start, we'll keep things simple - ignore inertia and only consider 8 cardinal directions with hardcoded "move" for each:

    @direction = current_path_segment.eight_sector_angle
    debug "Need to move in direction #{direction}"

    @inertia_direction = Segment[Point.new(0, 0), Point.new(h_speed, v_speed)].eight_sector_angle
    debug "Inertia direction is: #{inertia_direction}"

    @inertia_direction = Segment[Point.new(0, 0), Point.new(h_speed, v_speed.to_f - MARS_G)].eight_sector_angle
    debug "Inertia direction adjusted for gravity is #{@inertia_direction}"

    if nodes_to_landing.size < 2
      switch_to_targeting_closest_safe_landing
    end

    if _over_landing_strip = nodes_to_landing.size < 2 && (landing_segment.p1.x..landing_segment.p2.x).include?(x)
      # breaking if excessive inertia
      if v_speed.abs > MAX_SAFE_VERTICAL_SPEED
        debug "UNCONTROLLED FALLING DETECTED, BREAKING!"
        return "0 4"
      end

      landing_procedures
    else # as in keep cruisin'
      cruising_to_point(nodes_to_landing.first)
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
    surface_segments = []
    @surface_points.each_cons(2) do |a, b|
      surface_segments << Segment[a, b]
    end

    virtual_segments = []
    @surface_points.each do |p|
      next if p.y.zero?

      potential_segment = Segment[Point[p.x, p.y - 1], Point[p.x, 0]]
      next if surface_segments.find { potential_segment.intersect?(_1) }

      virtual_segments << potential_segment
    end

    @blocking_segments = surface_segments + virtual_segments

    nil
  end

  def initialize_visibility_graph
    graph = WeightedGraph.new

    surface_points[0..-2].each_with_index do |point, i|
      surface_points[i.next..].each do |other_point|
        if other_point == surface_points[i.next]
          # noop, neighboring points always see each other
        else
          next if Segment.orientation(point, surface_points[i.next], other_point) == 2

          next if blocking_segments.find do |segment|
            # segments that originate from either point cannot be visibility blockers for the pair
            next if segment.originates_from?(point) || segment.originates_from?(other_point)

            Segment[point, other_point].intersect?(segment)
          end
        end

        graph.connect_nodes(point, other_point, point.distance_to(other_point))
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

      @visibility_graph.connect_nodes(point, current_lander_location, point.distance_to(current_lander_location))
    end
  end

  def initialize_original_route
    return if @lander_location_initialized

    initialize_lander_location

    nodes_to_landing_left = visibility_graph.dijkstra_shortest_path(current_lander_location, landing_segment.p1)
    nodes_to_landing_right = visibility_graph.dijkstra_shortest_path(current_lander_location, landing_segment.p2)

    distance_to_p1 = visibility_graph.path_length(nodes_to_landing_left)
    distance_to_p2 = visibility_graph.path_length(nodes_to_landing_right)

    self.nodes_to_landing =
      if distance_to_p1 < distance_to_p2
        debug("Getting to landing's LEFT is shortest")
        nodes_to_landing_left
      else
        debug("Getting to landing's RIGHT is shortest")
        nodes_to_landing_right
      end[1..-1]

    debug "NODES TO LANDING: #{nodes_to_landing.to_s}"
    @lander_location_initialized = true
  end

  def remove_reached_node
    # checking if the lander can see the next node in originally planned route
    # and drop current as reached.
    if nodes_to_landing.size > 1
      next_point = nodes_to_landing[1]

      blocker = blocking_segments.find do |segment|
        # segments that originate from either point cannot be visibility blockers for the pair
        next if segment.originates_from?(next_point) || segment.originates_from?(current_lander_location)

        Segment[next_point, current_lander_location].intersect?(segment)
      end

      if blocker.nil?
        debug("Lander can see the next node #{next_point} in planned route, dropping current as reached")
        @nodes_to_landing = nodes_to_landing[1..]
      end
    end
  end

  def landing_procedures
    debug "Above landing strip, time to stabilise and land!"

    if h_speed.abs > MAX_SAFE_HORIZONTAL_SPEED && LANDING_DIRECTIONS.include?(direction)
      debug "HORIZONTAL SLIP DETECTED, BREAKING!"
      if (_going_right_too_fast = RIGHT_DIRECTIONS.include?(inertia_direction))
        return "23 4"
      else
        return "-23 4"
      end
    end

    if _brace_for_impact = current_path_segment.dx.abs < 400 && current_path_segment.dy.abs < 300
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
  end

  # @param destination [Point]
  def cruising_to_point(destination)
    debug "Not above landing strip, cruising to #{destination}"

    if v_speed.negative? && v_speed.abs > MAX_SAFE_VERTICAL_SPEED
      debug "UNCONTROLLED FALLING DETECTED, BREAKING!"
      return "0 4"
    end

    unless h_speed.abs < MAX_SAFE_HORIZONTAL_SPEED
      # breaking based on inertia and estimated break path
      seconds_to_cover_ground = (current_path_segment.dx.abs / h_speed.abs).round
      seconds_to_break_to_safe_speed = ((h_speed.abs - MAX_SAFE_HORIZONTAL_SPEED) /1.5).round

      debug "Traveling at current speed of #{h_speed}, covering #{current_path_segment.dx.abs}m will take #{seconds_to_cover_ground}s, but stabilising #{seconds_to_break_to_safe_speed}s"
      if seconds_to_break_to_safe_speed >= seconds_to_cover_ground || seconds_to_cover_ground < 10
        debug "Breaking to keep overshoot to a minumum"
        correction = if (_going_right_too_fast = RIGHT_DIRECTIONS.include?(inertia_direction))
          case direction
          when 7 then "60 4"
          else "22 4" # break maintaining height
          end
        else # oh, going left too fast
          case direction
          when 6 then "-60 4"
          else "-22 4" # break maintining height
          end
        end

        return correction
      end
    end

    heading_vector = current_path_segment.delta_vector.p2 # HARD LEFT
    inertia_vector = Point.new(h_speed, v_speed.to_f - MARS_G)

    if heading_vector.y.positive? # need to ascend
      if inertia_vector.y.negative?
        debug("Need to ascend detected")
        return "0 4"
      end
    end

    if direction == inertia_direction
      if direction == 6
        debug("Doing controlled descent to the left")
        return "0 1"
      elsif direction == 7
        debug("Doing controlled descent to the right")
        return "0 1"
      end
    end

    debug("Outputting default cruise command")
    case direction
    when 1
      "-22 4" # 22 degrees because given MARS_G and max thrust of 4 it's the breakeven angle
    when 2
      "-5 4"
    when 3
      "5 4"
    when 4
      "22 4"
    when 5
      "45 4"
    when 6 # need to descend
      "60 4"
    when 7 # need to descend
      "-60 4"
    when 8
      "-45 4"
    else
      raise("Unkown direction")
    end
  end

  def switch_to_targeting_closest_safe_landing
    return if @switched_to_targeting_closest_safe_landing

    safe_left_side = Point[landing_segment.p1.x+50, landing_segment.p1.y]
    safe_right_side = Point[landing_segment.p2.x-50, landing_segment.p2.y]

    @nodes_to_landing =
      if current_lander_location.distance_to(safe_left_side) < current_lander_location.distance_to(safe_right_side)
        [safe_left_side]
      else
        [safe_right_side]
      end

    debug("SWITCHED OVER to landing point at #{nodes_to_landing.first}")

    @switched_to_targeting_closest_safe_landing = true
  end
end
