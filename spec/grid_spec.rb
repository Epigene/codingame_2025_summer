RSpec.describe Grid, instance_name: :grid do
  describe "#initialize(width, height, fill: false)" do
    subject(:new) { described_class.new(width, height) }

    context "when initialized with fill: true" do
      it "returns a grid with all cells built" do
        expect(described_class.new(2, 2, fill: true).nodes).to eq(["0 0", "1 0", "0 1", "1 1"])
      end
    end
  end

  describe "#add_cell(point, except: nil, only: nil, auto_trim: true)" do
    subject(:add_cell) { grid.add_cell(point, **options) }

    let(:options) { {} }

    context "when adding the single cell in a 1x1 grid" do
      let(:grid) { described_class.new(1, 1) }
      let(:point) { "0 0" }

      it "foregoes adding any neightbor cells as those are out of bounds" do
        expect{ add_cell }.to(
          change{ grid.nodes }.to(["0 0"])
        )

        expect(grid[point]).to be_empty
      end
    end

    context "when adding upper right cell in a 2x2 grid" do
      let(:grid) { described_class.new(2, 2) }
      let(:point) { "1 0" }

      it "trims the up and right neighbors as out of bounds" do
        expect{ add_cell }.to(
          change{ grid.nodes }.to(["1 0", "1 1", "0 0"])
        )

        expect(grid[point]).to eq(["0 0", "1 1"].to_set)
      end
    end
  end

  describe "#n8(point)" do
    subject(:n8) { grid.n8(point) }

    let(:grid) { described_class.new(3, 3) }

    context "when asking for neighbors of '0 0' upper left corner" do
      let(:point) { "0 0" }
      it { is_expected.to contain_exactly("1 0", "0 1", "1 1") }
    end

    context "when asking for neighbors of '1 0'" do
      let(:point) { "1 0" }
      it { is_expected.to contain_exactly("0 0", "0 1", "1 1", "2 1", "2 0") }
    end

    context "when asking for neighbors of '1 1' middle cell" do
      let(:point) { "1 1" }
      it { is_expected.to contain_exactly("0 0", "1 0", "2 0", "0 1", "2 1", "0 2", "1 2", "2 2") }
    end
  end

  describe "#manhattan_distance(pointA, pointB)" do
    let(:grid) do
      described_class.new(2, 2).tap do |g|
        g.add_cell("0 0")
        g.add_cell("1 1")
      end
    end

    it "returns the manhattan distance between cells" do
      expect(grid.manhattan_distance("0 0", "0 0")).to eq(0)
      expect(grid.manhattan_distance("0 0", "1 0")).to eq(1)
      expect(grid.manhattan_distance("0 0", "1 1")).to eq(2)
    end
  end
end
