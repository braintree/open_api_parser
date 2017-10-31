require "spec_helper"

RSpec.describe OpenApiParser::Specification::Root do
  def root
    @root ||= begin
      path = File.expand_path("../../../resources/valid_spec.yaml", __FILE__)
      OpenApiParser::Specification.resolve(path)
    end
  end

  describe "body_schema" do
    it "returns the schema for the body" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.body_schema).to eq({
        "type" => "object",
        "required" => ["name", "legs"],
        "properties" => {
          "name" => {
            "type" => "string"
          },
          "legs" => {
            "type" => "integer"
          }
        }
      })
    end

    it "returns a restrictive schema if no body is specified" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.body_schema).to eq({
        "additionalProperties" => false,
        "properties" => {}
      })
    end
  end

  describe "header_schema" do
    it "returns the schema for the headers with normalized names" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.header_schema).to eq({
        "additionalProperties" => true,
        "properties" => {
          "USER_ID" => {
            "type" => "integer"
          }
        }
      })
    end

    it "returns a permissive schema if there are no headers" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.header_schema).to eq({
        "additionalProperties" => true,
        "properties" => {}
      })
    end
  end

  describe "path_schema" do
    it "returns the schema for the path" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.path_schema).to eq({
        "additionalProperties" => false,
        "required" => ["id"],
        "properties" => {
          "id" => {
            "type" => "integer"
          }
        }
      })
    end

    it "returns a restrictive schema with no path params" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.path_schema).to eq({
        "additionalProperties" => false,
        "properties" => {}
      })
    end
  end

  describe "query_schema" do
    it "returns the schema for the query params" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.query_schema).to eq({
        "additionalProperties" => false,
        "properties" => {
          "size" => {
            "type" => "string",
            "enum" => [
              "small",
              "large"
            ]
          },
          "age" => {
            "type" => "integer"
          },
          "tag" => {
            "type" => "string"
          }
        }
      })
    end

    it "returns a restrictive schema with no query params" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.query_schema).to eq({
        "additionalProperties" => false,
        "properties" => {}
      })
    end
  end

  describe "response_body_schema" do
    it "returns the body associated with the response code" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.response_body_schema(201)).to eq({
        "type" => "object",
        "properties" => {
          "status" => {
            "type" => "string",
            "enum" => ["ok"]
          }
        },
        "required" => ["status"],
      })
    end

    it "handles string or integer response codes" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.response_body_schema("201")).to eq({
        "type" => "object",
        "properties" => {
          "status" => {
            "type" => "string",
            "enum" => ["ok"]
          }
        },
        "required" => ["status"],
      })
    end

    it "returns the default response if present" do
      endpoint = root.endpoint("/animals", "post")

      expect(endpoint.response_body_schema(400)).to eq({
        "type" => "object",
        "properties" => {
          "status" => {
            "type" => "string",
            "enum" => ["bad"]
          }
        },
        "required" => ["status"],
      })
    end

    it "returns a restrictive schema for an unknown code without a default" do
      endpoint = root.endpoint("/headers", "get")

      expect(endpoint.response_body_schema(400)).to eq({
        "additionalProperties" => false,
        "properties" => {}
      })
    end

    it "returns a restrictive schema if no schema is specified for a known code" do
      endpoint = root.endpoint("/animals/1", "delete")

      expect(endpoint.response_body_schema(204)).to eq({
        "additionalProperties" => false,
        "properties" => {}
      })
    end
  end

  describe "response_body_header" do
    it "returns the headers associated with the response code" do
      endpoint = root.endpoint("/headers", "get")

      expect(endpoint.response_header_schema(200)).to eq({
        "additionalProperties" => true,
        "properties" => {
          "X_MY_HEADER" => {
            "type" => "string",
            "enum" => ["my value"]
          }
        }
      })
    end

    it "handles string or integer response codes" do
      endpoint = root.endpoint("/headers", "get")

      expect(endpoint.response_header_schema("200")).to eq({
        "additionalProperties" => true,
        "properties" => {
          "X_MY_HEADER" => {
            "type" => "string",
            "enum" => ["my value"]
          }
        }
      })
    end

    it "returns a premissive schema for an unknown code without a default" do
      endpoint = root.endpoint("/headers", "get")

      expect(endpoint.response_header_schema(400)).to eq({
        "additionalProperties" => true,
        "properties" => {}
      })
    end
  end

  describe "header_json" do
    it "returns a json representation of the headers, given a hash" do
      endpoint = root.endpoint("/animals/1", "get")
      header_hash = {
        "User-Id" => "foo"
      }

      expect(endpoint.header_json(header_hash)).to eq({
        "USER_ID" => "foo"
      })
    end

    it "parses integers if the value looks like an integer and the schema is an integer" do
      endpoint = root.endpoint("/animals/1", "get")
      header_hash = {
        "User-Id" => "123"
      }

      expect(endpoint.header_json(header_hash)).to eq({
        "USER_ID" => 123
      })
    end
  end

  describe "path_json" do
    it "returns a json representation of the path, given a string" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.path_json("/animals/1")).to eq({
        "id" => 1
      })
    end

    it "parses integers if the value looks like an integer and the schema is an integer" do
      endpoint = root.endpoint("/animals/1", "get")

      expect(endpoint.path_json("/animals/foo")).to eq({
        "id" => "foo"
      })

      expect(endpoint.path_json("/animals/1")).to eq({
        "id" => 1
      })
    end
  end

  describe "query_json" do
    it "returns a json representation of the query params, given a hash" do
      endpoint = root.endpoint("/animals/1", "get")
      query_hash = {
        "size" => "small"
      }

      expect(endpoint.query_json(query_hash)).to eq({
        "size" => "small"
      })
    end

    it "parses integers if the value looks like an integer and the schema is an integer" do
      endpoint = root.endpoint("/animals/1", "get")
      query_hash = {
        "age" => "25"
      }

      expect(endpoint.query_json(query_hash)).to eq({
        "age" => 25
      })

      query_hash = {
        "age" => "twenty"
      }

      expect(endpoint.query_json(query_hash)).to eq({
        "age" => "twenty"
      })
    end
  end
end
