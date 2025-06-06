# YAMLParser
YAMLParser based on moonbit and is designed for efficient and strict YAML parsing, supporting comprehensive YAML syntax features with real-time error detection.

# Key Features
- Data Type Parsing: Supports null, boolean, int, float, string, array, and object, along with scientific notation and binary integers.
- Structural Parsing:
  - Parses indentation levels with flexible spacing (while enforcing left alignment for elements at the same level).
  - Supports complex keys (?), arrays, and nested objects.(Will be implemented in the next version)
  - Parses anchors (&) and aliases (*), automatically expanding references while detecting cyclic dependencies.
  - Handles inheritance (<<) by expanding it at parse time, fully removing the << structure while supporting nested merging and field overrides.
-Error Handling:
  - Terminates on the first parsing error and provides detailed error logs (including line and column numbers) directly printed to the terminal.
  - Supports multiple error types (e.g., InvalidChar, InvalidEof, InvalidNumber, InvalidIdentEscape), ensuring precise error localization for easier debugging.
- Type Conversion:
  - true/false values are parsed as booleans instead of strings.
  - String parsing: Supports single quotes ('), double quotes ("), and multi-line strings, automatically merging line breaks.
  - Number parsing: Supports binary (0b), scientific notation (1.23e4).

# Test Case
```Moonbit
#|boolean:
#|  - TRUE
#|  - FALSE
#|float:
#|  - 3.14
#|int:
#|  - 123
#|string:
#|  - "Hello, world!"
#|  - 'Single-quoted string'
#|  - Multi-line
#|    text example
#|date:
#|  - 2018-02-17
#|inheritance:
#|  defaults: &default_config
#|    timeout: 30
#|    retries: 3
#|  server1:
#|    <<: *default_config
#|    host: "example.com"
#|  server2:
#|    <<: *default_config
#|    timeout: 60
```
