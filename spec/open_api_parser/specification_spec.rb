require "spec_helper"

RSpec.describe OpenApiParser::Specification do
  describe "self.resolve" do
    context "valid specification" do
      it "resolves successfully" do
        path = File.expand_path("../../resources/valid_spec.yaml", __FILE__)
        specification = OpenApiParser::Specification.resolve(path)

        expect(specification.raw.fetch("swagger")).to eq("2.0")
      end

      it "allows skipping meta schema validation" do
        expect do
          path = File.expand_path("../../resources/pointer_example.yaml", __FILE__)
          OpenApiParser::Specification.resolve(path, validate_meta_schema: false)
        end.to_not raise_error
      end
    end

    context "invalid specification" do
      it "fails to resolve if required properties are not set" do
        expect do
          path = File.expand_path("../../resources/pointer_example.yaml", __FILE__)
          OpenApiParser::Specification.resolve(path)
        end.to raise_error(
          JSON::Schema::ValidationError,
          /did not contain a required property of \'swagger\'/
        )
      end

      it "fails to resolve if nested validation rules are not met" do
        expect do
          path = File.expand_path("../../resources/invalid_spec.yaml", __FILE__)
          OpenApiParser::Specification.resolve(path)
        end.to raise_error(
          JSON::Schema::ValidationError,
          /contains additional properties \[\"fake-http-method\"\] outside of the schema/
        )
      end
    end
  end
end
