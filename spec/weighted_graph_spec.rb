RSpec.describe WeightedGraph, instance_name: :graph do
  let(:graph) { described_class.new }

  describe "#dijkstra_shortest_path(root, destination)" do
    subject(:dijkstra_shortest_path) { graph.dijkstra_shortest_path(root, destination) }

    context "when given a simple trinagle graph with short AB BA and long AC" do
      let(:root) { "A" }
      let(:destination) { "C" }

      before do
        graph.connect_nodes("A", "B", 1)
        graph.connect_nodes("B", "C", 2)
        graph.connect_nodes("A", "C", 10)
      end

      it "returns the correct two-node, but shorther-path route" do
        is_expected.to eq(["A", "B", "C"])
      end
    end

    context "when paths are equidistant" do
      let(:root) { "A" }
      let(:destination) { "C" }

      before do
        graph.connect_nodes("A", "B", 1)
        graph.connect_nodes("B", "C", 1)
        graph.connect_nodes("A", "C", 2)
      end

      it "returns the one that happens to be initialized first" do
        is_expected.to eq(["A", "C"])
      end
    end
  end
end
