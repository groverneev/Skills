#!/bin/zsh
# Links every skill folder in this directory into Claude Code and Codex.
# A skill = a subfolder containing SKILL.md. Run again after adding a skill.
# Also removes links whose skill was deleted from this folder.

SRC="${0:A:h}"
TARGETS=("$HOME/.claude/skills" "$HOME/.codex/skills")

for target in "${TARGETS[@]}"; do
  mkdir -p "$target"

  # Remove stale links that point into this folder but no longer resolve
  for link in "$target"/*(N@); do
    dest="$(readlink "$link")"
    if [[ "$dest" == "$SRC"/* && ! -e "$link" ]]; then
      rm "$link" && echo "removed stale: $link"
    fi
  done

  # Link each skill
  for skill in "$SRC"/*(N/); do
    [[ -f "$skill/SKILL.md" ]] || continue
    name="${skill:t}"
    link="$target/$name"
    if [[ -L "$link" ]]; then
      continue  # already linked
    elif [[ -e "$link" ]]; then
      echo "skipped $name: $link already exists and is not a link"
    else
      ln -s "$skill" "$link" && echo "linked $name -> $target"
    fi
  done
done
