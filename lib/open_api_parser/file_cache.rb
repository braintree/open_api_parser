module OpenApiParser
  class FileCache
    def initialize
      @cache = {}
    end

    def get(key, &block)
      return @cache[key] if @cache.has_key?(key)

      block.call.tap do |result|
        @cache[key] = result
      end
    end
  end
end
