# A smart wrapper for a cell in the grid.
class Cell
  attr_reader :xy, :cover, :grid, :cover_from

  def initialize(xy:, cover:, grid:, cover_from: {})
    @xy = xy
    @cover = cover
    @grid = grid
    @cover_from = cover_from
  end

  # @return nil # side-effects of changed #cover_from values
  def add_cover_from(cover_xy, cover_height=1)
    raise("Not neighbors!") unless grid.manhattan_distance(xy, cover_xy) == 1

    cells =
      case grid.direction(xy, cover_xy)
      when "S"
        min_y = cover_xy.y + 1
        grid.area(0..grid.max_x, min_y..grid.max_y)
      when "N"
        max_y = cover_xy.y - 1
        grid.area(0..grid.max_x, 0..max_y)
      when "E"
        min_x = cover_xy.x + 1
        grid.area(min_x..grid.max_x, 0..grid.max_y)
      when "W"
        max_x = cover_xy.x - 1
        grid.area(0..max_x, 0..grid.max_y)
      end

    cells -= grid.n8(cover_xy)

    cells.each do |cell|
      cover_from[cell] ||= cover_height
      cover_from[cell] = cover_height if cover_from[cell] < cover_height
    end

    nil
  end
end
