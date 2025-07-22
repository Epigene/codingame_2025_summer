RSpec.describe Grid, instance_name: :grid do
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
end
