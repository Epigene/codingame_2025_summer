# Encapsulates Splashing agent-related logic
class Agent
  attr_reader :id, :player, :cd, :optimal_range, :power, :bombs

  def initialize(id:, player:, cd:, optimal_range:, power:, bombs:)
    @id = id
    @player = player
    @cd = cd
    @optimal_range = optimal_range
    @power = power
    @bombs = bombs
  end
end
