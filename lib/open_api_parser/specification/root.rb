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

        matching_path_details = @raw["paths"].detect do |path_name, path|
          requested_path =~ to_pattern(path_name) &&
            path.keys.any? { |method| matching_method?(method, request_method) }
        end
        return nil if matching_path_details.nil?

        matching_name, matching_path = matching_path_details

        method_details = matching_path.detect do |method, schema|
          matching_method?(method, request_method)
        end

        Endpoint.new(matching_name, method_details.first, method_details.last)
      rescue URI::InvalidURIError
        nil
      end

      def to_json
        JSON.generate(@raw)
      end

      private

      def matching_method?(method, request_method)
        method.to_s == request_method.downcase
      end

      def to_pattern(path_name)
        Regexp.new("\\A" + path_name.gsub(/\{[^}]+\}/, "[^/]+") + "\\z")
      end
    end
  end
end
