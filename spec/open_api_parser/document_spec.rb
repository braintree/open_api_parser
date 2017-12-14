require "spec_helper"

RSpec.describe OpenApiParser::Document do
  describe "self.resolve" do
    context "yaml" do
      it "resolves JSON pointers" do
        path = File.expand_path("../../resources/pointer_example.yaml", __FILE__)
        json = OpenApiParser::Document.resolve(path)

        expect(json["person"]).to eq({
          "name" => "Drew"
        })
      end

      it "resolves JSON file references" do
        path = File.expand_path("../../resources/file_reference_example.yaml", __FILE__)
        json = OpenApiParser::Document.resolve(path)

        expect(json["person"]).to eq({
          "name" => "Drew"
        })

        expect(json["person_without_scheme"]).to eq({
          "name" => "Drew"
        })
      end

      it "resolves a mix of pointers and file references" do
        path = File.expand_path("../../resources/mixed_reference_example.yaml", __FILE__)
        json = OpenApiParser::Document.resolve(path)

        expect(json["person"]["greeting"]).to eq({
          "hi" => "Drew"
        })

        expect(json["person"]["stats"]).to eq({
          "age" => 34
        })

        expect(json["person_greeting"]).to eq("Drew")
      end
    end

    context "json" do
      it "resolves JSON pointers" do
        path = File.expand_path("../../resources/pointer_example.json", __FILE__)
        json = OpenApiParser::Document.resolve(path)

        expect(json["person"]).to eq({
          "name" => "Drew"
        })
      end
    end
  end
end
