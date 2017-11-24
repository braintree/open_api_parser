module OpenApiParser
  # Responsible for interpreting a $ref value and
  # resolving it to a raw specification given a base URI.
  class Reference
    # The resolved document. This gets set only after calling `#resolve`.
    attr_reader :referrent_document

    # Pointer of the referrent_document if it's embedded in a larger document.
    # This gets set only after calling `#resolve`.
    # Empty string means the whole document.
    attr_reader :referrent_pointer

    def initialize(raw_uri)
      @raw_uri = raw_uri
      @resolved = false
    end

    # Sets referrent_document and referrent_pointer to the resolved
    # raw specification and pointer, respectively.
    #
    # @return [Boolean] Whether the referrent has been fully expanded.
    def resolve(base_path, base_pointer, current_document, file_cache)
      if @resolved
        fail 'Do not try to resolve an already resolved reference.'
      end
      @resolved = true
      if @raw_uri.start_with?("file:")
        expand_file(@raw_uri, base_path, file_cache)
      else
        expand_pointer(@raw_uri, base_pointer, current_document)
      end
    end

    private

    # @return [Boolean] Whether the referrent has been fully expanded.
    def expand_file(raw_uri, base_path, file_cache)
      relative_path = raw_uri.split(":").last
      absolute_path = File.expand_path(File.join("..", relative_path), base_path)

      @referrent_document = OpenApiParser::Document.resolve(absolute_path, file_cache)
      @referrent_pointer = ''
      true
    end

    # @return [Boolean] Whether the referrent has been fully expanded.
    def expand_pointer(raw_uri, base_pointer, current_document)
      pointer = OpenApiParser::Pointer.new(raw_uri)

      if pointer.exists_in_path?(base_pointer)
        @referrent_document = { "$ref" => raw_uri }
        # @referrent_document is unchanged; pointer stays the same
        @referrent_pointer = base_pointer
        true
      else
        @referrent_document = pointer.resolve(current_document)
        @referrent_pointer = base_pointer + pointer.escaped_pointer
        false
      end
    end
  end
end
