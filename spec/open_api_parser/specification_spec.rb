require "spec_helper"

RSpec.describe OpenApiParser::Specification do
  describe "self.resolve" do
    context "valid specification" do
      let(:path) { File.expand_path("../../resources/valid_spec.yaml", __FILE__) }
      let(:specification) { OpenApiParser::Specification.resolve(path) }

      it "resolves successfully" do
        expect(specification.raw.fetch("swagger")).to eq("2.0")
      end

      it "properly resolves matching substring references" do
        expanded_info_response = {
          "type" => "object",
          "properties" => {
            "info" => {
              "type" => "object",
              "properties" => {
                "name" => {
                  "type" => "string"
                }
              }
            }
          }
        }

        expect(specification.raw.fetch("definitions").fetch("personInfoResponse")).to eq(expanded_info_response)
      end
    end

    context "valid specification containing a circular reference" do
      it "resolves successfully and stops expanding references if they are circular" do
        expanded_descendents = {
          "type" => "object",
          "properties" => {
            "name" => {
              "type" => "string"
            },
            "descendants" => {
              "type" => "array",
              "items" => {
                "$ref" => "#/definitions/animalHierarchyDescendants"
              }
            }
          }
        }

        expanded_hierarchy = {
          "type" => "object",
          "properties" => {
            "name" => {
              "type" => "string"
            },
            "descendants" => {
              "type" => "array",
              "items" => expanded_descendents
            }
          }
        }

        path = File.expand_path("../../resources/valid_with_cycle_spec.yaml", __FILE__)
        specification = OpenApiParser::Specification.resolve(path)

        expect(specification.raw.fetch("swagger")).to eq("2.0")
        expect(specification.raw.fetch("definitions").fetch("animalHierarchyDescendants")).to eq(expanded_descendents)
        expect(specification.raw.fetch("definitions").fetch("animalHierarchy")).to eq(expanded_hierarchy)
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

      it "allows skipping meta schema validation" do
        expect do
          path = File.expand_path("../../resources/invalid_spec.yaml", __FILE__)
          OpenApiParser::Specification.resolve(path, validate_meta_schema: false)
        end.to_not raise_error
      end
    end
  end
end
