module OpenApiParser
  class Document
    def self.resolve(path, file_cache = OpenApiParser::FileCache.new)
      file_cache.get(path) do
        content = YAML.load_file(path)
        Document.new(path, content, file_cache).resolve
      end
    end

    def initialize(path, content, file_cache)
      @path = path
      @content = content
      @file_cache = file_cache
    end

    def resolve
      deeply_expand_refs(@content, nil)
    end

    private

    def deeply_expand_refs(fragment, current_pointer)
      fragment, current_pointer = expand_refs(fragment, current_pointer)

      if fragment.is_a?(Hash)
        fragment.reduce({}) do |hash, (k, v)|
          hash.merge(k => deeply_expand_refs(v, "#{current_pointer}/#{k}"))
        end
      elsif fragment.is_a?(Array)
        fragment.map { |e| deeply_expand_refs(e, current_pointer) }
      else
        fragment
      end
    end

    def expand_refs(fragment, current_pointer)
      if fragment.is_a?(Hash) && fragment.key?("$ref")
        raw_uri = fragment["$ref"]
        ref = OpenApiParser::Reference.new(raw_uri)
        fully_resolved, referrent_document, referrent_pointer =
          ref.resolve(@path, current_pointer, @content, @file_cache)
        unless fully_resolved
          expand_refs(referrent_document, referrent_pointer)
        else
          [referrent_document, referrent_pointer]
        end
      else
        [fragment, current_pointer]
      end
    end
  end
end
