# OpenApiParser

[![Build Status](https://travis-ci.org/braintree/open_api_parser.svg?branch=master)](https://travis-ci.org/braintree/open_api_parser)

A gem for parsing Open API specifications.

## Usage

First, resolve a specification given an absolute file path.

```ruby
specification = OpenApiParser::Specification.resolve("/path/to/my/specification.yaml")
```

When you `resolve` your file, all references will be expanded and inlined. The fully resolved specification will be validated against the Open API V2 meta schema. If you'd like to prevent meta schema validation, you can provide an option to do so.

```ruby
specification = OpenApiParser::Specification.resolve("/path/to/my/specification.yaml", validate_meta_schema: false)
```

If you'd rather instantiate a specification with a _fully resolved_ ruby hash, you can do so by directly instantiating an `OpenApiParser::Specification::Root`.

```
OpenApiParser::Specification::Root.new({...})
```

### Reference resolution

`OpenApiParser::Specification.resolve` will fully resolve the provided Open API specification by inlining all [JSON References](https://tools.ietf.org/id/draft-pbryan-zyp-json-ref-03.html). Two types of references are allowed:

* [JSON Pointers](https://tools.ietf.org/html/rfc6901)
* JSON References to files

Pointers are resolved from the root of the document in which they appear. File references are resolved relative to the file in which they appear. Here's an example of each:

```yaml
definitions:
  person:
    type: object
    properties:
      name:
        type: string
      age:
        type: integer

info:
  person:
    $ref: "/definitions/person"
  other:
    $ref: "file:another/file.yaml"
```

For more information, see the specs.

### Endpoints

With a resolved schema, you can access the information for an endpoint given a path and an HTTP verb.

```ruby
endpoint = specification.endpoint("/animals", "post")
```

With an endpoint, you can get access to JSON schema representations of the body, headers, path, query params and response body and headers defined in your Open API specification. You can use these to validate input using any existing JSON Schema library. We recommend [JsonSchema](https://github.com/brandur/json_schema).

```ruby
endpoint.body_schema
# => {...}

endpoint.header_schema
# => {...}

endpoint.path_schema
# => {...}

endpoint.query_schema
# => {...}

endpoint.response_body_schema(201)
# => {...}

endpoint.response_header_schema(201)
# => {...}
```

You can also use the endpoint to transform user input into json that can be validated against the schemas generated in the previous examples.

```ruby
endpoint.header_json(request_headers_as_hash)
# => {...}

endpoint.path_json("/animals/123?query=param")
# => {...}

endpoint.query_json(request_query_params_as_hash)
# => {...}
```

For more information, see the specs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'open_api_parser'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install open_api_parser
```
