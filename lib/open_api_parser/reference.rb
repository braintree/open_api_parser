module OpenApiParser
  class Reference
    def initialize(raw_uri)
      @raw_uri = raw_uri
    end

    # Resolve this reference in the given context.
    #
    # Returns a three-element array of:
    #
    # - Whether the referrent has been fully expanded
    # - The resolved document
    # - Pointer of the document if it's embedded in a larger document.
    #   Empty string means the whole document.
    #
    # @param base_path [String] Location of the document where the $ref originates.
    # @param base_pointer [String] Location of the $ref within the document.
    # @param current_document [Hash] Document where the $ref originates.
    # @param file_cache [OpenApiParser::FileCache] File cache instance.
    # @return [Array<Boolean,Hash,String>]
    def resolve(base_path, base_pointer, current_document, file_cache)
      # ref_uri needs to be normalized before being joined, as normalization
      # affects absolute/relativeness.
      ref_uri = normalize_file_uri(Addressable::URI.parse(@raw_uri))
      base_uri = normalize_file_uri(Addressable::URI.parse(base_path)).omit(:fragment).normalize
      resolved_uri = base_uri.join(ref_uri).omit(:fragment).normalize

      fully_expanded, referenced_document, base_pointer =
        case resolved_uri.scheme
        when nil, 'file'
          if base_uri == resolved_uri
            [false, current_document, base_pointer]
          else
            [true, OpenApiParser::Document.resolve(resolved_uri.path, file_cache), '']
          end
        else
          fail "$ref with scheme #{ref_uri.scheme} is not supported"
        end

      if !ref_uri.fragment.nil? && ref_uri.fragment != ''
        resolve_pointer(ref_uri.fragment, base_pointer, referenced_document, fully_expanded)
      else
        [fully_expanded, referenced_document, '']
      end
    end

    private

    # Normalizes the given file URI so that when its `path` content is relative,
    # the URI considers itself relative as well.
    #
    # @example
    #   >> uri = Addressable::URI.parse('file:person.yaml')
    #   >> uri.path
    #   => "person.yaml"
    #   >> uri.absolute?
    #   => true
    #   >> normalize_file_uri(uri).absolute?
    #   => false
    #   >> normalize_file_uri(uri).path
    #   => "person.yaml"
    # @param uri [Addressable::URI]
    # @return [Addressable::URI]
    def normalize_file_uri(uri)
      if uri.scheme == 'file' && uri.host.nil?
        uri.merge(scheme: nil)
      else
        uri
      end
    end

    # @param raw_pointer [String] Pointer to resolve.
    # @param base_pointer [String] The location of the $ref being resolved.
    #   This is empty if `within_document` is not the document where $ref is located.
    # @param within_document [Hash] Document in which to evaluate the pointer.
    # @return [Array<Boolean, Hash, String>]
    #   Whether the referrent has been fully expanded, resolved document, and pointer.
    def resolve_pointer(raw_pointer, base_pointer, within_document, fully_expanded)
      pointer = OpenApiParser::Pointer.new(raw_pointer)

      if pointer.equal_or_ancestor_of?(base_pointer)
        # prevent infinite recursion
        referrent_document = { "$ref" => '#' + raw_pointer }
        # referrent_document is simply a new $ref object pointing
        # at the same fragment; pointer to the document stays the same,
        # i.e. base_pointer.
        [true, referrent_document, base_pointer]
      else
        referrent_document = pointer.resolve(within_document)
        referrent_pointer = pointer.escaped_pointer
        [fully_expanded, referrent_document, referrent_pointer]
      end
    end
  end
end
