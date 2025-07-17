class Controller
  # @param my_id Integer
  # @param agents Hash<Agent>
  # @param field String
  def initialize(my_id:, agents:, field:)
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
    ["1;MOVE 6 1", "2;MOVE 6 3"]
    # my_agent_count.times.map do
    #   # One line per agent: <agentId>;<action1;action2;...> actions are "MOVE x y | SHOOT id | THROW x y | HUNKER_DOWN | MESSAGE text"
    #   "HUNKER_DOWN"
    # end
  end
end
