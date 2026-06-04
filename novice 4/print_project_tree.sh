#!/bin/bash
# Run from the root of the Novice project:
#   chmod +x print_project_tree.sh
#   ./print_project_tree.sh
#
# Prints all files and folders, excluding build artefacts and generated files.
# Pipe to a file:  ./print_project_tree.sh > project_tree.txt

find . \
  -not -path './.git/*' \
  -not -path './.dart_tool/*' \
  -not -path './.idea/*' \
  -not -path '*/build/*' \
  -not -path '*/.flutter-plugins*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/.ipynb_checkpoints/*' \
  -not -path '*/\*.freezed.dart' \
  -not -name '*.g.dart' \
  -not -name '*.freezed.dart' \
  -not -name '.DS_Store' \
  | sort \
  | awk '
    BEGIN { prev_depth = 0 }
    {
      path = $0
      sub(/^\.\//, "", path)
      if (path == "") next

      n = split(path, parts, "/")
      depth = n - 1
      name  = parts[n]

      indent = ""
      for (i = 0; i < depth; i++) indent = indent "│   "

      # Check if last entry at this depth (approximate — good enough for README)
      printf "%s├── %s\n", indent, name
    }
  '
