class Controller
  BOMB_RANGE = 4
  MINIMUM_CLUSTER_SIZE = 5 # 7 is better because ensures full 3x3 coverāž
  attr_reader :my_id, :agents, :grid, :cells, :turn, :opp_clusers

  # @param my_id Integer
  # @param agents Hash<Agent>
  # @param field String
  def initialize(my_id:, agents:, field:)
    @turn = 0
    @my_id = my_id
    @agents = agents
    init_grid(field)
  end

  # @return Array<String>
  def call(agent_update:, my_agent_count:)
    @turn += 1
    @agent_update = agent_update
    @my_agent_count = my_agent_count

    set_agent_data!
    set_opp_clusers!

    my_agents.map do |agent|
      if opp_agents.any?
        if agent.id == 1 && agent.bombs.positive? && opp_clusers.any? # && # IF I CAN NADE A CLUSER
          clusters = opp_clusers.sort_by { |xy, opps| [grid.manhattan_distance(xy, agent.xy), -opps] }
          debug clusters
          closest_cluster = clusters.first.first
          distance = grid.manhattan_distance(closest_cluster, agent.xy)

          if distance <= BOMB_RANGE
            "#{agent.id}; THROW #{closest_cluster}"
          elsif distance == BOMB_RANGE + 1
            "#{agent.id}; MOVE #{closest_cluster}; THROW #{closest_cluster}"
          else # move towards
            "#{agent.id}; MOVE #{closest_cluster}"
          end
        else
          "#{agent.id}; HUNKER_DOWN"
        #== ˇ Old good logic below, enable in bronze ˇ

        # elsif (opps = in_opp_range(agent.xy)).any?
        #   nearby_cover =
        #     grid.neighbors(agent.xy).find { |ne| cells[ne].cover_from[opps.first.xy] == 2 } ||
        #     grid.neighbors(agent.xy).find { |ne| cells[ne].cover_from[opps.first.xy] == 1 }

        #   agents_in_range = opp_agents_in_range(agent.xy, agent.range)
        #   target = opp_agents_by_cover(agent.xy).select { |opp| agents_in_range.include?(opp) }.first

        #   "#{agent.id}; MOVE #{nearby_cover}; SHOOT #{target.id}"
        # else # nobody can shoot me, do other stuff
        #   "#{agent.id}; SHOOT #{opp_agents_by_wetness.first.id}; MESSAGE I'm untouchable!"
        end
      else
        "#{agent.id}; HUNKER_DOWN"
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

  # exposed first
  def opp_agents_by_cover(from_xy)
    opp_agents.sort_by { |agent| cells[agent.xy].cover_from[from_xy].to_i }
  end

  # Flipside of #opp_agents_in_range
  # @return Array<Agent>
  def in_opp_range(xy)
    opp_agents.select { grid.manhattan_distance(xy, _1.xy) <= _1.optimal_range }
  end

  # Flipside of #in_opp_range
  # @return Array<Agent>
  def opp_agents_in_range(of_xy, range)
    opp_agents.select { grid.manhattan_distance(of_xy, _1.xy) <= range }
  end

  ## Deep setup below ##

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

  # sets @grid and @cells
  def init_grid(field)
    lines = field.split("\n")
    grid = Grid.new(_width = lines.first.split.size / 3, _height = lines.size)
    @cells = {}

    lines.each do |line|
      inputs = line.split

      inputs.each_slice(3) do |x, y, cover_height|
        cells["#{x} #{y}"] = Cell.new(xy: "#{x} #{y}", cover: cover_height.to_i, grid: grid)
        grid.add_cell("#{x} #{y}") if cover_height.to_i.zero?
      end
    end

    cells.each_pair do |point, cell|
      grid.n4(point).each do |neighbor|
        next if cells[neighbor].cover.zero?

        cells[point].add_cover_from(neighbor, cells[neighbor].cover)
      end

      grid.remove_cells([point]) unless cell.cover.zero?
    end

    @grid = grid
  end

  # sets @opp_clusers
  def set_opp_clusers!
    clusters = {}
    agent_coords = my_agents.map { _1.xy }.to_set
    opp_agent_coords = opp_agents.map { _1.xy }.to_set
    claimed = {}
    candidates = []

    # First pass: gather all 3x3 clusters with counts
    (0..(grid.max_x - 2)).each do |i|
      (0..(grid.max_y - 2)).each do |j|
        cells = []
        count = 0
        blocked = false

        (i..i + 2).each do |x|
          (j..j + 2).each do |y|
            xy = "#{x} #{y}"
            cells << xy

            if agent_coords.include?(xy)
              blocked = true
              break
            end

            count += 1 if opp_agent_coords.include?(xy)
          end
          break if blocked
        end

        next if blocked
        next if count < MINIMUM_CLUSTER_SIZE

        candidates << { center: "#{i + 1} #{j + 1}", count: count, cells: cells }
      end
    end

    # Second pass: sort by descending count and pick non-overlapping clusters
    candidates.sort_by! { |c| -c[:count] }

    candidates.each do |cand|
      # Skip if any cell is already claimed
      next if cand[:cells].any? { |xy| claimed[xy].to_i > cand[:count] }

      # Accept this cluster
      clusters[cand[:center]] = cand[:count]

      # Mark all its cells as claimed
      cand[:cells].each { |xy| claimed[xy] = cand[:count] }
    end

    @opp_clusers = clusters
  end
end
