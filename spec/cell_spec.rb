RSpec.describe Cell, instance_name: :cell do
  describe "#add_cover_from(cover_xy, cover_height=1)" do
    subject(:add_cover) { cell.add_cover_from(cover_xy) }

    let(:grid) { Grid.new(5, 5) }

    context "when cover to S of cell" do
      let(:cell) { described_class.new(xy: "2 0", cover: 0, grid: grid) }
      let(:cover_xy) { "2 1" }

      it "updates the cell's #cover_from values" do
        expect{ add_cover }.to(
          change{ cell.cover_from }.to(
            "0 2" => 1, "4 2" => 1,
            "0 3" => 1, "1 3" => 1, "2 3" => 1, "3 3" => 1, "4 3" => 1,
            "0 4" => 1, "1 4" => 1, "2 4" => 1, "3 4" => 1, "4 4" => 1
          )
        )
      end
    end

    context "when cover to E of cell" do
      let(:cell) { described_class.new(xy: "1 2", cover: 0, grid: grid) }
      let(:cover_xy) { "2 2" }

      it "updates the cell's #cover_from values" do
        expect{ add_cover }.to(
          change{ cell.cover_from }.to(
            "3 0" => 1, "3 4" => 1,
            "4 0" => 1, "4 1" => 1, "4 2" => 1, "4 3" => 1, "4 4" => 1
          )
        )
      end
    end

    context "when cover to N and W of cell" do
      let(:cell) { described_class.new(xy: "3 3", cover: 0, grid: grid) }

      it "updates the cell's #cover_from values, preferring higher cover value where overlap" do
        expect do
          cell.add_cover_from("3 2", 1) # N
          cell.add_cover_from("2 3", 2) # W
        end.to(
          change{ cell.cover_from }.to(
            "2 0" => 1, "3 0" => 1, "4 0" => 1,
            "0 0" => 2, "1 0" => 2,
            "0 1" => 2, "1 1" => 2,
            "0 2" => 2, "0 3" => 2, "0 4" => 2
          )
        )
      end
    end

    context "when cover to W, from wood2 arena" do
      let(:grid) { Grid.new(13, 5) }
      let(:cell) { described_class.new(xy: "12 1", cover: 0, grid: grid) }
      let(:cover_xy) { "11 1" }

      it "updates the cell to have massive cover" do
        expect{ add_cover }.to(
          change{ cell.cover_from }.to(
            hash_including("8 1" => 1, "10 3" => 1)
          )
        )
      end
    end
  end
end
