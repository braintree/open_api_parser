require "spec_helper"

RSpec.describe OpenApiParser::Pointer do
  DOCUMENT = {
    "foo" => ["bar", "baz"],
    "" => 0,
    "a/b" => 1,
    "c%d" => 2,
    "e^f" => 3,
    "g|h" => 4,
    "i\\j" => 5,
    "k\"l" => 6,
    " " => 7,
    "m~n" => 8
  }

  describe "resolve" do
    it "works with RFC examples" do
      resolutions = {
        "#" => DOCUMENT,
        "#/foo" => ["bar", "baz"],
        "#/foo/0" => "bar",
        "#/" => 0,
        "#/a~1b" => 1,
        "#/c%d" => 2,
        "#/e^f" => 3,
        "#/g|h" => 4,
        "#/i\\j" => 5,
        "#/k\"l" => 6,
        "#/ " => 7,
        "#/m~0n" => 8,
      }

      resolutions.each do |pointer, expected|
        expect(OpenApiParser::Pointer.new(pointer).resolve(DOCUMENT)).to eq(expected)
        expect(OpenApiParser::Pointer.new(pointer[1..-1]).resolve(DOCUMENT)).to eq(expected)
      end
    end

    it "works with escaped RFC examples" do
      resolutions = {
        "#" => DOCUMENT,
        "#/foo" => ["bar", "baz"],
        "#/foo/0" => "bar",
        "#/" => 0,
        "#/a~1b" => 1,
        "#/c%25d" => 2,
        "#/e%5Ef" => 3,
        "#/g%7Ch" => 4,
        "#/i%5Cj" => 5,
        "#/k%22l" => 6,
        "#/%20" => 7,
        "#/m~0n" => 8,
      }

      resolutions.each do |pointer, expected|
        expect(OpenApiParser::Pointer.new(pointer).resolve(DOCUMENT)).to eq(expected)
        expect(OpenApiParser::Pointer.new(pointer[1..-1]).resolve(DOCUMENT)).to eq(expected)
      end
    end
  end
end
