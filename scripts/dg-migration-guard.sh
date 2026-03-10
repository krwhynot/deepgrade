#!/bin/bash
# DeepGrade: Migration Guard (PreToolUse: Write|Edit)
# Warns when editing EXISTING migration files. Pure bash, no dependencies.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"$//')

[ -z "$FILE_PATH" ] && exit 0

# Check if file is in a migration directory
case "$FILE_PATH" in
  */migrations/*|*/migrate/*|*/Migrations/*|*/alembic/versions/*|*/drizzle/*|*/changelog/*) ;;
  *) exit 0 ;;
esac

# Check if it's a migration file
BASENAME=$(basename "$FILE_PATH")
IS_MIGRATION=false
echo "$BASENAME" | grep -qiE '\.sql$' && IS_MIGRATION=true
echo "$BASENAME" | grep -qE '^[0-9]{4,14}' && IS_MIGRATION=true
echo "$BASENAME" | grep -qE '^V[0-9]+' && IS_MIGRATION=true
echo "$BASENAME" | grep -qE '^[0-9]{4}_' && IS_MIGRATION=true
echo "$BASENAME" | grep -q "ModelSnapshot.cs" && IS_MIGRATION=true

[ "$IS_MIGRATION" != "true" ] && exit 0

# Only warn on EXISTING files (new migrations are fine)
[ ! -f "$FILE_PATH" ] && exit 0

echo "MIGRATION GUARD: Editing existing migration: $FILE_PATH. Modifying applied migrations can break databases. Create a NEW migration instead." >&2
exit 2
