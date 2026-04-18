#!/bin/bash
# =============================================================================
# Agent 2: ADR Reviewer
# =============================================================================
# Hybrid approach: Bash collects data, Claude AI analyzes and scores ADRs
# Output: Markdown report with ADR pertinence scoring
# =============================================================================

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGED_FILES="${CHANGED_FILES:-}"
DOMAIN_CHANGES="${DOMAIN_CHANGES:-}"
ADR_CHANGES="${ADR_CHANGES:-}"

# Display banner
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  📚 AGENT 2: ADR REVIEWER                                   │"
echo "│  ─────────────────────────────────────────────────────────  │"
echo "│  Évalue la pertinence et la qualité des ADRs                │"
echo "│  Scoring: Structure (30) + Pertinence (40) + Qualité (30)   │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Collect ADR data via Bash
# -----------------------------------------------------------------------------
echo "📊 Collecte des données ADR..."

# List all ADRs and collect details
ADR_LIST=""
ADR_COUNT=0
ADR_DETAILS=""

if [ -d "docs/adrs" ]; then
  for adr in docs/adrs/*.md; do
    if [ -f "$adr" ]; then
      ADR_COUNT=$((ADR_COUNT + 1))
      ADR_NAME=$(basename "$adr")
      ADR_LIST+="$ADR_NAME, "

      # Extract title and status from ADR
      TITLE=$(grep -m1 "^# " "$adr" 2>/dev/null | sed 's/^# //' || echo "Unknown")
      STATUS=$(grep -iE "^\*\*Statut\*\*|^Statut:" "$adr" 2>/dev/null | head -1 || echo "Unknown")
      HAS_CONTEXT=$(grep -c "^## Contexte" "$adr" 2>/dev/null | tr -d '[:space:]' || echo "0")
      HAS_DECISION=$(grep -c "^## Décision" "$adr" 2>/dev/null | tr -d '[:space:]' || echo "0")
      HAS_CONSEQUENCES=$(grep -c "^## Conséquences" "$adr" 2>/dev/null | tr -d '[:space:]' || echo "0")
      # Ensure numeric values
      HAS_CONTEXT=${HAS_CONTEXT:-0}
      HAS_DECISION=${HAS_DECISION:-0}
      HAS_CONSEQUENCES=${HAS_CONSEQUENCES:-0}

      # Read first 100 lines of ADR content for analysis
      ADR_CONTENT=$(head -100 "$adr" 2>/dev/null || echo "")

      ADR_DETAILS+="
### $ADR_NAME
- **Titre**: $TITLE
- **Statut**: $STATUS
- **Contexte**: $([ "$HAS_CONTEXT" -gt 0 ] 2>/dev/null && echo '✅ Présent' || echo '❌ Absent')
- **Décision**: $([ "$HAS_DECISION" -gt 0 ] 2>/dev/null && echo '✅ Présent' || echo '❌ Absent')
- **Conséquences**: $([ "$HAS_CONSEQUENCES" -gt 0 ] 2>/dev/null && echo '✅ Présent' || echo '❌ Absent')

<details>
<summary>Contenu (aperçu)</summary>

\`\`\`markdown
$ADR_CONTENT
\`\`\`

</details>
"
    fi
  done
fi

ADR_LIST="${ADR_LIST%, }"  # Remove trailing comma

# Determine if domain/app changes require ADR
DOMAIN_CHANGE_COUNT=$(echo "$DOMAIN_CHANGES" | grep -c '.' 2>/dev/null || echo "0")
ADR_CHANGE_COUNT=$(echo "$ADR_CHANGES" | grep -c '.' 2>/dev/null || echo "0")

# Sanitize: ensure numeric values (critical for JSON generation)
[[ "$DOMAIN_CHANGE_COUNT" =~ ^[0-9]+$ ]] || DOMAIN_CHANGE_COUNT=0
[[ "$ADR_CHANGE_COUNT" =~ ^[0-9]+$ ]] || ADR_CHANGE_COUNT=0
[[ "$ADR_COUNT" =~ ^[0-9]+$ ]] || ADR_COUNT=0

echo "  📚 Nombre d'ADRs: $ADR_COUNT"
echo "  📝 ADRs: $ADR_LIST"
echo "  🔧 Changements domain/app: $DOMAIN_CHANGE_COUNT"
echo "  📄 ADRs modifiés dans PR: $ADR_CHANGE_COUNT"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Build prompt for Claude to generate MARKDOWN report with scoring
# -----------------------------------------------------------------------------
PROMPT_FILE=$(mktemp)

cat > "$PROMPT_FILE" << EOF
# ADR Review & Pertinence Scoring Request

Tu es l'Agent 2 (ADR Reviewer) du pipeline Spec-Kit.
Génère un rapport d'évaluation des ADRs en **MARKDOWN** avec un **scoring de pertinence**.

## Constitution Reference

Principe III - Règle d'Or:
> "Toute modification de logique métier dans src/application ou src/domain DOIT être accompagnée d'un nouveau fichier .md dans docs/adrs/"

## Données Collectées

### ADRs Existants ($ADR_COUNT total)
$ADR_DETAILS

### Changements dans cette PR

**Fichiers domain/application modifiés:**
$DOMAIN_CHANGES

**ADRs modifiés/ajoutés dans cette PR:**
$ADR_CHANGES

**Tous les fichiers modifiés:**
$CHANGED_FILES

## Scoring de Pertinence (100 points)

Pour chaque ADR, évalue selon ces critères:

| Critère | Points | Description |
|---------|--------|-------------|
| **Structure** | 30 | Sections Contexte (10) + Décision (15) + Conséquences (5) |
| **Pertinence** | 40 | Lien avec les fichiers modifiés dans ce PR |
| **Qualité** | 30 | Clarté, justifications, alternatives mentionnées |

## Règles de Validation

1. **PASS** si:
   - Aucun changement domain/application (pas d'ADR requis)
   - OU changements domain/application + ADR correspondant existe avec score ≥ 70

2. **FAIL** si:
   - Changements domain/application sans ADR correspondant
   - OU ADR existant avec score < 50

3. **NEEDS_REVIEW** si:
   - ADR existe mais pertinence incertaine (score 50-70)

## Output Requis

Génère un rapport MARKDOWN avec ce format exact (inclus le banner ASCII "pixel art"):

## 📚 Agent 2: ADR Reviewer

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────┐
│  📚 AGENT 2: ADR REVIEWER                                                   │
│  ───────────────────────────────────────────────────────────────────────── │
│  Évalue la pertinence et la qualité des ADRs                                │
│  Scoring: Structure (30) + Pertinence (40) + Qualité (30)                   │
└─────────────────────────────────────────────────────────────────────────────┘
\`\`\`

### ADRs Analysés

| ADR | Contexte | Décision | Conséquences | Score |
|-----|----------|----------|--------------|-------|
| nom-de-l-adr.md | ✅/❌ | ✅/❌ | ✅/❌ | XX/100 |

### Pertinence pour ce PR

**Fichiers domain/app modifiés**: X fichiers

| ADR | Pertinence | Raison |
|-----|------------|--------|
| nom-adr.md | 🎯 Haute / ⚠️ Moyenne / ❓ Faible | Explication |

### Score

\`\`\`
ADR Review:  [████████████████████████░░░░░░░░]  75%  (exemple)
\`\`\`

### Verdict

**Statut**: ✅ PASS / ❌ FAIL / ⚠️ NEEDS_REVIEW
**Score moyen ADRs**: XX/100
**Couverture**: X changements couverts sur Y

> Commentaire sur la qualité et pertinence des ADRs.

### Recommandations

Si FAIL ou NEEDS_REVIEW, fournir des suggestions concrètes:
- Template ADR suggéré si manquant
- Corrections à apporter si non-pertinent

---

EOF

# -----------------------------------------------------------------------------
# Step 3: Call Claude CLI (REQUIRED - no fallback)
# -----------------------------------------------------------------------------
OUTPUT_FILE="adr-review-report.md"
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

echo "🤖 Appel Claude API pour analyse des ADRs..."

if ! "$SCRIPT_DIR/call-claude.sh" "$PROMPT_CONTENT" "$OUTPUT_FILE" "markdown"; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ AGENT 2 ÉCHOUÉ: Claude API non disponible                 ║"
  echo "║  La validation IA est OBLIGATOIRE - pas de fallback bash      ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  rm -f "$PROMPT_FILE"
  exit 1
fi

rm -f "$PROMPT_FILE"

# Determine status for JSON report
# RÈGLE CONSTITUTIONNELLE: Si domain modifié, un NOUVEL ADR doit être ajouté dans cette PR
if [ "$DOMAIN_CHANGE_COUNT" -eq 0 ]; then
  # Pas de changement domain = pas d'ADR requis
  STATUS="PASS"
elif [ "$ADR_CHANGE_COUNT" -gt 0 ]; then
  # Domain modifié ET nouvel ADR ajouté dans cette PR = OK
  STATUS="PASS"
else
  # Domain modifié SANS nouvel ADR = VIOLATION CONSTITUTIONNELLE
  STATUS="FAIL"
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ VIOLATION RÈGLE CONSTITUTIONNELLE                         ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║                                                               ║"
  echo "║  Fichiers domain modifiés: $DOMAIN_CHANGE_COUNT"
  echo "║  ADRs ajoutés dans cette PR: $ADR_CHANGE_COUNT"
  echo "║                                                               ║"
  echo "║  RÈGLE: Toute modification dans src/domain DOIT être          ║"
  echo "║         accompagnée d'un nouveau fichier dans docs/adrs/      ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
fi

# Also create a JSON version for the aggregator
# Escape status for JSON safety
STATUS_SAFE=$(echo "$STATUS" | sed 's/["\]/\\&/g')

cat > "adr-review-report.json" << EOF
{
  "agent": "adr-reviewer",
  "domain_changes_count": $DOMAIN_CHANGE_COUNT,
  "adrs_found": $ADR_COUNT,
  "adrs_in_pr": $ADR_CHANGE_COUNT,
  "status": "$STATUS_SAFE"
}
EOF

# Validate generated JSON
if ! jq -e '.' "adr-review-report.json" > /dev/null 2>&1; then
  echo "⚠️ JSON validation failed, creating fallback..."
  cat > "adr-review-report.json" << EOF
{
  "agent": "adr-reviewer",
  "domain_changes_count": 0,
  "adrs_found": 0,
  "adrs_in_pr": 0,
  "status": "$STATUS_SAFE"
}
EOF
fi

echo "📊 JSON report generated: adr-review-report.json"

# Display result
echo ""
echo "📋 Rapport généré:"
echo "─────────────────────────────────────────────────────────────────"
cat "$OUTPUT_FILE"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Exit status
if [ "$STATUS" = "FAIL" ]; then
  echo "❌ ADR review FAILED"
  exit 1
elif [ "$STATUS" = "NEEDS_REVIEW" ]; then
  echo "⚠️ ADR review NEEDS_REVIEW"
else
  echo "✅ ADR review PASSED"
fi
