RSpec.describe Controller, instance_name: :controller do
  describe "#initialize" do
    subject(:controller) { described_class.new(surface) }

    # the example is of a simple 6-point surface where the landing site is inbetween two hills
    context "when given a simple surface, landing inbetween two hills" do
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

      it "initializes the surface visibility graph and detects landing segment" do
        expect(controller.landing_segment).to eq(Segment[Point[1000, 0], Point[2000,0]])

        expect(controller.visibility_graph["P[0, 0]"][:outgoing]).to contain_exactly("P[500, 100]")

        expect(controller.visibility_graph.dijkstra_shortest_path("P[0, 0]", "P[6999, 0]")).to eq(
          ["P[0, 0]", "P[500, 100]", "P[2500, 100]", "P[6999, 0]"]
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

        expect(controller.visibility_graph["P[0, 0]"][:outgoing]).to contain_exactly("P[4000, 2000]")
        expect(controller.visibility_graph["P[6999, 500]"][:outgoing]).to(
          contain_exactly("P[4000, 2000]", "P[3800, 1800]", "P[3800, 100]", "P[4800, 100]")
        )

        expect(controller.visibility_graph.dijkstra_shortest_path("P[0, 0]", "P[3800, 100]")).to eq(
          ["P[0, 0]", "P[4000, 2000]", "P[3800, 100]"]
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

        expect(controller.visibility_graph["P[0, 0]"][:outgoing]).to contain_exactly("P[2000, 2000]")
        expect(controller.visibility_graph["P[2000, 2000]"][:outgoing]).to(
          contain_exactly("P[0, 0]", "P[3000, 1900]", "P[4000, 2000]")
        )

        expect(controller.visibility_graph.dijkstra_shortest_path("P[0, 0]", "P[3500, 100]")).to eq(
          ["P[0, 0]", "P[2000, 2000]", "P[4000, 2000]", "P[4000, 1500]", "P[3500, 100]"]
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
        expect(call).to eq("30 4")

        expect(controller.visibility_graph["P[3000.0, 80.0]"][:outgoing]).to(
          contain_exactly("P[2500, 100]", "P[6999, 0]")
        )

        expect(controller.nodes_to_landing).to eq(["P[2500, 100]", "P[1000, 0]"])
      end
    end

    context "when initialized with A terrain and starting location" do
      let(:surface) do
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

      let(:line) { "6500 2600 -20 0 1000 45 0" }

      it "returns the immediate move and sets up path to landing" do
        expect(call).to eq("YAY")
      end
    end
  end
end
