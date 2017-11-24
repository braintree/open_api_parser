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

    def deeply_expand_refs(fragment, cur_path)
      fragment, cur_path = expand_refs(fragment, cur_path)

      if fragment.is_a?(Hash)
        fragment.reduce({}) do |hash, (k, v)|
          hash.merge(k => deeply_expand_refs(v, "#{cur_path}/#{k}"))
        end
      elsif fragment.is_a?(Array)
        fragment.map { |e| deeply_expand_refs(e, cur_path) }
      else
        fragment
      end
    end

    def expand_refs(fragment, cur_path)
      if fragment.is_a?(Hash) && fragment.key?("$ref")
        raw_uri = fragment["$ref"]
        ref = OpenApiParser::Reference.new(raw_uri)
        fully_resolved = ref.resolve(@path, cur_path, @content, @file_cache)
        unless fully_resolved
          expand_refs(ref.referrent_document, ref.referrent_pointer)
        else
          [ref.referrent_document, ref.referrent_pointer]
        end
      else
        [fragment, cur_path]
      end
    end
  end
end
