require "rails_helper"

RSpec.describe UsageCounter, type: :model do
  describe ".bump!" do
    it "creates and increments a per-device, per-kind, per-day counter" do
      expect(described_class.bump!(device_id: "d1", kind: "explanation")).to eq(1)
      expect(described_class.bump!(device_id: "d1", kind: "explanation")).to eq(2)
    end

    it "keeps separate counts per kind and device" do
      described_class.bump!(device_id: "d1", kind: "explanation")
      expect(described_class.bump!(device_id: "d1", kind: "writing_correction")).to eq(1)
      expect(described_class.bump!(device_id: "d2", kind: "explanation")).to eq(1)
    end
  end

  describe ".limit_for" do
    it "returns the configured limit" do
      expect(described_class.limit_for("writing_correction")).to eq(20)
      expect(described_class.limit_for("explanation")).to eq(60)
    end

    it "falls back to a default for unknown kinds" do
      expect(described_class.limit_for("something_else")).to eq(30)
    end
  end
end
