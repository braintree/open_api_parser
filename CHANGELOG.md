# Changelog

## 1.4.0-dev

## 1.3.0

* Expose `path` and `method` on endpoints
* Fix issue where references that matched a substring of the path were not being resolved
  (e.g. "/definitions/PersonInfo" in "/definitions/PersonInfoResponse/schema")

## 1.2.3

* Handle circular references during resolution

## 1.2.2

* Use `json-schema` to validate meta schema

## 1.2.1

* Use `Addressable::URI.unencode` instead of obsoleted `URI.decode`

## 1.2.0

* Make all response headers optional

## 1.1.2

* Match path to correct endpoint when many similar paths exist

## 1.1.1

* Handle invalid URLs in `endpoint`

## 1.1.0

* Bump JsonSchema version

## 1.0.1

* Correctly handle known responses with empty schemas

## 1.0.0

* Initial release
