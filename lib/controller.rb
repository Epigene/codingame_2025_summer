class Controller
  attr_reader :my_id, :agents, :field, :turn

  # @param my_id Integer
  # @param agents Hash<Agent>
  # @param field String
  def initialize(my_id:, agents:, field:)
    @turn = 0
    @my_id = my_id
    @agents = agents
    @field = "TODO"

    # inputs = line.split

    # for j in 0..(width-1)
    #   # x: X coordinate, 0 is left edge
    #   # y: Y coordinate, 0 is top edge
    #   x = inputs[3*j].to_i
    #   y = inputs[3*j+1].to_i
    #   tile_type = inputs[3*j+2].to_i
    # end
  end

  # @return Array<String>
  def call(agent_update:, my_agent_count:)
    @turn += 1
    @agent_update = agent_update
    @my_agent_count = my_agent_count

    set_agent_data!

    # ["1;MOVE 6 1", "2;MOVE 6 3"]

    my_agents.map do |agent|
      if opp_agents.any?
        "#{agent.id};SHOOT #{opp_agents_by_wetness.first.id}"
      else
        "#{agent.id};HUNKER_DOWN"
      end
    end
    # my_agent_count.times.map do
    #   # One line per agent: <agentId>;<action1;action2;...> actions are "MOVE x y | SHOOT id | THROW x y | HUNKER_DOWN | MESSAGE text"
    #   "HUNKER_DOWN"
    # end
  end

  private

  attr_reader :agent_update, :my_agent_count

  def my_agents
    my_agents ||= {}
    my_agents[turn] ||= agents.filter_map { |id, agent| agent.player == my_id ? agent : nil }
  end

  def opp_agents
    opp_agents ||= {}
    opp_agents[turn] ||= agents.filter_map { |id, agent| agent.player != my_id ? agent : nil }
  end

  # @return Array<Agent> # ordered descending, most wet first
  def opp_agents_by_wetness
    opp_agents_by_wetness ||= {}
    opp_agents_by_wetness[turn] ||= opp_agents.sort_by { |agent| -agent.wetness }
  end

  def set_agent_data!
    agent_update.transform_values! do |line|
      agent_id, x, y, cd, bombs, wetness = line.split.map { |x| x.to_i }

      agent = agents[agent_id]

      agent.assign_attributes(
        xy: "#{x} #{y}",
        cd: cd,
        bombs: bombs,
        wetness: wetness
      )

      agent
    end

    @agents = agent_update

    nil
  end
end
