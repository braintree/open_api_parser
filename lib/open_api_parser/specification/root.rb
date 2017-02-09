module OpenApiParser
  module Specification
    class Root
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def endpoint(path, request_method)
        uri = URI.parse(path)
        requested_path = uri.path.gsub(/\..+\z/, "")

        path_details = @raw["paths"].detect do |path_name, path|
          requested_path =~ to_pattern(path_name)
        end
        return nil if path_details.nil?

        path = path_details.last

        method_details = path.detect do |method, schema|
          method.to_s == request_method.downcase
        end
        return nil if method_details.nil?

        Endpoint.new(path_details.first, method_details.first, method_details.last)
      rescue URI::InvalidURIError
        nil
      end

      def to_json
        JSON.generate(@raw)
      end

      private

      def to_pattern(path_name)
        Regexp.new("\\A" + path_name.gsub(/\{[^}]+\}/, "[^/]+") + "\\z")
      end
    end
  end
end
