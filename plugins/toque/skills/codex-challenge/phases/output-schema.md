# Codex Output Schema

Loaded by /toque:codex-challenge SKILL.md on entry.

<output_schema>
## Codex Output Schema

The `--output-schema` flag enforces structured JSON output from Codex CLI,
eliminating free-text parsing entirely. Write this schema to a temp file and
pass it via `--output-schema SCHEMAFILE`.

```json
{
  "type": "object",
  "properties": {
    "scores": {
      "type": "object",
      "properties": {
        "problem_definition": { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "architecture":       { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "sequencing":         { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "risk":               { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "rollback":           { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "timeline":           { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "testing":            { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "omissions":          { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] }
      },
      "required": ["problem_definition", "architecture", "sequencing", "risk", "rollback", "timeline", "testing", "omissions"]
    },
    "total": { "type": "integer", "minimum": 8, "maximum": 40 },
    "gaps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "dimension": { "type": "string" },
          "score": { "type": "integer", "minimum": 1, "maximum": 5 },
          "issue": { "type": "string" },
          "fix": { "type": "string" }
        },
        "required": ["dimension", "score", "issue", "fix"]
      },
      "maxItems": 7
    }
  },
  "required": ["scores", "total", "gaps"],
  "additionalProperties": false
}
```

This schema is passed to Codex via `--output-schema`. Codex CLI validates the
response shape automatically. If the response does not match the schema, Codex
CLI will return an error — this is the schema-enforced fail-closed mechanism.
</output_schema>
