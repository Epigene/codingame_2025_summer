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

  # Helper function to check if point p3 lies on line segment p1p2 (for collinear case)
  def on_segment?(p1, p2, p3)
    p3.x >= [p1.x, p2.x].min && p3.x <= [p1.x, p2.x].max &&
    p3.y >= [p1.y, p2.y].min && p3.y <= [p1.y, p2.y].max
  end

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
