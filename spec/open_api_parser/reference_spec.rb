require "spec_helper"

RSpec.describe OpenApiParser::Reference do
  let(:file_cache) { OpenApiParser::FileCache.new }

  module PathHelpers
    def cwd_relative(path_relative_to_project_root)
      abs_path = Pathname.new(absolute(path_relative_to_project_root))
      abs_path.relative_path_from(Pathname.pwd).to_s
    end

    def absolute(path_relative_to_project_root)
      File.join(project_root, path_relative_to_project_root)
    end

    def project_root
      @project_root ||= File.expand_path(File.join('..', '..', '..'), __FILE__)
    end
  end
  extend PathHelpers
  include PathHelpers

  describe "#resolve" do
    it "can be called repeatedly" do
      ref = OpenApiParser::Reference.new('')
      expect do
        ref.resolve("http:", '', {}, file_cache)
      end.to raise_error(Addressable::URI::InvalidURIError)
      expect(ref.resolve('', '', {}, file_cache)).to eq [false, {}, ""]
    end

    describe "supported schemes" do
      it "supports the file scheme with relative path" do
        ref = OpenApiParser::Reference.new('file:nested/person.yaml')
        _, referrent_doc, _ = ref.resolve(cwd_relative("spec/resources/valid_spec.yaml"), '', {}, file_cache)
        expect(referrent_doc).to eq({"name" => "Drew"})
      end

      it "supports the file scheme with absolute path" do
        ref = OpenApiParser::Reference.new('file:' + absolute('spec/resources/nested/person.yaml'))
        _, referrent_doc, _ = ref.resolve(cwd_relative("spec/resources/valid_spec.yaml"), '', {}, file_cache)
        expect(referrent_doc).to eq({"name" => "Drew"})
      end

      it "interprets an empty scheme as a file path" do
        ref = OpenApiParser::Reference.new('nested/person.yaml')
        _, referrent_doc, _ = ref.resolve(cwd_relative("spec/resources/valid_spec.yaml"), '', {}, file_cache)
        expect(referrent_doc).to eq({"name" => "Drew"})
      end

      it "does not support URI schemes other than file" do
        ref = OpenApiParser::Reference.new('http://example.com/')
        expect do
          ref.resolve('', '', {}, file_cache)
        end.to raise_error(/scheme http is not supported/)
      end
    end

    STANDARD_DOCUMENT = {
      "foo" => "bar",
      "base_pointer" => "boo",
    }

    context "given an invalid base uri" do
      it "raises an error" do
        ref = OpenApiParser::Reference.new(cwd_relative('spec/resources/nested/person.yaml'))
        expect do
          ref.resolve("http:", '', {}, file_cache)
        end.to raise_error(Addressable::URI::InvalidURIError)
      end
    end

    context "given a non-existent base uri" do
      it "does not check for base uri's existence" do
        ref = OpenApiParser::Reference.new('nested/person.yaml')
        bad_base_path = cwd_relative("spec/resources/this-should-never-exist.lmay")
        _, referrent_doc, _ = ref.resolve(bad_base_path, '', {}, file_cache)
        expect(referrent_doc).to eq({"name" => "Drew"})
      end
    end

    context "given a non-existent ref path" do
      it "raises an error" do
        ref = OpenApiParser::Reference.new('nested/this-should-never-exist.lmay')
        expect do
          ref.resolve(cwd_relative("spec/resources/valid_spec.yaml"), '', {}, file_cache)
        end.to raise_error(Errno::ENOENT)
      end
    end

    describe "path resolution" do
      [
        ["nested/person.yaml", cwd_relative("spec/resources/valid_spec.yaml")],
        ["nested/person.yaml", absolute("spec/resources/valid_spec.yaml")],
        [absolute("spec/resources/nested/person.yaml"), cwd_relative("spec/resources/valid_spec.yaml")],
        [absolute("spec/resources/nested/person.yaml"), absolute("spec/resources/valid_spec.yaml")],
      ].each do |ref_uri,base_uri|
        context "given $ref #{ref_uri} and base_uri #{base_uri}" do
          it "resolves successfully" do
            ref = OpenApiParser::Reference.new(ref_uri)
            _, referrent_doc, _ = ref.resolve(base_uri, '', {}, file_cache)
            expect(referrent_doc).to eq({"name" => "Drew"})
          end
        end
      end

      context "given a $ref path the same as the base path" do
        it "reuses the current document" do
          expect(YAML).to_not receive(:load)
          document = {"current" => true}
          ref = OpenApiParser::Reference.new('person.yaml')
          _, referrent_doc, _ = ref.resolve('person.yaml', '', document, file_cache)
          expect(referrent_doc).to eq(document)
        end
      end
    end

    describe "pointer resolution" do
      context "given a deeply nested document" do
        let(:base_path) { cwd_relative("spec/resources/standard.yaml") }
        let(:ref_path) { "" }
        let(:document) {
          {
            "base" => "hello",
            "parent" => {
              "base" => {
              },
              "b" => "parent b",
              "base-2" => "parent base-2",
            }
          }
        }
        [
          ["/parent/base", "#/parent", {"$ref" => "#/parent"}, "/parent/base"],
          ["/parent/base", "#/base", "hello", "/base"],
          ["/parent/base", "#/parent/b", "parent b", "/parent/b"],
          ["/parent/base", "#/parent/base", {"$ref" => "#/parent/base"}, "/parent/base"],
          ["/parent/base", "#/parent/base-2", "parent base-2", "/parent/base-2"],
        ].each do |base_pointer,ref_pointer,expected_doc,expected_pointer|
          it "resolves '#{ref_pointer}' as expected when base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            _, referrent_doc, referrent_pointer = ref.resolve(base_path, base_pointer, document, file_cache)

            expect(referrent_doc).to eq(expected_doc)
            expect(referrent_pointer).to eq(expected_pointer)
          end
        end
      end

      context "given a $ref with an empty path" do
        let(:document) { STANDARD_DOCUMENT }
        let(:base_path) { cwd_relative("spec/resources/standard.yaml") }
        let(:ref_path) { "" }
        [
          ["", "", STANDARD_DOCUMENT, ""],
          ["", "#/foo", "bar", "/foo"],
          ["", "#/base_pointer", "boo", "/base_pointer"],
          ["/base_pointer", "", STANDARD_DOCUMENT, ""],
          ["/base_pointer", "#/foo", "bar", "/foo"],
          ["/base_pointer", "#/base_pointer", {"$ref" => "#/base_pointer"}, "/base_pointer"],
        ].each do |base_pointer,ref_pointer,expected_doc,expected_pointer|
          it "resolves '#{ref_pointer}' as expected when base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            _, referrent_doc, referrent_pointer = ref.resolve(base_path, base_pointer, document, file_cache)

            expect(referrent_doc).to eq(expected_doc)
            expect(referrent_pointer).to eq(expected_pointer)
          end
        end

        it "raises an error if referrent fragment does not exist" do
          ref = OpenApiParser::Reference.new('#/non-existent-token')
          expect do
            ref.resolve('', '', document, file_cache)
          end.to raise_error(KeyError)
        end
      end

      context "given a $ref whose path is the same as base_uri" do
        let(:document) { STANDARD_DOCUMENT }
        let(:base_path) { cwd_relative("spec/resources/standard.yaml") }
        let(:ref_path) { "standard.yaml" }

        before do
          expect(YAML).to_not(
            receive(:load_file).with(base_path))
        end

        [
          ["", "", STANDARD_DOCUMENT, ""],
          ["", "#/foo", "bar", "/foo"],
          ["", "#/base_pointer", "boo", "/base_pointer"],
          ["/base_pointer", "", STANDARD_DOCUMENT, ""],
          ["/base_pointer", "#/foo", "bar", "/foo"],
          ["/base_pointer", "#/base_pointer", {"$ref" => "#/base_pointer"}, "/base_pointer"],
        ].each do |base_pointer,ref_pointer,expected_doc,expected_pointer|
          it "resolves '#{ref_pointer}' as expected when base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            _, referrent_doc, referrent_pointer = ref.resolve(base_path, base_pointer, document, file_cache)

            expect(referrent_doc).to eq(expected_doc)
            expect(referrent_pointer).to eq(expected_pointer)
          end
        end
      end

      context "given a $ref whose path is different than the base_uri" do
        let(:document) { STANDARD_DOCUMENT }
        let(:base_path) { cwd_relative("spec/resources/standard.yaml") }
        let(:ref_path) { "another_standard.yaml" }

        before do
          expect(YAML).to(
            receive(:load_file).with(cwd_relative("spec/resources/another_standard.yaml")).and_return(document))
        end
        [
          ["", "", STANDARD_DOCUMENT, ""],
          ["", "#/foo", "bar", "/foo"],
          ["", "#/base_pointer", "boo", "/base_pointer"],
          ["/base_pointer", "", STANDARD_DOCUMENT, ""],
          ["/base_pointer", "#/foo", "bar", "/foo"],
          ["/base_pointer", "#/base_pointer", "boo", "/base_pointer"],
        ].each do |base_pointer,ref_pointer,expected_doc,expected_pointer|
          it "resolves '#{ref_pointer}' as expected when base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            _, referrent_doc, referrent_pointer = ref.resolve(base_path, base_pointer, document, file_cache)

            expect(referrent_doc).to eq(expected_doc)
            expect(referrent_pointer).to eq(expected_pointer)
          end
        end
      end
    end

    describe 'return value for fully_expanded' do
      let(:document) { STANDARD_DOCUMENT }

      context "given an empty ref path" do
        let(:base_path) { cwd_relative('spec/resources/standard.yaml') }
        let(:ref_path) { '' }

        [
          ['', '', false],
          ['', '#/foo', false],
          ['/base_pointer', '', false],
          ['/base_pointer', '#/foo', false],
          ['/base_pointer', '#/base_pointer', true],
        ].each do |base_pointer,ref_pointer,expected|
          it "is #{expected} when $ref pointer is '#{ref_pointer}' and base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            fully_expanded, *_rest = ref.resolve(base_path, base_pointer, document, file_cache)
            expect(fully_expanded).to be expected
          end
        end
      end

      context "given a ref path same as the base path" do
        let(:base_path) { cwd_relative('spec/resources/standard.yaml') }
        let(:ref_path) { 'standard.yaml' }

        [
          ['', '', false],
          ['', '#/foo', false],
          ['/base_pointer', '', false],
          ['/base_pointer', '#/foo', false],
          ['/base_pointer', '#/base_pointer', true],
        ].each do |base_pointer,ref_pointer,expected|
          it "is #{expected} when $ref pointer is '#{ref_pointer}' and base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            fully_expanded, *_rest = ref.resolve(base_path, base_pointer, document, file_cache)
            expect(fully_expanded).to be expected
          end
        end
      end

      context "given a ref path different than the base path" do
        let(:base_path) { cwd_relative('spec/resources/standard.yaml') }
        let(:ref_path) { 'another_standard.yaml' }

        before do
          expect(YAML).to(
            receive(:load_file).with(cwd_relative("spec/resources/another_standard.yaml")).and_return(document))
        end
        [
          ['', '', true],
          ['', '#/foo', true],
          ['/base_pointer', '', true],
          ['/base_pointer', '#/foo', true],
          ['/base_pointer', '#/base_pointer', true],
        ].each do |base_pointer,ref_pointer,expected|
          it "is #{expected} when $ref pointer is '#{ref_pointer}' and base pointer is '#{base_pointer}'" do
            ref_uri = ref_path + ref_pointer
            ref = OpenApiParser::Reference.new(ref_uri)
            fully_expanded, *_rest = ref.resolve(base_path, base_pointer, document, file_cache)
            expect(fully_expanded).to be expected
          end
        end
      end
    end
  end
end
