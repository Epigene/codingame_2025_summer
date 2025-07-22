# Implements a cell-based Grid - a special sub-type of a directionless and weightless graph structure.
# Node IDs are "x y" String objects monkeypatched to respond to #x and #y.
# "0 0" origin is assumed to be in the upper left, "1 1" is to the lower right of it.
# Allows special concepts like "row", "column", "straight line along a row/column", and "diagonally".
#
# Initialization gives you an empty grid. Use #add_cell to populate the grid. By default the new
# cell will be connected to all four neighbour cells and . Use kwargs to :except or :only needed connections.
# Use `add_cell( trim_excess: false)` to opt out of 'outside bounds auto-trim'
class Grid
  # Key data storage.
  # Each key is a node (key == name),
  # and the value set represents the neighbouring nodes.
  # private attr_reader :structure

  NEIGHBORS = [
    N = [0, -1].freeze, # North
    E = [1, 0].freeze, # East
    S = [0, 1].freeze, # South
    W = [-1, 0].freeze, # West
  ].freeze

  DIAGONALS = [
    NW = [-1, -1],
    NE = [1, -1],
    SW = [-1, 1],
    SE = [1, 1]
  ].freeze

  N8 = (NEIGHBORS + DIAGONALS).freeze

  attr_reader :width, :height

  # @param fill Boolean # whether to run naive structure fillout
  def initialize(width, height, fill: false)
    @width = width
    @height = height

    @structure =
      Hash.new do |hash, key|
        hash[key] = Set.new
      end

    if fill
      width.times do |x|
        height.times do |y|
          add_cell("#{x} #{y}")
        end
      end
    end
  end

  def max_x
    width - 1
  end

  def max_y
    height - 1
  end

  # Returns a new
  # @return Grid
  def dup
    duplicate = self.class.new(width, height)
    new_structure = {}
    nodes.each { new_structure[_1] = self[_1].dup }
    duplicate.instance_variable_set("@structure", new_structure)
    duplicate
  end

  # A shorthand access to underlying has node structure
  def [](node)
    structure[node]
  end

  def nodes
    structure.keys
  end

  # adds a new cell node. By default all 4 neighbors, but kwars allow tweaking that.
  #
  # @param point Point
  # @param except Array<neighbor>
  # @param only Array<neighbor>
  def add_cell(point, except: nil, only: nil, auto_trim: true)
    raise ArgumentError.new("Only one of :except or :only kwards is supported") if !except.nil? && !only.nil?

    neighbors = NEIGHBORS.dup

    if !except.nil?
      neighbors -= except
    elsif !only.nil?
      neighbors &= only
    end

    raise ArgumentError.new(":except/:only use made a cell have no neighbors") if neighbors.none?

    structure[point] ||= Set.new

    neighbors.each do |neighbor|
      neighbor = "#{point.x + neighbor.first} #{point.y + neighbor.last}"

      next if auto_trim && cell_outside_norms?(neighbor)

      structure[point] << neighbor
      structure[neighbor] << point
    end

    nil
  end

  def cell_outside_norms?(cell)
    cell.x.negative? ||
    cell.y.negative? ||
    cell.x > width - 1 ||
    cell.y > height - 1
  end

  # Removes a list of cells and any connections to it from the neighbors
  # @return [nil]
  def remove_cells(cells)
    cells.each do |cell|
      remove_cell(cell)
    end

    nil
  end

  # Removes the cell and any connections to it from the neighbors
  # @return [nil]
  def remove_cell(cell)
    return if structure[cell].nil?

    structure[cell].each do |other_cell|
      structure[other_cell] -= [cell]
      structure.delete(other_cell) if structure[other_cell].none?
    end

    structure.delete(cell)

    nil
  end

  # Uses bi-directional path lookup approach, 40% more efficient than naive dijkstra
  def shortest_path(start, goal, excluding: nil)
    return [start] if start == goal

    # Initialize forward and backward search queues
    forward_queue = [start]
    backward_queue = [goal]

    # Sets to track visited nodes for both directions
    exclusions = excluding.to_a.each_with_object({}) do |node, mem|
      mem[node] = nil
    end

    forward_visited = {start => nil}.merge(exclusions) # Maps node to its parent
    backward_visited = {goal => nil}.merge(exclusions)

    loop do
      # Expand the forward search
      if forward_queue.any?
        intersect = expand_layer(forward_queue, forward_visited, backward_visited, structure)
        return build_path(intersect, forward_visited, backward_visited) if intersect
      end

      # Expand the backward search
      if backward_queue.any?
        intersect = expand_layer(backward_queue, backward_visited, forward_visited, structure)
        return build_path(intersect, forward_visited, backward_visited) if intersect
      end

      # If neither queue can proceed, no path exists
      return if forward_queue.empty? && backward_queue.empty?
    end

    nil # No path found
  end

  # Feed in for example shortest path found to get its distance. Useful when comparing routes
  #
  # @param path [Array<cell>]
  # @return Integer
  def path_length(path)
    path.size - 1
  end

  # @return Integer
  def manhattan_distance(pointA, pointB)
    @manhattan_distances ||= {}
    key = "#{pointA}_#{pointB}"
    @manhattan_distances[key] ||= (pointA.x - pointB.x).abs + (pointA.y - pointB.y).abs
  end

  def manhattan_distance_from_mid(point)
    closest_mid_x = width.odd? ? (width / 2) : ([(width / 2), (width / 2) - 1].sort_by { (point.x - _1).abs }.first)
    closest_mid_y = height.odd? ? (height / 2) : ([(height / 2), (height / 2) - 1].sort_by { (point.y - _1).abs }.first)

    manhattan_distance(point, Point[closest_mid_x, closest_mid_y])
  end

  # @return Array<Coords>
  def area(x_range, y_range)
    coords = []
    x_range.each do |x|
      y_range.each do |y|
        coords << "#{x} #{y}"
      end
    end

    coords
  end

  # Useful for finding longest rows in a grid
  #
  # @return Hash # { y => [[P[0, 0], P[1, 0], P[2, 0]]] } each row lists its segment x-es
  def row_segments
    rows = Hash.new { |hash, key| hash[key] = [] }
    nodes.each do |node|
      rows[node.y] << node.x
    end

    segments = {}

    rows.each do |y, x_coords|
      x_coords.sort! # Sort x-coordinates in the row
      row_segments = []

      current_segment = [Point[x_coords.first, y]]

      x_coords.each_cons(2) do |a, b|
        if b == a.next
          current_segment << Point[b, y]
        else # break in contiguity
          row_segments << current_segment

          current_segment = [Point[b, y]]
        end
      end

      # Add the last segment
      row_segments << current_segment
      segments[y] = row_segments
    end

    segments
  end

  # Given an arena of known dimensions, we can split it in two horizontal halves (odd mid column gets excluded)
  # and ask for one of the halves.
  #
  # @return Set<Point>
  def horizontally_opposite_side_cells(from:)
    mid_x =
      if width.odd?
        (width - 1) / 2
      else
        mid_indexes = (0..width-1).to_a.mid
        mid_indexes.sort_by { |i| (from.x - i).abs }.first
      end

    left_root = from.x < mid_x

    nodes.each_with_object(Set.new) do |node, mem|
      on_other_side =
        if left_root
          node.x > mid_x
        else
          node.x < mid_x
        end

      mem << node if on_other_side
    end
  end

  # As in navigable neighbors # use #n8 to get just cell-geometry level data
  def neighbors(point)
    structure[point]
  end

  # assumes no out-of bounds per width*height cells are present
  # @return Array<String> # array of points
  def n4(point)
    NEIGHBORS.filter_map do |delta|
      new_x = point.x + delta[0]
      new_y = point.y + delta[1]
      n = "#{new_x} #{new_y}"

      next if cell_outside_norms?(n)
      n
    end
  end

  # assumes no out-of bounds per width*height cells are present
  # @return Array<String> # array of points
  def n8(point)
    N8.filter_map do |delta|
      new_x = point.x + delta[0]
      new_y = point.y + delta[1]
      n = "#{new_x} #{new_y}"

      next if cell_outside_norms?(n)
      n
    end
  end

  # Returns cells that are specified distance away from a given cell. Useful for telling
  # which cells are covered by a bombard attack 2-3 cells away etc.
  #
  # @param range Range
  # @return Set
  def cells_at_distance(point, range)
    visited = Set.new
    queue = [[point, 0]] # Each element is [current_cell, current_distance]
    result = Set.new

    while queue.any?
      current_cell, current_distance = queue.shift

      # Skip if already visited
      next if visited.include?(current_cell)

      visited.add(current_cell)

      # Add to result if within the range
      if range.include?(current_distance)
        result << current_cell
      end

      # Stop exploring if the current distance exceeds the maximum range
      next if current_distance > range.max

      # Enqueue all neighbors with incremented distance
      structure[current_cell].each do |neighbor|
        queue << [neighbor, current_distance.next]
      end
    end

    result
  end

  def cells_at_diagonal_distance(point, range)
    diagonal_as_direct_ranges = range.map { (_1 * 2)..(_1 * 2) }

    cells_at_distances = diagonal_as_direct_ranges.map do |range|
      cells_at_distance(point, range)
    end.flatten.reduce { |a, b| a += b }

    cells_at_distances.reject do |cell|
      cell.x == point.x || cell.y == point.y
    end.to_set
  end

  # Assumes points on at least same row/column. Tells the cardinal direction of the pair.
  # @return String # one of %w[N E S W]
  def direction(point_a, point_b)
    if point_a.x == point_b.x && point_a.y > point_b.y
      return "N"
    elsif point_a.x == point_b.x && point_a.y < point_b.y
      return "S"
    elsif point_a.y == point_b.y && point_a.x > point_b.x
      return "W"
    elsif point_a.y == point_b.y && point_a.x < point_b.x
      return "E"
    end

    raise "Hmm, same points?"
  end

  private

    def structure
      @structure
    end

    def expand_layer(queue, visited, other_visited, structure)
      current_node = queue.shift

      structure[current_node].sort_by { |neighbor| manhattan_distance_from_mid(neighbor) }.each do |neighbor|
        next if visited.key?(neighbor)

        visited[neighbor] = current_node
        return neighbor if other_visited.key?(neighbor) # Intersection found

        queue << neighbor
      end

      nil
    end

    def build_path(intersect, forward_visited, backward_visited)
      path = []

      # Build path from start to intersection
      current = intersect
      while current
        path.unshift(current)
        current = forward_visited[current]
      end

      # Build path from intersection to goal
      current = backward_visited[intersect]
      while current
        path << current
        current = backward_visited[current]
      end

      path
    end
end
