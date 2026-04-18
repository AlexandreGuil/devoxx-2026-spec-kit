#!/bin/bash
# =============================================================================
# Agent 1: Structure Validator
# =============================================================================
# Hybrid approach: Bash collects data, Claude AI analyzes and generates report
# Output: Markdown report (human-readable)
# =============================================================================

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGED_FILES="${CHANGED_FILES:-}"
BRANCH_NAME="${BRANCH_NAME:-unknown}"
FEATURE_NAME="${FEATURE_NAME:-unknown}"

# Display banner
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🔍 AGENT 1: STRUCTURE VALIDATOR                            │"
echo "│  ─────────────────────────────────────────────────────────  │"
echo "│  Vérifie la conformité Clean Architecture                   │"
echo "│  Règles: R1a (structure), R1b (imports), R2 (ADRs)         │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Collect data via Bash
# -----------------------------------------------------------------------------
echo "📊 Collecte des données..."

# Check directories
DOMAIN_EXISTS=$(test -d src/domain && echo "true" || echo "false")
APP_EXISTS=$(test -d src/application && echo "true" || echo "false")
INFRA_EXISTS=$(test -d src/infrastructure && echo "true" || echo "false")
ADRS_EXISTS=$(test -d docs/adrs && echo "true" || echo "false")

# Count ADRs
ADR_COUNT=$(ls docs/adrs/*.md 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# Check forbidden imports in domain
FORBIDDEN_DOMAIN=$(grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/ 2>/dev/null | wc -l | tr -d ' ' || echo "0")
FORBIDDEN_APP=$(grep -rE "from\s+['\"]\.\./(infrastructure)" src/application/ 2>/dev/null | wc -l | tr -d ' ' || echo "0")
FORBIDDEN_DOMAIN=${FORBIDDEN_DOMAIN:-0}
FORBIDDEN_APP=${FORBIDDEN_APP:-0}
FORBIDDEN_TOTAL=$((FORBIDDEN_DOMAIN + FORBIDDEN_APP))

# Check for specs directory
SPECS_FOUND="false"
SPECS_LOCATION="none"
if [ -d ".specify/specs/$FEATURE_NAME" ]; then
  SPECS_FOUND="true"
  SPECS_LOCATION=".specify/specs/$FEATURE_NAME"
elif [ -d "specs/$FEATURE_NAME" ]; then
  SPECS_FOUND="true"
  SPECS_LOCATION="specs/$FEATURE_NAME"
fi

# Check for required spec files
SPEC_MD_EXISTS="false"
PLAN_MD_EXISTS="false"
TASKS_MD_EXISTS="false"
if [ "$SPECS_FOUND" = "true" ]; then
  test -f "$SPECS_LOCATION/spec.md" && SPEC_MD_EXISTS="true"
  test -f "$SPECS_LOCATION/plan.md" && PLAN_MD_EXISTS="true"
  test -f "$SPECS_LOCATION/tasks.md" && TASKS_MD_EXISTS="true"
fi

echo "  ✅ src/domain: $DOMAIN_EXISTS"
echo "  ✅ src/application: $APP_EXISTS"
echo "  ✅ src/infrastructure: $INFRA_EXISTS"
echo "  ✅ docs/adrs: $ADRS_EXISTS (count: $ADR_COUNT)"
echo "  ✅ Forbidden imports: $FORBIDDEN_TOTAL"
echo "  ✅ Specs found: $SPECS_FOUND ($SPECS_LOCATION)"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Build prompt for Claude to generate MARKDOWN report
# -----------------------------------------------------------------------------
PROMPT_FILE=$(mktemp)

cat > "$PROMPT_FILE" << EOF
# Structure Validation Report Request

Tu es l'Agent 1 (Structure Validator) du pipeline Spec-Kit.
Génère un rapport de validation de structure Clean Architecture en **MARKDOWN**.

## Données Collectées

### Répertoires Obligatoires
| Répertoire | Existe |
|------------|--------|
| src/domain | $DOMAIN_EXISTS |
| src/application | $APP_EXISTS |
| src/infrastructure | $INFRA_EXISTS |
| docs/adrs | $ADRS_EXISTS |

### Métriques
- Nombre d'ADRs: $ADR_COUNT
- Imports interdits dans domain: $FORBIDDEN_DOMAIN
- Imports interdits dans application: $FORBIDDEN_APP
- Total imports interdits: $FORBIDDEN_TOTAL

### Specs Feature
- Feature: $FEATURE_NAME
- Specs trouvées: $SPECS_FOUND
- Emplacement: $SPECS_LOCATION
- spec.md existe: $SPEC_MD_EXISTS
- plan.md existe: $PLAN_MD_EXISTS
- tasks.md existe: $TASKS_MD_EXISTS

### Fichiers modifiés
$CHANGED_FILES

## Règles de Validation

1. **PASS** si:
   - Les 4 répertoires (domain, application, infrastructure, docs/adrs) existent
   - ET aucun import interdit (FORBIDDEN_TOTAL = 0)
   - ET au moins 1 ADR existe

2. **FAIL** si:
   - Un répertoire obligatoire manque
   - OU imports interdits détectés

## Output Requis

Génère un rapport MARKDOWN avec ce format exact (inclus le banner ASCII "pixel art"):

## 🔍 Agent 1: Structure Validator

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────┐
│  🔍 AGENT 1: STRUCTURE VALIDATOR                                            │
│  ───────────────────────────────────────────────────────────────────────── │
│  Vérifie la conformité Clean Architecture                                   │
│  Règles: R1a (structure), R1b (imports), R2 (ADRs)                         │
└─────────────────────────────────────────────────────────────────────────────┘
\`\`\`

### Vérifications

| Élément | Statut | Détails |
|---------|--------|---------|
| \`src/domain/\` | ✅ ou ❌ | Présent/Absent |
| \`src/application/\` | ✅ ou ❌ | Présent/Absent |
| \`src/infrastructure/\` | ✅ ou ❌ | Présent/Absent |
| \`docs/adrs/\` | ✅ ou ❌ | X ADRs trouvés |
| Imports interdits | ✅ ou ❌ | X violations |

### Score

\`\`\`
Structure:  [████████████████████████████████] 100%  (si PASS)
         ou [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]   0%  (si FAIL)
\`\`\`

### Verdict

**Statut**: ✅ PASS ou ❌ FAIL
**Score**: X/100

> Commentaire sur la conformité Clean Architecture.

---

EOF

# -----------------------------------------------------------------------------
# Step 3: Call Claude CLI (REQUIRED - no fallback)
# -----------------------------------------------------------------------------
OUTPUT_FILE="structure-validation-report.md"
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

echo "🤖 Appel Claude API pour analyse..."

if ! "$SCRIPT_DIR/call-claude.sh" "$PROMPT_CONTENT" "$OUTPUT_FILE" "markdown"; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ AGENT 1 ÉCHOUÉ: Claude API non disponible                 ║"
  echo "║  La validation IA est OBLIGATOIRE - pas de fallback bash      ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  rm -f "$PROMPT_FILE"
  exit 1
fi

rm -f "$PROMPT_FILE"

# Also create a JSON version for the aggregator
cat > "structure-validation-report.json" << EOF
{
  "agent": "structure-validator",
  "checks": {
    "src_domain_exists": $DOMAIN_EXISTS,
    "src_application_exists": $APP_EXISTS,
    "src_infrastructure_exists": $INFRA_EXISTS,
    "docs_adrs_exists": $ADRS_EXISTS,
    "forbidden_imports_count": $FORBIDDEN_TOTAL
  },
  "adr_count": $ADR_COUNT,
  "specs": {
    "found": $SPECS_FOUND,
    "location": "$SPECS_LOCATION"
  },
  "status": "$([[ $DOMAIN_EXISTS = "true" && $APP_EXISTS = "true" && $INFRA_EXISTS = "true" && $ADRS_EXISTS = "true" && $FORBIDDEN_TOTAL -eq 0 ]] && echo "PASS" || echo "FAIL")"
}
EOF

# Display result
echo ""
echo "📋 Rapport généré:"
echo "─────────────────────────────────────────────────────────────────"
cat "$OUTPUT_FILE"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Determine status
if [ "$DOMAIN_EXISTS" = "true" ] && \
   [ "$APP_EXISTS" = "true" ] && \
   [ "$INFRA_EXISTS" = "true" ] && \
   [ "$ADRS_EXISTS" = "true" ] && \
   [ "$FORBIDDEN_TOTAL" -eq 0 ]; then
  echo "✅ Structure validation PASSED"
else
  echo "❌ Structure validation FAILED"
  exit 1
fi
