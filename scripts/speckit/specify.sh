#!/bin/bash
# =============================================================================
# /speckit.specify — Wrapper terminal de la commande IDE
# =============================================================================
# Simule la commande /speckit.specify de GitHub Copilot Chat en terminal.
# Claude crée directement specs/<feature>/spec.md via ses outils agentiques.
#
# Usage: ./scripts/speckit/specify.sh <feature-name>
# Exemple: ./scripts/speckit/specify.sh 005-validate-speaker-bio
#
# Prérequis: CLI claude installé et authentifié (https://claude.ai/code)
# =============================================================================

set -eu

FEATURE_NAME="${1:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -z "$FEATURE_NAME" ]; then
  echo ""
  echo "Usage: $0 <feature-name>"
  echo "Exemple: $0 005-validate-speaker-bio"
  echo ""
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  ❌ CLI 'claude' introuvable                          ║"
  echo "║  Installez Claude Code : https://claude.ai/code       ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  exit 1
fi

# ── Header "commande IDE"
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   🔧 /speckit.specify ${FEATURE_NAME}"
echo "║                                                               ║"
echo "║   Spec-kit › Génération de la spécification fonctionnelle    ║"
echo "║   Modèle : claude-haiku-4-5                                   ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Lire les fichiers de contexte
CONSTITUTION="$REPO_ROOT/.specify/memory/constitution.md"
TEMPLATE="$REPO_ROOT/.specify/templates/spec-template.md"
AGENT_PROMPT="$REPO_ROOT/.github/prompts/speckit.specify.prompt.md"

echo "📚 Chargement du contexte Spec-kit..."
echo "   ├─ .specify/memory/constitution.md"
echo "   ├─ .specify/templates/spec-template.md"
echo "   └─ .github/prompts/speckit.specify.prompt.md"
echo ""

CONSTITUTION_CONTENT=$(cat "$CONSTITUTION" 2>/dev/null || echo "# Constitution non trouvee")
TEMPLATE_CONTENT=$(cat "$TEMPLATE" 2>/dev/null || echo "# Template non trouve")
# Retirer le frontmatter YAML (lignes entre --- et ---) du prompt agent
AGENT_INSTRUCTIONS=$(awk '/^---/{f=!f; next} !f' "$AGENT_PROMPT" 2>/dev/null || echo "")

OUTPUT_DIR="$REPO_ROOT/specs/$FEATURE_NAME"
OUTPUT_FILE="$OUTPUT_DIR/spec.md"
mkdir -p "$OUTPUT_DIR"

# ── Construire le prompt
PROMPT=$(cat <<EOF
$AGENT_INSTRUCTIONS

## Feature à spécifier : $FEATURE_NAME

---

## Constitution du projet (NON-NÉGOCIABLE)

$CONSTITUTION_CONTENT

---

## Template à utiliser : spec-template.md

$TEMPLATE_CONTENT

---

## Instruction finale

Génère le fichier specs/$FEATURE_NAME/spec.md complet en suivant exactement le template.
Remplis toutes les sections avec des données réalistes pour la feature "$FEATURE_NAME".
Cree le fichier directement avec l outil Write.
EOF
)

# ── Appel Claude (mode agentique — crée le fichier directement)
echo "🤖 Claude génère specs/$FEATURE_NAME/spec.md..."
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo ""

PROMPT_TMP=$(mktemp)
echo "$PROMPT" > "$PROMPT_TMP"

claude -p "$(cat "$PROMPT_TMP")" \
  --model claude-haiku-4-5 \
  --output-format text \
  --dangerously-skip-permissions

rm -f "$PROMPT_TMP"

echo ""
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

# ── Vérifier et afficher le résultat
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
  echo "✅ Spécification générée : specs/$FEATURE_NAME/spec.md ($LINES lignes)"
  echo ""
  echo "   Aperçu :"
  echo "   ─────────────────────────────────────────────────"
  head -8 "$OUTPUT_FILE" | sed 's/^/   /'
  echo "   ..."
else
  echo "⚠️  Le fichier specs/$FEATURE_NAME/spec.md est vide ou absent"
  echo "   Claude a peut-etre affiche le contenu ci-dessus sans creer le fichier."
  echo "   Astuce : relancez sans redirection stderr pour voir le detail."
fi

echo ""
echo "   Prochaine étape : ./scripts/speckit/plan.sh $FEATURE_NAME"
echo ""




