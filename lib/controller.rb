class Controller
  attr_reader :my_id, :agents, :field, :cells, :turn

  # @param my_id Integer
  # @param agents Hash<Agent>
  # @param field String
  def initialize(my_id:, agents:, field:)
    @turn = 0
    @my_id = my_id
    @agents = agents
    init_field(field)
  end

  # @return Array<String>
  def call(agent_update:, my_agent_count:)
    @turn += 1
    @agent_update = agent_update
    @my_agent_count = my_agent_count

    set_agent_data!

    my_agents.map do |agent|
      if opp_agents.any?
        "#{agent.id};SHOOT #{opp_agents_by_wetness.first.id}"
      else
        "#{agent.id};HUNKER_DOWN"
      end
    end

    # One line per agent: <agentId>;<action1;action2;...>
    # actions are "MOVE x y | SHOOT id | THROW x y | HUNKER_DOWN | MESSAGE text"
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

  # sets @field and @cells
  def init_field(field)
    lines = field.split("\n")
    grid = Grid.new(_width = lines.first.split.size / 3, _height = lines.size)
    @cells = {}

    lines.each do |line|
      inputs = line.split

      inputs.each_slice(3) do |x, y, cover_height|
        @cells["#{x} #{y}"] = cover_height.to_i
        grid.add_cell("#{x} #{y}") if cover_height.to_i.zero?
      end
    end

    @cells.each_pair do |point, cover_height|
      grid.remove_cells([point]) unless cover_height.zero?
    end

    @field = grid
  end
end
