module OpenApiParser
  class Reference
    def initialize(raw_uri)
      @raw_uri = raw_uri
    end

    def resolve(base_path, base_pointer, current_document, file_cache)
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

    def normalize_file_uri(uri)
      if uri.scheme == 'file' && uri.host.nil?
        uri.merge(scheme: nil)
      else
        uri
      end
    end

    def resolve_pointer(raw_pointer, base_pointer, within_document, fully_expanded)
      pointer = OpenApiParser::Pointer.new(raw_pointer)

      if pointer.equal_or_ancestor_of?(base_pointer)
        referrent_document = { "$ref" => '#' + raw_pointer }
        [true, referrent_document, base_pointer]
      else
        referrent_document = pointer.resolve(within_document)
        referrent_pointer = pointer.escaped_pointer
        [fully_expanded, referrent_document, referrent_pointer]
      end
    end
  end
end
