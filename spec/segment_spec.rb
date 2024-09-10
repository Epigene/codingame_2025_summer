RSpec.describe Segment do
  describe "#intersect?(other_segment)" do
    subject(:intersect?) { segment.intersect?(other_segment) }

    let(:segment) { described_class[Point[10, 10], Point[20, 10]] }

    context "when horizontal line is crossed by a vertical one" do
      let(:other_segment) { described_class[Point[15, 5], Point[15, 15]] }

      it { is_expected.to be(true) }
    end

    context "when horizontal line is crossed by a diagonal one" do
      let(:other_segment) { described_class[Point[9, 11], Point[21, 9]] }

      it { is_expected.to be(true) }
    end

    context "when one line starts on the other (1 shared vertex)" do
      let(:other_segment) { described_class[Point[11, 10], Point[11, 5]] }

      it { is_expected.to be(true) }
    end

    context "when both lines share a vertex (co-origin)" do
      let(:other_segment) { described_class[Point[10, 10], Point[11, 5]] }

      it { is_expected.to be(true) }
    end

    context "when both segments are on the same line, but do not overlap" do
      let(:other_segment) { described_class[Point[21, 10], Point[30, 10]] }

      it { is_expected.to be(false) }
    end

    context "when both segments are on parallel lines" do
      let(:other_segment) { described_class[Point[10, 11], Point[15, 11]] }

      it { is_expected.to be(false) }
    end

    context "when a horizontal line is not crossed by a vertical line further on" do
      let(:other_segment) { described_class[Point[21, 11], Point[21, 5]] }

      it { is_expected.to be(false) }
    end

    context "when a horizontal line is not crossed by a vertical line under it" do
      let(:other_segment) { described_class[Point[15, 9], Point[15, 5]] }

      it { is_expected.to be(false) }
    end
  end

  describe "#eight_sector_angle" do
    subject(:eight_sector_angle) { segment.eight_sector_angle }

    context "when the segment is pointing from 0 to 45 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[10, 9]] }

      it { is_expected.to eq(1) }
    end

    context "when the segment is pointing from 45 to 90 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[10, 11]] }

      it { is_expected.to eq(2) }
    end

    context "when the segment is pointing from 90 to 135 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[-1, 10]] }

      it { is_expected.to eq(3) }
    end

    context "when the segment is pointing from 135 to 180 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[-10, 1]] }

      it { is_expected.to eq(4) }
    end

    context "when the segment is pointing from 180 to 225 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[-10, -1]] }

      it { is_expected.to eq(5) }
    end

    context "when the segment is pointing from 225 to 270 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[-10, -11]] }

      it { is_expected.to eq(6) }
    end

    context "when the segment is pointing from 270 to 315 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[1, -10]] }

      it { is_expected.to eq(7) }
    end

    context "when the segment is pointing from 315 to 360 Deg" do
      let(:segment) { described_class[Point[0, 0], Point[10, -1]] }

      it { is_expected.to eq(8) }
    end
  end
end
