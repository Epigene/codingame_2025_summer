RSpec.describe Controller, instance_name: :controller do
  let(:controller) { described_class.new }

  describe "#call(n)" do
    subject(:call) { controller.call(n) }

    context "when n is 1" do
      let(:n) { 1 }

      it { is_expected.to eq(0) }
    end

    context "when n is 2" do
      let(:n) { 2 }

      it { is_expected.to eq(0) }
    end

    context "when n is 3" do
      let(:n) { 3 }

      it { is_expected.to eq(1) }
    end

    context "when n is 4" do
      let(:n) { 4 }

      it { is_expected.to eq(1) }
    end

    context "when n is 5" do
      let(:n) { 5 }

      it { is_expected.to eq(2) }
    end

    context "when n is 6" do
      let(:n) { 6 }

      it { is_expected.to eq(3) }
    end

    context "when n is 10" do
      let(:n) { 10 }

      it { is_expected.to eq(9) }
    end

    context "when n is 12" do
      let(:n) { 12 }

      it { is_expected.to eq(14) }
    end

    context "when n is 14, a special case where it's 1 shy from a full 5-column stair, so has 4 'excess' bricks" do
      let(:n) { 14 }

      it { is_expected.to eq(21) }
    end

    context "when n is 25" do
      let(:n) { 25 }

      it { is_expected.to eq(141) }
    end

    context "when n is 27" do
      let(:n) { 27 }

      it { is_expected.to eq(191) }
    end

    context "when n is 70" do
      let(:n) { 70 }

      it { is_expected.to eq(29926) }
    end

    context "when n is 90" do
      let(:n) { 90 }

      # ORIG time | 3.01 seconds (files took 0.23623 seconds to load)
      # with combined last two column combo counting | 1.17 seconds (files took 0.23095 seconds to load)
      # stop dupping steps array | 0.80186 seconds (files took 0.22733 seconds to load)
      # with quick-step in level increase | 0.7528 seconds (files took 0.22712 seconds to load)
      it { is_expected.to eq(189585) }
    end

    context "when n is 100" do
      let(:n) { 100 }

      # ORIG time (with quick-step in level) | 1.75 seconds (files took 0.22669 seconds to load)
      # in-place step mod 1 | 1.68 seconds (files took 0.22725 seconds to load)
      # in-place step mod 2 | 1.55 seconds (files took 0.22722 seconds to load)
      # without debug output | 0.48621 seconds (files took 0.2342 seconds to load)
      it { is_expected.to eq(444792) }
    end

    context "when n is 120" do
      let(:n) { 120 }

      # without debug output | 2.34 seconds (files took 0.23288 seconds to load)
      it { is_expected.to eq(2_194_431) }
    end

    context "when n is 500" do
      let(:n) { 500 }

      it { is_expected.to eq(732_986_521_245_023) }
    end
  end

  describe "#steps_in_n_columns(steps, columns)" do
    subject(:steps_in_n_columns) { controller.steps_in_n_columns(steps, columns) }

    context "when given a simple mini-case" do
      let(:steps) { [1, 2] }
      let(:columns) { 2 }

      it { is_expected.to eq(1) }
    end

    context "when given an end-game case with last column having excess" do
      let(:steps) { [1, 6] }
      let(:columns) { 2 }

      it { is_expected.to eq(3) }
    end

    context "when given an end-game case with last column having excess" do
      let(:steps) { [1, 7] }
      let(:columns) { 2 }

      it { is_expected.to eq(3) }
    end

    context "when given an end-game case with last column having excess" do
      let(:steps) { [5, 6] }
      let(:columns) { 2 }

      it { is_expected.to eq(1) }
    end

    context "when given an mid-game case with last column having no excess" do
      let(:steps) { [1, 2, 3] }
      let(:columns) { 3 }

      it { is_expected.to eq(1) }
    end

    context "when given an mid-game case with last column having excess" do
      let(:steps) { [1, 2, 7] }
      let(:columns) { 3 }

      it { is_expected.to eq(4) }
    end

    context "when given an early-game case with last column having a large excess" do
      let(:steps) { [1, 2, 15] }
      let(:columns) { 3 }

      it { is_expected.to eq(19) }
    end
  end

  describe "#non_decreasing_partitions_v2(n, c)" do
    subject(:non_decreasing_partitions_v2) { controller.non_decreasing_partitions_v2(*args) }

    context "when asked to put 4 bricks in 4 columns in a non-decreasing way" do
      let(:args) { [4, 4] }

      it { is_expected.to eq(5) }
    end

    context "when asked to put 3 bricks in 2 columns in a non-decreasing way" do
      let(:args) { [3, 2] }

      it { is_expected.to eq(2) }
    end

    context "when asked to put 5 bricks in 3 columns in a non-decreasing way" do
      let(:args) { [5, 3] }

      it { is_expected.to eq(5) }
    end

    context "when asked to put 5 bricks in 5 columns in a non-decreasing way" do
      let(:args) { [5, 5] }

      it { is_expected.to eq(7) }
    end

    context "when asked to put 500 bricks in 3 columns in a non-decreasing way" do
      let(:args) { [500, 3] }

      it { is_expected.to eq(21084) }
    end
  end

  describe "#unique_partitions(n, c)" do
    subject(:unique_partitions) { controller.unique_partitions(*args) }

    context "when asked to put 4 bricks in exactly 1 columns" do
      let(:args) { [4, 1] }

      it { is_expected.to eq(1) }
    end

    context "when asked to put 4 bricks in exactly 2 columns" do
      let(:args) { [4, 2] }

      it { is_expected.to eq(2) }
    end

    context "when asked to put 4 bricks in exactly 3 columns" do
      let(:args) { [4, 3] }

      it { is_expected.to eq(1) }
    end

    context "when asked to put 4 bricks in exactly 4 columns" do
      let(:args) { [4, 4] }

      it { is_expected.to eq(1) }
    end

    context "when asked to put 3 bricks in exactly 2 columns" do
      let(:args) { [3, 2] }

      it { is_expected.to eq(1) }
    end

    context "when asked to put 4 bricks in exactly 3 columns" do
      let(:args) { [4, 3] }

      it { is_expected.to eq(1) }
    end

    context "when asked to put 1 brick in exactly 2 columns" do
      let(:args) { [1, 2] }

      it { is_expected.to eq(0) }
    end
  end
end
