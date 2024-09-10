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
end
