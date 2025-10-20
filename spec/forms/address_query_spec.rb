require "rails_helper"

RSpec.describe AddressQuery do
  describe "#value" do
    it "returns stripped value when present" do
      query = described_class.new("  New York  ")
      expect(query.value).to eq("New York")
    end

    it "returns nil when blank" do
      query = described_class.new("   ")
      expect(query.value).to be_nil
    end

    it "coerces nil to empty string before processing" do
      query = described_class.new(nil)
      expect(query.value).to be_nil
    end
  end

  describe "#present?" do
    it "is true when value exists" do
      query = described_class.new("Boston")
      expect(query).to be_present
    end

    it "is false when value is blank" do
      query = described_class.new("   ")
      expect(query).not_to be_present
    end
  end
end
