require "spec_helper"

RSpec.describe OpenApiParser::Specification::Root do
  def root
    @root ||= begin
      path = File.expand_path("../../../resources/valid_spec.yaml", __FILE__)
      OpenApiParser::Specification.resolve(path)
    end
  end

  describe "endpoint" do
    it "returns an endpoint for a given path and method" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.raw.fetch("operationId")).to eq("createAnimal")
    end

    it "normalized the http method" do
      endpoint = root.endpoint("/animals", "POST")

      expect(endpoint.raw.fetch("operationId")).to eq("createAnimal")
    end

    it "handles path parameters" do
      endpoint = root.endpoint("/animals/123", "get")

      expect(endpoint.raw.fetch("operationId")).to eq("getAnimal")
    end

    it "handles path parameters and query parameters" do
      endpoint = root.endpoint("/animals/123?foo=bar", "get")

      expect(endpoint.raw.fetch("operationId")).to eq("getAnimal")
    end

    it "handles invalid URLs" do
      endpoint = root.endpoint("&&^^..%", "get")

      expect(endpoint).to be_nil
    end

    it "matches the expected path/operation when paths have significant components in common" do
      endpoint = root.endpoint("/animals/search", "post")

      expect(endpoint.raw.fetch("operationId")).to eq("searchAnimals")
    end

    it "handles a missing method on a valid URL" do
      endpoint = root.endpoint("/headers", "head")
      expect(endpoint).to be_nil
    end
  end

  describe "raw" do
    it "exposes the raw schema" do
      expect(root.raw.fetch("swagger")).to eq("2.0")
    end
  end

  describe "to_json" do
    it "returns a json representation of the raw schema" do
      json = root.to_json
      decoded = JSON.parse(json)

      expect(decoded.fetch("swagger")).to eq("2.0")
    end
  end
end
