#!/bin/bash
# =============================================================================
# /speckit.plan — Wrapper terminal de la commande IDE
# =============================================================================
# Simule la commande /speckit.plan de GitHub Copilot Chat en terminal.
# Génère specs/<feature>/plan.md via Claude en streamant l'output en temps réel.
#
# Usage: ./scripts/speckit/plan.sh <feature-name>
# Exemple: ./scripts/speckit/plan.sh 005-validate-speaker-bio
#
# Prérequis: specs/<feature>/spec.md doit exister (généré par specify.sh)
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

SPEC_FILE="$REPO_ROOT/specs/$FEATURE_NAME/spec.md"
if [ ! -f "$SPEC_FILE" ]; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ specs/$FEATURE_NAME/spec.md introuvable                   ║"
  echo "║  Exécutez d'abord : ./scripts/speckit/specify.sh $FEATURE_NAME ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  exit 1
fi

# ── Header "commande IDE"
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   📐 /speckit.plan ${FEATURE_NAME}"
echo "║                                                               ║"
echo "║   Spec-kit › Génération du plan d'implémentation technique   ║"
echo "║   Modèle : claude-haiku-4-5                                   ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Lire les fichiers de contexte
CONSTITUTION="$REPO_ROOT/.specify/memory/constitution.md"
TEMPLATE="$REPO_ROOT/.specify/templates/plan-template.md"
AGENT_PROMPT="$REPO_ROOT/.github/prompts/speckit.plan.prompt.md"
GOVERNANCE_RULES="$REPO_ROOT/.specify/memory/governance-rules.md"

echo "📚 Chargement du contexte Spec-kit..."
echo "   ├─ specs/$FEATURE_NAME/spec.md ✅"
echo "   ├─ .specify/memory/constitution.md"
echo "   ├─ .specify/memory/governance-rules.md"
echo "   ├─ .specify/templates/plan-template.md"
echo "   └─ .github/prompts/speckit.plan.prompt.md"
echo ""

CONSTITUTION_CONTENT=$(cat "$CONSTITUTION" 2>/dev/null || echo "# Constitution non trouvee")
TEMPLATE_CONTENT=$(cat "$TEMPLATE" 2>/dev/null || echo "# Template non trouve")
AGENT_INSTRUCTIONS=$(awk '/^---/{f=!f; next} !f' "$AGENT_PROMPT" 2>/dev/null || echo "")
GOVERNANCE_CONTENT=$(cat "$GOVERNANCE_RULES" 2>/dev/null || echo "# Regles non trouvees")
SPEC_CONTENT=$(cat "$SPEC_FILE")

# ── Structure du projet pour contexte
PROJECT_STRUCTURE=$(find "$REPO_ROOT/src" -type f -name "*.ts" 2>/dev/null | sed "s|$REPO_ROOT/||" | sort | head -20)

# ── Construire le prompt complet
OUTPUT_DIR="$REPO_ROOT/specs/$FEATURE_NAME"
OUTPUT_FILE="$OUTPUT_DIR/plan.md"

PROMPT=$(cat <<EOF
$AGENT_INSTRUCTIONS

## Feature à planifier : $FEATURE_NAME

---

## Spécification fonctionnelle (input)

$SPEC_CONTENT

---

## Constitution du projet (NON-NÉGOCIABLE)

$CONSTITUTION_CONTENT

---

## Règles de gouvernance

$GOVERNANCE_CONTENT

---

## Template à utiliser : plan-template.md

$TEMPLATE_CONTENT

---

## Structure actuelle du projet

\`\`\`
$PROJECT_STRUCTURE
\`\`\`

---

## Instruction finale

Génère le fichier \`specs/$FEATURE_NAME/plan.md\` complet en suivant exactement le template.
Inclus les décisions techniques précises, les fichiers à créer/modifier avec leurs chemins exacts.
Cree le fichier directement avec l outil Write.
EOF
)

# ── Appel Claude (mode agentique — crée le fichier directement)
echo "🤖 Claude génère specs/$FEATURE_NAME/plan.md..."
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo ""

PROMPT_TMP=$(mktemp)
echo "$PROMPT" > "$PROMPT_TMP"

rm -f "$OUTPUT_FILE"

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
  echo "✅ Plan technique généré : specs/$FEATURE_NAME/plan.md ($LINES lignes)"
  echo ""
  echo "   Aperçu :"
  echo "   ─────────────────────────────────────────────────"
  head -8 "$OUTPUT_FILE" | sed 's/^/   /'
  echo "   ..."
else
  echo "⚠️  Le fichier specs/$FEATURE_NAME/plan.md est vide ou absent"
fi

echo ""
echo "   Prochaine étape : ./scripts/speckit/tasks.sh $FEATURE_NAME"
echo ""






