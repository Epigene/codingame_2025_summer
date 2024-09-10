RSpec.describe Controller, instance_name: :controller do
  describe "#initialize" do
    subject(:controller) { described_class.new(surface) }

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

    # the example is of a simple 6-point surface where the landing site is inbetween two hills
    it "initializes the surface visibility graph and detects landing segment" do
      expect(controller.landing_segment).to eq(Segment[Point[1000, 0], Point[2000,0]])

      expect(controller.visibility_graph["P[0, 0]"][:outgoing]).to contain_exactly("P[500, 100]")

      expect(controller.visibility_graph.dijkstra_shortest_path("P[0, 0]", "P[6999, 0]")).to eq(
        ["P[0, 0]", "P[500, 100]", "P[2500, 100]", "P[6999, 0]"]
      )
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
  end
end
