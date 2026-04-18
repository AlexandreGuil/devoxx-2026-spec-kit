#!/bin/bash
# =============================================================================
# Claude Code CLI Wrapper
# =============================================================================
# Usage: ./call-claude.sh <prompt> <output_file> [format]
#
# Arguments:
#   prompt      - The prompt to send to Claude
#   output_file - Where to save the response
#   format      - Output format: "json" (default) or "markdown"
#
# Environment variables:
#   ANTHROPIC_API_KEY    - Anthropic API key (required for claude CLI)
#   REQUIRE_AI_ANALYSIS  - If "true", exit 1 on failure (default: true)
#
# Uses Claude Code CLI in non-interactive mode
# Model: claude-haiku-4-5 (cheapest, $1/1M input, $5/1M output)
# =============================================================================

set -eu

PROMPT="${1:-}"
OUTPUT_FILE="${2:-}"
OUTPUT_FORMAT="${3:-json}"
REQUIRE_AI="${REQUIRE_AI_ANALYSIS:-true}"

if [ -z "$PROMPT" ] || [ -z "$OUTPUT_FILE" ]; then
  echo "Usage: $0 <prompt> <output_file> [format]"
  exit 1
fi

# Check for API key
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ ERREUR: ANTHROPIC_API_KEY non configurée                  ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║                                                               ║"
  echo "║  L'analyse IA est OBLIGATOIRE pour la validation.             ║"
  echo "║                                                               ║"
  echo "║  💡 Pour configurer:                                          ║"
  echo "║     1. Obtenez une clé sur console.anthropic.com              ║"
  echo "║     2. Ajoutez le secret ANTHROPIC_API_KEY dans GitHub        ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  if [ "$REQUIRE_AI" = "true" ]; then
    exit 1
  else
    echo "⚠️ REQUIRE_AI_ANALYSIS=false - Fallback autorisé (dev mode)"
    exit 1
  fi
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🤖 Appel Claude API (claude-haiku-4-5)                     │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# Create a temporary file for the prompt (handles special characters better)
PROMPT_FILE=$(mktemp)
echo "$PROMPT" > "$PROMPT_FILE"

# Call Claude Code CLI in non-interactive mode with print flag
# -p: print mode (non-interactive, single prompt)
# --model: use cheapest model (Haiku)
# --output-format: request JSON output (we'll convert to markdown if needed)
RESPONSE=$(claude -p "$(cat "$PROMPT_FILE")" --model claude-haiku-4-5 --output-format json 2>&1) || {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ ERREUR: Appel Claude API échoué                           ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║                                                               ║"
  echo "║  La validation par IA est OBLIGATOIRE.                        ║"
  echo "║  Les rapports de gouvernance DOIVENT être générés par l'IA.   ║"
  echo "║                                                               ║"
  echo "║  💡 Vérifiez:                                                 ║"
  echo "║     - La clé ANTHROPIC_API_KEY est valide                     ║"
  echo "║     - Le modèle claude-haiku-4-5 est accessible               ║"
  echo "║     - Votre quota API n'est pas épuisé                        ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Erreur détaillée: $RESPONSE"
  rm -f "$PROMPT_FILE"

  if [ "$REQUIRE_AI" = "true" ]; then
    exit 1
  else
    echo "⚠️ REQUIRE_AI_ANALYSIS=false - Fallback autorisé (dev mode)"
    exit 1
  fi
}

rm -f "$PROMPT_FILE"

# Try to extract the result from Claude's response
# Claude Code CLI returns JSON with a "result" field containing the actual response

# First, check if it's already valid JSON with a result field
RESULT=""
if echo "$RESPONSE" | jq -e '.result' > /dev/null 2>&1; then
  RESULT=$(echo "$RESPONSE" | jq -r '.result')
elif echo "$RESPONSE" | jq -e '.' > /dev/null 2>&1; then
  # It's valid JSON but no result field - use as-is
  RESULT="$RESPONSE"
else
  # Not JSON, use raw response
  RESULT="$RESPONSE"
fi

# Save the result
if [ "$OUTPUT_FORMAT" = "markdown" ]; then
  # For markdown output, save the full response
  # Claude's response IS the markdown report, don't try to extract from code blocks
  # as that would only get the first block and miss the rest of the report
  echo "$RESULT" > "$OUTPUT_FILE"
  echo "✅ Rapport markdown sauvegardé: $OUTPUT_FILE"
else
  # For JSON, try to extract valid JSON
  if echo "$RESULT" | jq -e '.' > /dev/null 2>&1; then
    echo "$RESULT" > "$OUTPUT_FILE"
  elif echo "$RESULT" | grep -q '```json'; then
    echo "$RESULT" | sed -n '/```json/,/```/p' | sed '1d;$d' > "$OUTPUT_FILE"
  else
    # Try to find JSON object in text
    JSON_EXTRACTED=$(echo "$RESULT" | grep -oE '\{[^{}]*(\{[^{}]*\}[^{}]*)*\}' | head -1 || echo "")
    if [ -n "$JSON_EXTRACTED" ] && echo "$JSON_EXTRACTED" | jq -e '.' > /dev/null 2>&1; then
      echo "$JSON_EXTRACTED" > "$OUTPUT_FILE"
    else
      # Fallback: wrap in JSON
      echo "{\"raw_response\": $(echo "$RESULT" | jq -Rs .)}" > "$OUTPUT_FILE"
    fi
  fi
  echo "✅ Rapport JSON sauvegardé: $OUTPUT_FILE"
fi

exit 0
