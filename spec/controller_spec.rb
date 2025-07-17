RSpec.describe Controller, instance_name: :controller do
  # 1 => Agent.new()

  describe "#call(agent_update:, my_agent_count:)" do
    subject(:call) { controller.call(agent_update: update, my_agent_count: 2) }

    context "when initialized with wood 4 starting setup" do
      let(:controller) { described_class.new(my_id: 0, agents: agents, field: field) }

      let(:agents) do
        {
          1 => Agent.new("1 0 0 6 24 0"),
          2 => Agent.new("2 0 0 6 24 0")
        }
      end

      let(:field) do
        <<~FIELD
          0 0 0 1 0 0 2 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0
          0 1 0 1 1 0 2 1 0 3 1 0 4 1 0 5 1 0 6 1 0 7 1 0
          0 2 0 1 2 0 2 2 0 3 2 0 4 2 0 5 2 0 6 2 0 7 2 0
          0 3 0 1 3 0 2 3 0 3 3 0 4 3 0 5 3 0 6 3 0 7 3 0
          0 4 0 1 4 0 2 4 0 3 4 0 4 4 0 5 4 0 6 4 0 7 4 0
        FIELD
      end

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
  end
end
