#!/bin/bash
# =============================================================================
# /speckit.tasks — Wrapper terminal de la commande IDE
# =============================================================================
# Simule la commande /speckit.tasks de GitHub Copilot Chat en terminal.
# Génère specs/<feature>/tasks.md via Claude en streamant l'output en temps réel.
#
# Usage: ./scripts/speckit/tasks.sh <feature-name>
# Exemple: ./scripts/speckit/tasks.sh 005-validate-speaker-bio
#
# Prérequis: spec.md + plan.md doivent exister pour la feature
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
PLAN_FILE="$REPO_ROOT/specs/$FEATURE_NAME/plan.md"

for f in "$SPEC_FILE" "$PLAN_FILE"; do
  if [ ! -f "$f" ]; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ❌ Fichier manquant : $(basename "$f")                       ║"
    echo "║  Exécutez d'abord specify.sh puis plan.sh                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
  fi
done

# ── Header "commande IDE"
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   ✅ /speckit.tasks ${FEATURE_NAME}"
echo "║                                                               ║"
echo "║   Spec-kit › Génération des tâches (Phase 0 Governance)      ║"
echo "║   Modèle : claude-haiku-4-5                                   ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ── Lire les fichiers de contexte
CONSTITUTION="$REPO_ROOT/.specify/memory/constitution.md"
TEMPLATE="$REPO_ROOT/.specify/templates/tasks-template.md"
AGENT_PROMPT="$REPO_ROOT/.github/prompts/speckit.tasks.prompt.md"
GOVERNANCE_RULES="$REPO_ROOT/.specify/memory/governance-rules.md"

echo "📚 Chargement du contexte Spec-kit..."
echo "   ├─ specs/$FEATURE_NAME/spec.md ✅"
echo "   ├─ specs/$FEATURE_NAME/plan.md ✅"
echo "   ├─ .specify/memory/governance-rules.md"
echo "   ├─ .specify/templates/tasks-template.md"
echo "   └─ .github/prompts/speckit.tasks.prompt.md"
echo ""

CONSTITUTION_CONTENT=$(cat "$CONSTITUTION" 2>/dev/null || echo "")
TEMPLATE_CONTENT=$(cat "$TEMPLATE" 2>/dev/null || echo "")
AGENT_INSTRUCTIONS=$(awk '/^---/{f=!f; next} !f' "$AGENT_PROMPT" 2>/dev/null || echo "")
GOVERNANCE_CONTENT=$(cat "$GOVERNANCE_RULES" 2>/dev/null || echo "")
SPEC_CONTENT=$(cat "$SPEC_FILE")
PLAN_CONTENT=$(cat "$PLAN_FILE")

# ── Construire le prompt complet
OUTPUT_DIR="$REPO_ROOT/specs/$FEATURE_NAME"
OUTPUT_FILE="$OUTPUT_DIR/tasks.md"

PROMPT=$(cat <<EOF
$AGENT_INSTRUCTIONS

## Feature : $FEATURE_NAME

---

## Spécification fonctionnelle

$SPEC_CONTENT

---

## Plan technique

$PLAN_CONTENT

---

## Règles de gouvernance

$GOVERNANCE_CONTENT

---

## Template à utiliser : tasks-template.md

$TEMPLATE_CONTENT

---

## Instruction finale

Génère le fichier \`specs/$FEATURE_NAME/tasks.md\` complet.

IMPORTANT : La Phase 0 (Governance Compliance) est OBLIGATOIRE et doit toujours venir EN PREMIER.
Elle doit contenir au minimum :
- TGOV-01 : Créer ADR docs/adrs/NNNN-$FEATURE_NAME.md
- TGOV-02 : Vérifier placement Clean Architecture
- TGOV-03 : Vérifier aucun import interdit
- TGOV-04 : Exécuter npm run test:compliance
- TGOV-05 : Vérifier contenu ADR (Context, Decision, Consequences)

Puis les phases fonctionnelles par User Story.
Ne tronque pas - genere le fichier complet.
EOF
)

# ── Appel Claude (mode agentique — crée le fichier directement)
echo "🤖 Claude génère specs/$FEATURE_NAME/tasks.md..."
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

# ── Résumé des tâches générées
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
  TGOV_COUNT=$(grep -c "TGOV-" "$OUTPUT_FILE" 2>/dev/null || echo "0")
  TASK_COUNT=$(grep -c "^- \[ \]" "$OUTPUT_FILE" 2>/dev/null || echo "0")
  echo "✅ Tâches générées : specs/$FEATURE_NAME/tasks.md"
  echo "   ├─ Phase 0 (Governance) : $TGOV_COUNT tâches TGOV"
  echo "   └─ Total : $TASK_COUNT tâches"
else
  echo "⚠️  Le fichier specs/$FEATURE_NAME/tasks.md est vide ou absent"
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│  🚀 Workflow Spec-kit complet pour $FEATURE_NAME               │"
echo "│                                                                 │"
echo "│  specs/$FEATURE_NAME/                                           │"
echo "│  ├─ spec.md    ✅ Spécification fonctionnelle                   │"
echo "│  ├─ plan.md    ✅ Plan technique                                │"
echo "│  └─ tasks.md   ✅ Tâches + Phase 0 Governance                  │"
echo "│                                                                 │"
echo "│  Prochaine étape :                                              │"
echo "│    git add specs/$FEATURE_NAME/                                 │"
echo "│    git commit -m \"feat: speckit artifacts for $FEATURE_NAME\"   │"
echo "│    gh pr create --draft                                         │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""




