RSpec.describe Segment do
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
