module OpenApiParser
  module Specification
    class Endpoint
      RESERVED_PARAMETER_KEYS = [
        "name",
        "in",
        "description",
        "required"
      ]

      attr_reader :raw

      def initialize(path, method, raw)
        @path = path
        @method = method
        @raw = raw
      end

      def body_schema
        body_param = parameters.detect { |param| param["in"] == "body" }
        return restrictive_schema if body_param.nil?

        body_param["schema"]
      end

      def header_schema
        @header_schema ||= begin
         schema = parameter_schema(permissive_schema, "header")

         schema.tap do |schema|
           schema["properties"] = schema["properties"].reduce({}) do |props, (k, v)|
             props.merge(headerize(k) => v)
           end
         end
        end
      end

      def path_schema
        @path_schema ||= parameter_schema(restrictive_schema, "path")
      end

      def query_schema
        @query_schema ||= parameter_schema(restrictive_schema, "query")
      end

      def response_body_schema(status)
        response = response_from_status(status)
        return restrictive_schema if response.nil?

        response["schema"]
      end

      def response_header_schema(status)
        response = response_from_status(status)
        return permissive_schema if response.nil?

        header_properties = response.fetch("headers", {}).reduce({}) do |props, (k, v)|
          props.merge(headerize(k) => v)
        end

        permissive_schema.tap do |schema|
          schema["properties"] = header_properties
          schema["required"] = header_properties.keys
        end
      end

      def header_json(headers)
        schema = header_schema

        headers.reduce({}) do |json, (k, v)|
          json.merge(json_entry(schema, headerize(k), v))
        end
      end

      def path_json(request_path)
        pattern = Regexp.new(@path.gsub(/\{([^}]+)\}/, '(?<\1>[^/]+)'))
        match = pattern.match(request_path.gsub(/\..+\z/, ""))
        schema = path_schema

        match.names.reduce({}) do |json, name|
          json.merge(json_entry(schema, name, match[name]))
        end
      end

      def query_json(query_params)
        schema = query_schema

        query_params.reduce({}) do |json, (k, v)|
          json.merge(json_entry(schema, k, v))
        end
      end

      private

      def permissive_schema
        {
          "additionalProperties" => true,
          "properties" => {}
        }
      end

      def restrictive_schema
        {
          "additionalProperties" => false,
          "properties" => {}
        }
      end

      def headerize(name)
        name.gsub("-", "_").upcase
      end

      def json_entry(schema, name, value)
        properties = schema["properties"]

        if properties.has_key?(name) && properties[name]["type"] == "integer" && value =~ /\A[0-9]+\z/
          {name => value.to_i}
        else
          {name => value}
        end
      end

      def parameters
        @raw.fetch("parameters", [])
      end

      def parameter_schema(empty_schema, type)
        type_params = parameters.select { |param| param["in"] == type }
        return empty_schema if type_params.empty?

        properties = type_params.reduce({}) do |schema, param|
          schema_value = param.clone.delete_if do |k, v|
            RESERVED_PARAMETER_KEYS.include?(k)
          end

          schema.merge(param["name"] => schema_value)
        end

        type_schema = empty_schema.merge("properties" => properties)

        required_params = type_params.select { |param| param["required"] == true }.map { |param| param["name"] }

        if required_params.any?
          type_schema["required"] = required_params
        end

        type_schema
      end

      def response_from_status(status)
        entry = @raw.fetch("responses", {}).detect do |k, v|
          k.to_s == status.to_s
        end

        return @raw.fetch("responses", {})["default"] if entry.nil?

        entry.last
      end
    end
  end
end
