# Put the one-time game setup code that comes before `loop do` here.

# == GAME INIT ==
my_id = gets.to_i # Your player id (0 or 1)
debug "My id: #{my_id}"
agent_data_count = gets.to_i # Total number of agents in the game
agents = {}
agent_data_count.times do
  # agent_id: Unique identifier for this agent
  # player: Player id of this agent
  # shoot_cooldown: Number of turns between each of this agent's shots
  # optimal_range: Maximum manhattan distance for greatest damage output
  # soaking_power: Damage output within optimal conditions
  # splash_bombs: Number of splash bombs this can throw this game
  line = gets
  debug line
  # agent_id, player, shoot_cooldown, optimal_range, soaking_power, splash_bombs = line.split.map { |x| x.to_i }
  # agents[agent_id] = Agent.new(
  #   id: agent_id,
  #   player: player,
  #   cd: shoot_cooldown,
  #   optimal_range: optimal_range,
  #   power: soaking_power,
  #   bombs: splash_bombs
  # )
  agent_id = line.split.first.to_i
  agents[agent_id] = Agent.new(line)
end

# width: Width of the game map
# height: Height of the game map
width, height = gets.split.map(&:to_i)
field_lines = []
height.times do
  line = gets
  debug line
  field_lines << line
end
field = field_lines.join("\n")

@controller = Controller.new(my_id: my_id, agents: agents, field: field)
