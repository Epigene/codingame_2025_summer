RSpec.describe Controller, instance_name: :controller do
  describe "#call(agent_update:, my_agent_count:)" do
    subject(:call) { controller.call(agent_update: update, my_agent_count: 2) }

    let(:controller) { described_class.new(my_id: my_id, agents: agents, field: field) }
    let(:my_id) { 0 }

    let(:empty_field) do
      <<~FIELD
        0 0 0 1 0 0 2 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0
        0 1 0 1 1 0 2 1 0 3 1 0 4 1 0 5 1 0 6 1 0 7 1 0
        0 2 0 1 2 0 2 2 0 3 2 0 4 2 0 5 2 0 6 2 0 7 2 0
        0 3 0 1 3 0 2 3 0 3 3 0 4 3 0 5 3 0 6 3 0 7 3 0
        0 4 0 1 4 0 2 4 0 3 4 0 4 4 0 5 4 0 6 4 0 7 4 0
      FIELD
    end

    context "when ??" do
      let(:agents) do
        {
          1 => Agent.new("1 0 0 6 50 0"),
          2 => Agent.new("2 0 0 6 50 0")
        }
      end

      let(:field) do
        <<~FIELD
          0 0 0 1 0 0 2 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0
          ...
        FIELD
      end

      let(:update) do
        {
          1 => "1 0 0 0 0 0",
          2 => "2 0 4 0 0 0"
        }
      end

      xit "returns moves TODO" do
        is_expected.to eq(
          ["TODO1", "TODO2"]
        )
      end
    end

    context "when initialized with wood 4 starting setup" do
      let(:agents) do
        {
          1 => Agent.new("1 0 0 6 24 0"),
          2 => Agent.new("2 0 0 6 24 0")
        }
      end

      let(:field) { empty_field }

      let(:update) do
        {
          1 => "1 0 0 0 0 0",
          2 => "2 0 4 0 0 0"
        }
      end

      xit "returns moves for both agents" do
        is_expected.to eq(
          ["1;MOVE 6 1", "2;MOVE 6 3"]
        )
      end
    end

    context "when initialized with wood 3 starting setup" do
      let(:agents) do
        {
          1 => Agent.new("1 0 0 6 50 0"),
          2 => Agent.new("2 0 0 6 50 0"),
          3 => Agent.new("3 1 0 6 100 0"),
          4 => Agent.new("4 1 0 6 100 0"),
          5 => Agent.new("5 1 0 6 100 0"),
          6 => Agent.new("6 1 0 6 100 0")
        }
      end

      let(:field) { empty_field }

      let(:update) do
        {
          1 => "1 3 2 0 0 0",
          2 => "2 4 2 0 0 0",
          3 => "3 5 3 0 0 60",
          4 => "4 5 1 0 0 70",
          5 => "5 2 1 0 0 90",
          6 => "6 2 3 0 0 80",
        }
      end

      xit "returns commands to shoot at agent 5, the wettest one" do
        is_expected.to eq(["1;SHOOT 5", "2;SHOOT 5"])
      end
    end

    context "when initialized with wood 2 starting setup" do
      let(:agents) do
        {
          1 => Agent.new("1 0 0 6 50 0"),
          2 => Agent.new("2 0 0 6 50 0"),
          3 => Agent.new("3 1 0 6 100 0"),
          4 => Agent.new("4 1 0 6 100 0"),
          5 => Agent.new("5 1 0 6 100 0"),
          6 => Agent.new("6 1 0 6 100 0")
        }
      end

      let(:field) do
        <<~FIELD.chomp
          0 0 0 1 0 0 2 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0 8 0 0 9 0 0 10 0 0 11 0 0 12 0 0
          0 1 0 1 1 2 2 1 0 3 1 1 4 1 0 5 1 0 6 1 2 7 1 0 8 1 0 9 1 2 10 1 0 11 1 2 12 1 0
          0 2 0 1 2 0 2 2 0 3 2 0 4 2 2 5 2 0 6 2 0 7 2 0 8 2 1 9 2 0 10 2 0 11 2 0 12 2 0
          0 3 0 1 3 1 2 3 0 3 3 2 4 3 0 5 3 0 6 3 2 7 3 0 8 3 0 9 3 1 10 3 0 11 3 1 12 3 0
          0 4 0 1 4 0 2 4 0 3 4 0 4 4 1 5 4 0 6 4 0 7 4 0 8 4 2 9 4 0 10 4 0 11 4 0 12 4 0
        FIELD
      end

      let(:update) do
        {
          1 => "1 0 2 0 0 0",
          2 => "2 12 2 0 0 0",
          3 => "3 4 1 0 0 0",
          4 => "4 4 3 0 0 0",
          5 => "5 8 1 0 0 0",
          6 => "6 8 3 0 0 0"
        }
      end

      it "returns moves to get to cover and shoot" do
        is_expected.to eq(
          ["1; MOVE 0 1; SHOOT 3", "2; MOVE 12 1; SHOOT 6"]
        )
      end
    end

    context "when initialized with wood 1 starting setup for nading groups (seed=-2340371910410667500)" do
      let(:agents) do
        {
          1 => Agent.new("1 0 0 1 10 3"),
          2 => Agent.new("2 0 0 1 10 1"),
          3 => Agent.new("3 1 0 64 200 0"),
          4 => Agent.new("4 1 0 64 200 0"),
          5 => Agent.new("5 1 0 64 200 0"),
          6 => Agent.new("6 1 0 64 200 0"),
          7 => Agent.new("7 1 0 64 200 0"),
          8 => Agent.new("8 1 0 64 200 0"),
          9 => Agent.new("9 1 0 64 200 0"),
          10 => Agent.new("10 1 0 64 200 0"),
          11 => Agent.new("11 1 0 64 200 0"),
          12 => Agent.new("12 1 0 64 200 0"),
          13 => Agent.new("13 1 0 64 200 0"),
          14 => Agent.new("14 1 0 64 200 0"),
          15 => Agent.new("15 1 0 64 200 0"),
          16 => Agent.new("16 1 0 64 200 0"),
          17 => Agent.new("17 1 0 64 200 0"),
          18 => Agent.new("18 1 0 64 200 0"),
          19 => Agent.new("19 1 0 64 200 0"),
          20 => Agent.new("20 1 0 64 200 0"),
          21 => Agent.new("21 1 0 64 200 0"),
          22 => Agent.new("22 1 0 64 200 0"),
          23 => Agent.new("23 1 0 64 200 0"),
          24 => Agent.new("24 1 0 64 200 0"),
          25 => Agent.new("25 1 0 64 200 0"),
          26 => Agent.new("26 1 0 64 200 0"),
          27 => Agent.new("27 1 0 64 200 0"),
          28 => Agent.new("28 1 0 64 200 0"),
          29 => Agent.new("29 1 0 64 200 0")
        }
      end

      let(:field) do
        <<~FIELD
          0 0 2 1 0 2 2 0 2 3 0 2 4 0 2 5 0 0 6 0 0 7 0 0 8 0 0 9 0 0 10 0 2 11 0 2 12 0 2 13 0 2 14 0 2
          0 1 2 1 1 0 2 1 0 3 1 0 4 1 2 5 1 0 6 1 0 7 1 0 8 1 0 9 1 0 10 1 2 11 1 0 12 1 0 13 1 0 14 1 2
          0 2 2 1 2 0 2 2 0 3 2 0 4 2 2 5 2 0 6 2 0 7 2 0 8 2 0 9 2 0 10 2 2 11 2 0 12 2 0 13 2 0 14 2 2
          0 3 2 1 3 0 2 3 0 3 3 0 4 3 2 5 3 0 6 3 0 7 3 0 8 3 0 9 3 0 10 3 2 11 3 0 12 3 0 13 3 0 14 3 2
          0 4 2 1 4 2 2 4 2 3 4 2 4 4 2 5 4 0 6 4 0 7 4 0 8 4 0 9 4 0 10 4 2 11 4 2 12 4 2 13 4 2 14 4 2
          0 5 0 1 5 0 2 5 0 3 5 0 4 5 0 5 5 0 6 5 0 7 5 0 8 5 0 9 5 0 10 5 0 11 5 0 12 5 0 13 5 0 14 5 0
          0 6 0 1 6 0 2 6 0 3 6 0 4 6 0 5 6 0 6 6 0 7 6 0 8 6 0 9 6 0 10 6 0 11 6 0 12 6 0 13 6 0 14 6 0
          0 7 2 1 7 2 2 7 2 3 7 2 4 7 2 5 7 0 6 7 0 7 7 0 8 7 0 9 7 0 10 7 2 11 7 2 12 7 2 13 7 2 14 7 2
          0 8 2 1 8 0 2 8 0 3 8 0 4 8 2 5 8 0 6 8 0 7 8 0 8 8 0 9 8 0 10 8 2 11 8 0 12 8 0 13 8 0 14 8 2
          0 9 2 1 9 0 2 9 0 3 9 0 4 9 2 5 9 0 6 9 0 7 9 0 8 9 0 9 9 0 10 9 2 11 9 0 12 9 0 13 9 0 14 9 2
          0 10 2 1 10 0 2 10 0 3 10 0 4 10 2 5 10 0 6 10 0 7 10 0 8 10 0 9 10 0 10 10 2 11 10 0 12 10 0 13 10 0 14 10 2
          0 11 2 1 11 2 2 11 2 3 11 2 4 11 2 5 11 0 6 11 0 7 11 0 8 11 0 9 11 0 10 11 2 11 11 2 12 11 2 13 11 2 14 11 2
        FIELD
      end

      let(:update) do
        {
          1 => "1 7 6 0 3 70", # 3 bombs, yay
          2 => "2 2 2 0 1 70",
          3 => "3 2 1 0 0 70",
          4 => "4 2 3 0 0 70",
          5 => "5 3 2 0 0 70",
          6 => "6 3 1 0 0 70",
          7 => "7 1 9 0 0 70",
          8 => "8 1 8 0 0 70",
          9 => "9 1 10 0 0 70",
          10 => "10 2 9 0 0 70",
          11 => "11 2 8 0 0 70",
          12 => "12 2 10 0 0 70",
          13 => "13 3 9 0 0 70",
          14 => "14 13 1 0 0 70",
          15 => "15 13 3 0 0 70",
          16 => "16 13 2 0 0 70",
          17 => "17 11 1 0 0 70",
          18 => "18 11 3 0 0 70",
          19 => "19 11 2 0 0 70",
          20 => "20 12 1 0 0 70",
          21 => "21 13 9 0 0 70",
          22 => "22 13 8 0 0 70",
          23 => "23 13 10 0 0 70",
          24 => "24 12 9 0 0 70",
          25 => "25 12 8 0 0 70",
          26 => "26 12 10 0 0 70",
          27 => "27 11 9 0 0 70",
          28 => "28 11 8 0 0 70",
          29 => "29 11 10 0 0 70",
        }
      end

      it "returns moves for agent 1 to move towards and nade thickest cluster of opps" do
        is_expected.to eq(
          ["1; MOVE 12 9", "2; HUNKER_DOWN"]
        )
      end
    end
  end
end
