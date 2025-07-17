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

      it "returns moves for both agents" do
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

      it "returns commands to shoot at agent 5, the wettest one" do
        is_expected.to eq(["1;SHOOT 5", "2;SHOOT 5"])
      end
    end
  end
end
