require "spec_helper"

RSpec.describe OpenApiParser::Specification do
  describe "self.resolve" do
    it "resolves a valid specification" do
      path = File.expand_path("../../resources/example_spec.yaml", __FILE__)
      specification = OpenApiParser::Specification.resolve(path)

      expect(specification.raw.fetch("swagger")).to eq("2.0")
    end

    it "fails on an invalid specification" do
      expect do
        path = File.expand_path("../../resources/pointer_example.yaml", __FILE__)
        OpenApiParser::Specification.resolve(path)
      end.to raise_error(JsonSchema::Error)
    end

    it "allows skipping meta schema validation" do
      expect do
        path = File.expand_path("../../resources/pointer_example.yaml", __FILE__)
        OpenApiParser::Specification.resolve(path, validate_meta_schema: false)
      end.to_not raise_error
    end
  end
end
