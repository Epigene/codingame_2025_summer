# Encapsulates Splashing agent-related logic
class Agent
  attr_reader :id, :player, :optimal_range, :power, :bombs, :xy
  attr_accessor :cd, :bombs, :wetness

  # def initialize(id:, player:, cd:, optimal_range:, power:, bombs:)
  def initialize(line)
    @id, @player, @cd, @optimal_range, @power, @bombs = line.split.map { |x| x.to_i }

    # @id = id
    # @player = player
    # @cd = cd
    # @optimal_range = optimal_range
    # @power = power
    # @bombs = bombs
  end

  def assign_attributes(**attrs)
    attrs.each_pair do |k, v|
      send("#{k}=", v)
    end
  end

  def xy=(v)
    @xy = v
  end

  def x
    xy.x
  end

  def y
    xy.y
  end

  def range
    optimal_range
  end
end
