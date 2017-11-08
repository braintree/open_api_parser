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
        ref = fragment["$ref"]

        if ref.start_with?("file:")
          expand_file(ref)
        else
          expand_pointer(ref, cur_path)
        end
      else
        [fragment, cur_path]
      end
    end

    def expand_file(ref)
      relative_path = ref.split(":").last
      absolute_path = File.expand_path(File.join("..", relative_path), @path)

      Document.resolve(absolute_path, @file_cache)
    end

    def expand_pointer(ref, cur_path)
      pointer = OpenApiParser::Pointer.new(ref)

      if pointer.exists_in_path?(cur_path)
        { "$ref" => ref }
      else
        fragment = pointer.resolve(@content)
        expand_refs(fragment, cur_path + pointer.escaped_pointer)
      end
    end
  end
end
