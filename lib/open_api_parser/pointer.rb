module OpenApiParser
  class Pointer
    def initialize(raw_pointer)
      @raw_pointer = raw_pointer
    end

    def resolve(document)
      return document if escaped_pointer == ""

      tokens.reduce(document) do |nested_doc, token|
        nested_doc.fetch(token)
      end
    end

    def equal_or_ancestor_of?(other_pointer)
      other_tokens = OpenApiParser::Pointer.new(other_pointer).escaped_pointer.split("/")
      self_tokens = escaped_pointer.split("/")
      perhaps_common_prefix = other_tokens[0...self_tokens.length]
      perhaps_common_prefix == self_tokens
    end

    def escaped_pointer
      fragment =
        if @raw_pointer.start_with?("#")
          @raw_pointer[1..-1]
        else
          @raw_pointer
        end
      Addressable::URI.unencode(fragment)
    end

    private

    def parse_token(token)
      if token =~ /\A\d+\z/
        token.to_i
      else
        token.gsub("~0", "~").gsub("~1", "/")
      end
    end

    def tokens
      tokens = escaped_pointer[1..-1].split("/")
      tokens << "" if @raw_pointer.end_with?("/")
      tokens.map do |token|
        parse_token(token)
      end
    end
  end
end
