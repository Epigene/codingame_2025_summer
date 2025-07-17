class Controller
  # @param my_id Integer
  # @param agents Hash<Agent>
  def initialize(my_id:, agents:)
    @my_id = my_id
    @agents = agents
  end

  # @return Array<String>
  def call(agent_update:, my_agent_count:)
    my_agent_count.times.map do
      # One line per agent: <agentId>;<action1;action2;...> actions are "MOVE x y | SHOOT id | THROW x y | HUNKER_DOWN | MESSAGE text"
      "HUNKER_DOWN"
    end
  end
end
