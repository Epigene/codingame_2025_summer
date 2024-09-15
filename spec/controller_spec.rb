RSpec.describe Controller, instance_name: :controller do
  let(:test_case_A_surface) do
    [
      Point[0, 450],
      Point[300, 750],
      Point[1000, 450],
      Point[1500, 650],
      Point[1800, 850],
      Point[2000, 1950],
      Point[2200, 1850],
      Point[2400, 2000],
      Point[3100, 1800],
      Point[3150, 1550],
      Point[2500, 1600],
      Point[2200, 1550],
      Point[2100, 750],
      Point[2200, 150], # landing
      Point[3200, 150], # landing
      Point[3500, 450],
      Point[4000, 950],
      Point[4500, 1450],
      Point[5000, 1550],
      Point[5500, 1500],
      Point[6000, 950],
      Point[6999, 1750],
    ]
  end

  let(:test_case_B_surface) do
    [
      Point[0, 1800],
      Point[300, 1200],
      Point[1000, 1550],
      Point[2000, 1200],
      Point[2500, 1650],
      Point[3700, 220], # landing
      Point[4700, 220], # landing
      Point[4750, 1000],
      Point[4700, 1650],
      Point[4000, 1700],
      Point[3700, 1600], # curve spike above landing
      Point[3750, 1900], # curve hump 1
      Point[4000, 2100], # curve hump 2
      Point[4900, 2050], # curve hump 3
      Point[5100, 1000],
      Point[5500, 500],
      Point[6200, 800],
      Point[6999, 600]
    ]
  end

  # the example is of a simple 6-point surface where the landing site is inbetween two hills
  let(:simple_surface) do
    [
      Point[0, 0],
      Point[500, 100],
      Point[1000, 0], # landing
      Point[2000, 0], # landing
      Point[2500, 100],
      Point[6999, 0],
    ]
  end

  describe "#initialize" do
    subject(:controller) { described_class.new(surface) }

    context "when given a simple surface, landing inbetween two hills" do
      let(:surface) { simple_surface }

      it "initializes the surface visibility graph and detects landing segment" do
        expect(controller.landing_segment).to eq(Segment[Point[1000, 0], Point[2000,0]])

        expect(controller.visibility_graph[Point[0, 0]].keys).to contain_exactly(Point[500, 100])

        expect(controller.visibility_graph.dijkstra_shortest_path(Point[0, 0], Point[6999, 0])).to eq(
          [Point[0, 0], Point[500, 100], Point[2500, 100], Point[6999, 0]]
        )
      end
    end

    context "when given a tricky surface with a sharp overhang cliff" do
      let(:surface) do
        [
          Point[0, 0],
          Point[4000, 2000],
          Point[3800, 1800],
          Point[3800, 100],
          Point[4800, 100],
          Point[6999, 500]
        ]
      end

      it "initializes the surface visibility graph and detects landing segment", :aggregate_failures do
        expect(controller.landing_segment).to eq(Segment[Point[3800, 100], Point[4800, 100]])

        expect(controller.visibility_graph[Point[0, 0]].keys).to contain_exactly(Point[4000, 2000])
        expect(controller.visibility_graph[Point[6999, 500]].keys).to(
          contain_exactly(Point[4000, 2000], Point[3800, 1800], Point[3800, 100], Point[4800, 100])
        )

        expect(controller.visibility_graph.dijkstra_shortest_path(Point[0, 0], Point[3800, 100])).to eq(
          [Point[0, 0], Point[4000, 2000], Point[3800, 100]]
        )
      end
    end

    context "when given a tricky surface with blocky overhang" do
      let(:surface) do
        [
          Point[0, 0],
          Point[2000, 2000],
          Point[3000, 1900],
          Point[4000, 2000],
          Point[4000, 1500],
          Point[3500, 1500],
          Point[3500, 100],
          Point[4500, 100],
          Point[6999, 10],
        ]
      end

      it "initializes the surface visibility graph and detects landing segment", :aggregate_failures do
        expect(controller.landing_segment).to eq(Segment[Point[3500, 100], Point[4500, 100]])

        expect(controller.visibility_graph[Point[0, 0]].keys).to contain_exactly(Point[2000, 2000])
        expect(controller.visibility_graph[Point[2000, 2000]].keys).to(
          contain_exactly(Point[0, 0], Point[3000, 1900], Point[4000, 2000])
        )

        expect(controller.visibility_graph.dijkstra_shortest_path(Point[0, 0], Point[3500, 100])).to eq(
          [Point[0, 0], Point[2000, 2000], Point[4000, 2000], Point[4000, 1500], Point[3500, 100]]
        )
      end
    end

    context "when given a sneaky surface with points resulting in a straight-line terrain" do
      let(:surface) do
        [
          Point[0, 0],
          Point[100, 100], # redundant because subsumed under neighbors
          Point[200, 200],
          Point[1000, 1200], # landing
          Point[2000, 1200], # landing
          Point[3000, 950], # redundant because subsumed
          Point[4000, 700], # redundant because subsumed
          Point[6000, 200],
          Point[6999, 0],
        ]
      end

      it "discards the excess points and initializes a simpler surface visibility graph" do
        expect(controller.landing_segment).to eq(Segment[Point[1000, 1200], Point[2000, 1200]])

        expect(controller.visibility_graph[Point[0, 0]].keys).to contain_exactly(Point[200, 200], Point[1000, 1200])

        expect(controller.visibility_graph.dijkstra_shortest_path(Point[0, 0], Point[6999, 0])).to eq(
          [Point[0, 0], Point[1000, 1200], Point[2000, 1200], Point[6999, 0]]
        )
      end
    end
  end

  describe "#call(line)" do
    subject(:call) { controller.call(line) }

    let(:controller) { described_class.new(surface) }

    context "when initialized with simple two-hill surface and turn info" do
      let(:surface) do
        [
          Point[0, 0],
          Point[500, 100],
          Point[1000, 0],
          Point[2000, 0],
          Point[2500, 100],
          Point[6999, 0],
        ]
      end

      let(:line) { "3000 80 0 4 5000 45 0" }

      it "returns the immediate comand, and sets a long-term node-path to landing" do
        expect(call).to eq("22 4")

        expect(controller.visibility_graph[Point[3000.0, 80.0]].keys).to(
          contain_exactly(Point[2500, 100], Point[6999, 0])
        )

        expect(controller.nodes_to_landing).to eq([Point[2500, 100], Point[1000, 0]])
      end
    end

    context "when initialized with test case A terrain and starting location" do
      let(:surface) { test_case_A_surface }

      let(:line) { "6500 2600 -20 0 1000 45 0" }

      it "returns the immediate move and sets up path to landing" do
        expect(call).to eq("45 4")

        expect(controller.nodes_to_landing).to eq([Point[2200, 150]])
      end
    end

    context "when initialized with test case A terrain in the rightmost canyon" do
      let(:surface) { test_case_A_surface }

      let(:line) { "6000, 1000 -57 -8 846 -7 4" }

      it "returns immediate move and calculates nodes_to_landing" do
        expect(call).to eq("-22 4")

        expect(controller.nodes_to_landing).to eq(
          [Point[5500, 1500], Point[5000, 1550], Point[4500, 1450], Point[2200, 150]]
        )
      end
    end

    context "when initialized with test case A terrain just outside and to the left of the the rightmost canyon" do
      let(:surface) { test_case_A_surface }

      let(:line) { "5500, 1501 0 0 846 -7 4" }
      let(:original_spawn_line) { "6000, 1000 -57 -8 846 -7 4" }

      before do
        controller.call(original_spawn_line)
      end

      it "returns immediate move and drops the P[5500, 1500] node from :nodes_to_landing as reached because lander can see the next node" do
        expect(call).to eq("22 4")

        expect(controller.nodes_to_landing).to eq(
          [Point[5000, 1550], Point[4500, 1450], Point[2200, 150]]
        )
      end
    end

    context "when initialized with test case A surface and should start lowering (inertia 5 to direction 6)" do
      let(:surface) { test_case_A_surface }

      let(:line) { "4148 2252 -66 -7 826 -7 4" }
      let(:original_spawn_line) { "6500 2600 -20 0 1000 45 0" }

      before do
        controller.call(original_spawn_line)
      end

      it "returns immediate move to shut off engines and get more positive Y (falling from gravity)" do
        expect(call).to eq("-60 4")
      end
    end

    context "when initialized with simple surface and needing to go exactly left" do
      let(:surface) { simple_surface }

      # Point[0, 0],
      # Point[500, 100],
      # Point[1000, 0], # landing
      # Point[2000, 0], # landing
      # Point[2500, 100],
      # Point[6999, 0],

      let(:line) { "2550 100 0 0 1200 0 0" }

      it "returns the immediate move and planned route looping around curved surface" do
        expect(call).to eq("45 4")

        expect(controller.nodes_to_landing).to eq(
          [Point[2500, 100], Point[2000, 0]]
        )
      end
    end
  end
end
