debug "Game starts!"

# game loop
loop do
  agent_count = gets.to_i # Total number of agents still in the game
  agents = {}
  agent_count.times do
    # cooldown: Number of turns before this agent can shoot
    # wetness: Damage (0-100) this agent has taken
    line = gets
    debug line
    # agent_id, x, y, cooldown, splash_bombs, wetness = line.split.map { |x| x.to_i }
    agent_id = line.split.first.to_i
    agents[agent_id] = line
  end

  my_agent_count = gets.to_i # Number of alive agents controlled by you

  @controller.call(agent_update: agents, my_agent_count: my_agent_count).each do |move|
    puts move
  end
end
