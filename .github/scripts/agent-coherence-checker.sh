#!/bin/bash
# =============================================================================
# Agent 3: Coherence Checker
# =============================================================================
# Hybrid approach: Bash collects data, Claude AI analyzes coherence and scores
#
# MISSION: Vérifier la COHERENCE BIDIRECTIONNELLE
#   1. Code -> Documentation: Le code est-il bien documenté?
#   2. Documentation -> Code: La documentation est-elle fidèle au code?
#
# Output: Markdown report with coherence scoring
# =============================================================================

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGED_FILES="${CHANGED_FILES:-}"
FEATURE_NAME="${FEATURE_NAME:-unknown}"
# Support both naming conventions (direct and SPECKIT_ prefixed)
HAS_SPECS="${SPECKIT_HAS_SPECS:-${HAS_SPECS:-false}}"
VALIDATION_MODE="${SPECKIT_VALIDATION_MODE:-${VALIDATION_MODE:-legacy}}"
USER_STORIES="${SPECKIT_USER_STORIES:-${USER_STORIES:-[]}}"

# Display banner
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  🔗 AGENT 3: COHERENCE CHECKER                              │"
echo "│  ─────────────────────────────────────────────────────────  │"
echo "│  Vérifie la cohérence BIDIRECTIONNELLE:                     │"
echo "│   • Code -> Doc: le code est-il bien documenté?             │"
echo "│   • Doc -> Code: la doc est-elle fidèle au code?            │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Collect code and documentation data via Bash
# -----------------------------------------------------------------------------
echo "📊 Collecte des données pour analyse..."

# Extract different file categories from changed files
DOMAIN_FILES_CHANGED=""
ADR_FILES_CHANGED=""
SPEC_FILES_CHANGED=""
TEST_FILES_CHANGED=""
ALL_SRC_FILES_CHANGED=""

if [ -n "$CHANGED_FILES" ]; then
  DOMAIN_FILES_CHANGED=$(echo "$CHANGED_FILES" | tr ' ' '\n' | grep "^src/domain/" || true)
  ADR_FILES_CHANGED=$(echo "$CHANGED_FILES" | tr ' ' '\n' | grep "^docs/adrs/" || true)
  SPEC_FILES_CHANGED=$(echo "$CHANGED_FILES" | tr ' ' '\n' | grep -E "^specs/|^\.specify/" || true)
  TEST_FILES_CHANGED=$(echo "$CHANGED_FILES" | tr ' ' '\n' | grep -E "\.test\.|\.spec\." || true)
  ALL_SRC_FILES_CHANGED=$(echo "$CHANGED_FILES" | tr ' ' '\n' | grep "^src/" || true)
fi

DOMAIN_FILES_COUNT=$(echo "$DOMAIN_FILES_CHANGED" | grep -c '.' 2>/dev/null || echo "0")
ADR_FILES_COUNT=$(echo "$ADR_FILES_CHANGED" | grep -c '.' 2>/dev/null || echo "0")
SPEC_FILES_COUNT=$(echo "$SPEC_FILES_CHANGED" | grep -c '.' 2>/dev/null || echo "0")
TEST_FILES_COUNT=$(echo "$TEST_FILES_CHANGED" | grep -c '.' 2>/dev/null || echo "0")
ALL_SRC_COUNT=$(echo "$ALL_SRC_FILES_CHANGED" | grep -c '.' 2>/dev/null || echo "0")

echo "  📁 Fichiers domaine modifiés: $DOMAIN_FILES_COUNT"
echo "  📁 Fichiers src/ modifiés: $ALL_SRC_COUNT"
echo "  📄 ADRs modifiés/ajoutés: $ADR_FILES_COUNT"
echo "  📋 Specs modifiés: $SPEC_FILES_COUNT"
echo "  🧪 Tests modifiés: $TEST_FILES_COUNT"

# -----------------------------------------------------------------------------
# Step 2: Collect FULL domain code details for analysis
# -----------------------------------------------------------------------------
DOMAIN_CODE_DETAILS=""

if [ "$DOMAIN_FILES_COUNT" -gt 0 ]; then
  echo ""
  echo "📖 Lecture du code domaine..."
  for file in $DOMAIN_FILES_CHANGED; do
    if [ -f "$file" ]; then
      echo "  - $file"
      FILE_CONTENT=$(cat "$file" 2>/dev/null || echo "")

      DOMAIN_CODE_DETAILS+="
### $file

\`\`\`typescript
$FILE_CONTENT
\`\`\`
"
    fi
  done
fi

# Also read other src files (not domain) for context
OTHER_SRC_CODE=""
if [ -n "$ALL_SRC_FILES_CHANGED" ]; then
  for file in $ALL_SRC_FILES_CHANGED; do
    # Skip if already in domain
    if echo "$file" | grep -q "^src/domain/"; then
      continue
    fi
    if [ -f "$file" ]; then
      echo "  - $file (src non-domaine)"
      FILE_CONTENT=$(head -80 "$file" 2>/dev/null || echo "")
      OTHER_SRC_CODE+="
### $file
\`\`\`typescript
$FILE_CONTENT
\`\`\`
"
    fi
  done
fi

# -----------------------------------------------------------------------------
# Step 3: Collect FULL ADR documentation for coherence analysis
# -----------------------------------------------------------------------------
ADR_FULL_CONTENT=""

if [ -d "docs/adrs" ]; then
  echo ""
  echo "📖 Lecture des ADRs..."
  for adr in docs/adrs/*.md; do
    if [ -f "$adr" ]; then
      ADR_NAME=$(basename "$adr")
      echo "  - $ADR_NAME"
      ADR_CONTENT=$(cat "$adr" 2>/dev/null || echo "")

      ADR_FULL_CONTENT+="
### $ADR_NAME

\`\`\`markdown
$ADR_CONTENT
\`\`\`
"
    fi
  done
fi

# -----------------------------------------------------------------------------
# Step 4: Collect Spec-kit artifacts (spec.md, plan.md, tasks.md)
# -----------------------------------------------------------------------------
SPECKIT_ARTIFACTS=""
SPECS_LOCATION=""

if [ -d ".specify/specs/$FEATURE_NAME" ]; then
  SPECS_LOCATION=".specify/specs/$FEATURE_NAME"
elif [ -d "specs/$FEATURE_NAME" ]; then
  SPECS_LOCATION="specs/$FEATURE_NAME"
fi

if [ -n "$SPECS_LOCATION" ]; then
  echo ""
  echo "📖 Lecture des artifacts Spec-kit: $SPECS_LOCATION"

  if [ -f "$SPECS_LOCATION/spec.md" ]; then
    SPEC_CONTENT=$(cat "$SPECS_LOCATION/spec.md" 2>/dev/null || echo "")
    SPECKIT_ARTIFACTS+="
### spec.md (Spécification fonctionnelle)
\`\`\`markdown
$SPEC_CONTENT
\`\`\`
"
    echo "  - spec.md ✓"
  fi

  if [ -f "$SPECS_LOCATION/plan.md" ]; then
    PLAN_CONTENT=$(cat "$SPECS_LOCATION/plan.md" 2>/dev/null || echo "")
    SPECKIT_ARTIFACTS+="
### plan.md (Plan technique)
\`\`\`markdown
$PLAN_CONTENT
\`\`\`
"
    echo "  - plan.md ✓"
  fi

  if [ -f "$SPECS_LOCATION/tasks.md" ]; then
    TASKS_CONTENT=$(cat "$SPECS_LOCATION/tasks.md" 2>/dev/null || echo "")
    SPECKIT_ARTIFACTS+="
### tasks.md (Tâches de gouvernance)
\`\`\`markdown
$TASKS_CONTENT
\`\`\`
"
    echo "  - tasks.md ✓"
  fi
fi

# -----------------------------------------------------------------------------
# Step 5: Collect architecture analysis data
# -----------------------------------------------------------------------------
echo ""
echo "🏗️ Analyse architecture..."

# Check for forbidden imports in domain (infrastructure/application imports)
FORBIDDEN_IMPORTS=""
if [ -d "src/domain" ]; then
  FORBIDDEN_IMPORTS=$(grep -rn "from\s*['\"]\.\./(infrastructure|application)" src/domain/ 2>/dev/null || echo "Aucune violation trouvée")
fi

# Check for side effects in domain (console.log, fetch, etc.)
SIDE_EFFECTS=""
if [ -d "src/domain" ]; then
  SIDE_EFFECTS=$(grep -rn "console\.(log|error|warn)\|fetch(\|axios\." src/domain/ 2>/dev/null || echo "Aucun side effect trouvé")
fi

echo ""
echo "📊 Données collectées. Appel Claude API pour analyse de cohérence..."

# -----------------------------------------------------------------------------
# Step 6: Build prompt for Claude to analyze COHERENCE
# -----------------------------------------------------------------------------
PROMPT_FILE=$(mktemp)

cat > "$PROMPT_FILE" << EOF
# COHERENCE CHECKER - Analyse Bidirectionnelle Code <-> Documentation

Tu es l'Agent 3 (Coherence Checker) du pipeline Spec-Kit.
Ta mission est d'analyser la **COHERENCE BIDIRECTIONNELLE** entre le code et la documentation.

## 🎯 MISSION CRITIQUE

### Direction 1: CODE → DOCUMENTATION
Le code implémenté dans cette PR est-il correctement documenté?
- Les classes/types/fonctions ajoutés sont-ils documentés dans un ADR?
- Les règles métier implémentées sont-elles décrites dans la spec?
- Les contraintes de validation sont-elles documentées?

### Direction 2: DOCUMENTATION → CODE
La documentation est-elle fidèle à ce que le code fait réellement?
- Ce que l'ADR décrit correspond-il à l'implémentation?
- Les user stories de la spec sont-elles implémentées dans le code?
- Y a-t-il des écarts entre plan technique et implémentation réelle?

## Feature Context

**Feature name:** $FEATURE_NAME
**Validation mode:** $VALIDATION_MODE
**Has Spec-kit artifacts:** $HAS_SPECS

## Fichiers Modifiés dans cette PR

**Domain files ($DOMAIN_FILES_COUNT):**
$DOMAIN_FILES_CHANGED

**ADR files ($ADR_FILES_COUNT):**
$ADR_FILES_CHANGED

**Spec files ($SPEC_FILES_COUNT):**
$SPEC_FILES_CHANGED

**Test files ($TEST_FILES_COUNT):**
$TEST_FILES_CHANGED

## 📝 CODE COMPLET (src/domain/)

$DOMAIN_CODE_DETAILS

$OTHER_SRC_CODE

## 📚 DOCUMENTATION COMPLÈTE (ADRs)

$ADR_FULL_CONTENT

## 📋 SPEC-KIT ARTIFACTS

$SPECKIT_ARTIFACTS

## 🏗️ Architecture Analysis

**Imports interdits (domain ne doit pas importer infrastructure/application):**
$FORBIDDEN_IMPORTS

**Side effects (domain doit être pur):**
$SIDE_EFFECTS

## 🚨 RÈGLE CONSTITUTIONNELLE OBLIGATOIRE 🚨

**TRÈS IMPORTANT - CETTE RÈGLE EST NON-NÉGOCIABLE:**

> "Toute modification de logique métier dans src/domain DOIT être accompagnée
> d'un NOUVEAU fichier .md dans docs/adrs/"

**VÉRIFICATION CRITIQUE:**
- Domain files modifiés dans cette PR: $DOMAIN_FILES_COUNT
- ADR files ajoutés/modifiés dans cette PR: $ADR_FILES_COUNT

**SI domain files > 0 ET adr files == 0:**
→ C'est une VIOLATION MAJEURE de la règle constitutionnelle
→ Le score MAXIMUM possible est **40/100**
→ Le status doit être **FAIL**
→ Les artifacts Spec-kit (spec.md, plan.md) NE REMPLACENT PAS un ADR

**SI domain files > 0 ET adr files > 0:**
→ Vérifier que l'ADR documente bien les changements domain
→ Score normal possible (jusqu'à 100/100)

## Critères de Scoring (100 points)

| Catégorie | Points | Description |
|-----------|--------|-------------|
| **ADR Requis** | 40 | Si domain modifié, un ADR DOIT exister dans cette PR |
| **Doc Accuracy** | 20 | La documentation décrit-elle fidèlement le code? (Doc→Code) |
| **Code Coverage** | 20 | Le code est-il suffisamment documenté? (Code→Doc) |
| **Architecture** | 20 | Clean architecture respectée (pas d'imports interdits, pas de side effects) |

**ATTENTION:**
- Si domain files > 0 et ADR files == 0: **ADR Requis = 0/40** (automatique!)
- Les spec.md, plan.md, tasks.md NE COMPTENT PAS comme ADR
- Seuls les fichiers dans docs/adrs/*.md comptent comme ADR

## 🚫 IMPORTANT - Ne PAS signaler comme problème:

1. Les classes d'erreur comme "InvalidTitleLengthError" - c'est un pattern DDD correct
2. Les Value Objects comme "Duration" - pattern correct
3. Les noms techniques descriptifs - ils sont corrects

## ✅ CE QU'IL FAUT VÉRIFIER:

1. **ADR Requis**: Y a-t-il un ADR ajouté pour documenter les changements domain?
2. **Doc Accuracy**: L'ADR mentionne-t-il les mêmes validations que le code implémente?
3. **Code Coverage**: Chaque règle métier dans le code a-t-elle une trace dans l'ADR?
4. **Architecture**: Le domain est-il pur (pas d'imports externes, pas de side effects)?

## Output Format

Génère EXACTEMENT ce format markdown:

## 🔗 Agent 3: Coherence Checker

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────┐
│  🔗 COHERENCE CHECKER - Code <-> Documentation                              │
│  ───────────────────────────────────────────────────────────────────────── │
│  Analyse bidirectionnelle: Code→Doc et Doc→Code                             │
└─────────────────────────────────────────────────────────────────────────────┘
\`\`\`

### 📊 Scores de Cohérence

| Catégorie | Score | Observations |
|-----------|-------|--------------|
| 🚨 ADR Requis | XX/40 | Si domain modifié sans ADR ajouté → 0/40 |
| Doc → Code (Fidélité) | XX/20 | La doc décrit-elle fidèlement le code? |
| Code → Doc (Couverture) | XX/20 | Le code est-il documenté dans l'ADR? |
| Architecture Clean | XX/20 | Imports, side effects |
| **TOTAL** | **XX/100** | |

### 🔍 Analyse Détaillée

#### 🚨 ADR Requis (XX/40)

**Vérification constitutionnelle:**
- Domain files modifiés: $DOMAIN_FILES_COUNT
- ADR files dans cette PR: $ADR_FILES_COUNT

[Si domain > 0 et ADR == 0: VIOLATION! Score = 0/40]
[Si domain > 0 et ADR > 0: Vérifier pertinence de l'ADR]
[Si domain == 0: ADR optionnel, Score = 40/40]

#### 📖 Documentation → Code (Fidélité: XX/20)

[Analyse: La documentation décrit-elle correctement ce que le code fait?]
- Ce que l'ADR dit vs ce que le code implémente
- Écarts identifiés
- Points de correspondance

#### 💻 Code → Documentation (Couverture: XX/20)

[Analyse: Tout le code métier est-il documenté dans l'ADR?]
- Règles métier implémentées et leur documentation
- Code non documenté
- Suggestions de documentation manquante

#### 🏗️ Architecture (XX/20)

[Analyse des imports et side effects]

### Score

\`\`\`
Coherence:  [████████████████████████░░░░░░░░]  XX%
\`\`\`

### Verdict

**Statut**: ✅ PASS / ❌ FAIL / ⚠️ NEEDS_REVIEW
**Score**: XX/100 (seuil: 80)

> Conclusion sur la cohérence bidirectionnelle code <-> documentation.

### 🛠️ Recommandations pour améliorer la cohérence

[Si score < 100, fournir des recommandations concrètes et actionnables]

---

EOF

# -----------------------------------------------------------------------------
# Step 7: Call Claude CLI (REQUIRED - no fallback)
# -----------------------------------------------------------------------------
OUTPUT_FILE="coherence-check-report.md"
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

echo ""
echo "🤖 Appel Claude API pour analyse de cohérence..."

if ! "$SCRIPT_DIR/call-claude.sh" "$PROMPT_CONTENT" "$OUTPUT_FILE" "markdown"; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  ❌ AGENT 3 ÉCHOUÉ: Claude API non disponible                 ║"
  echo "║  La validation IA est OBLIGATOIRE - pas de fallback bash      ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  rm -f "$PROMPT_FILE"
  exit 1
fi

rm -f "$PROMPT_FILE"

# -----------------------------------------------------------------------------
# Step 8: Extract score from report and determine status
# -----------------------------------------------------------------------------
SCORE=70  # Default if extraction fails
STATUS="NEEDS_REVIEW"

if [ -f "$OUTPUT_FILE" ]; then
  # Try multiple patterns to extract score
  EXTRACTED_SCORE=""

  # Pattern 1: "**TOTAL** | **XX/100**"
  EXTRACTED_SCORE=$(grep -oE "TOTAL\*\*\s*\|\s*\*\*([0-9]+)/100" "$OUTPUT_FILE" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "")

  # Pattern 2: "Score: XX/100"
  if [ -z "$EXTRACTED_SCORE" ]; then
    EXTRACTED_SCORE=$(grep -oE "Score[:\s]+[0-9]+/100" "$OUTPUT_FILE" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "")
  fi

  # Pattern 3: "XX%" from progress bar
  if [ -z "$EXTRACTED_SCORE" ]; then
    EXTRACTED_SCORE=$(grep -oE "\]\s+[0-9]+%" "$OUTPUT_FILE" 2>/dev/null | grep -oE "[0-9]+" | head -1 || echo "")
  fi

  # Pattern 4: Look for any XX/100 pattern
  if [ -z "$EXTRACTED_SCORE" ]; then
    EXTRACTED_SCORE=$(grep -oE "[0-9]+/100" "$OUTPUT_FILE" 2>/dev/null | grep -oE "^[0-9]+" | tail -1 || echo "")
  fi

  if [ -n "$EXTRACTED_SCORE" ]; then
    SCORE=$EXTRACTED_SCORE
  fi
fi

# =============================================================================
# 🚨 CONSTITUTIONAL RULE ENFORCEMENT (BASH - OVERRIDES CLAUDE ANALYSIS)
# =============================================================================
# Rule: If domain files modified AND no ADR in PR → VIOLATION
# This enforcement happens IN BASH, regardless of what Claude returned
# =============================================================================

if [ "$DOMAIN_FILES_COUNT" -gt 0 ] && [ "$ADR_FILES_COUNT" -eq 0 ]; then
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║  🚨 CONSTITUTIONAL RULE VIOLATION DETECTED                    ║"
  echo "╠═══════════════════════════════════════════════════════════════╣"
  echo "║                                                               ║"
  echo "║  Domain files modified: $DOMAIN_FILES_COUNT"
  echo "║  ADR files in this PR: $ADR_FILES_COUNT"
  echo "║                                                               ║"
  echo "║  RULE: Any domain modification MUST include a new ADR        ║"
  echo "║  Spec-kit artifacts (spec.md, plan.md) do NOT replace ADRs   ║"
  echo "║                                                               ║"
  echo "║  🔴 Score CAPPED at 40/100 (ADR Requis = 0/40)               ║"
  echo "║  🔴 Status forced to FAIL                                    ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  # Cap score at 40 (max without ADR)
  if [ "$SCORE" -gt 40 ]; then
    echo "⚠️ Score réduit de $SCORE → 40 (violation règle constitutionnelle)"
    SCORE=40
  fi
  STATUS="FAIL"
else
  # Normal status determination from Claude's score
  if [ "$SCORE" -ge 80 ]; then
    STATUS="PASS"
  elif [ "$SCORE" -ge 60 ]; then
    STATUS="NEEDS_REVIEW"
  else
    STATUS="FAIL"
  fi

  # Also check explicit status markers from Claude
  if [ -f "$OUTPUT_FILE" ]; then
    if grep -q "✅ PASS" "$OUTPUT_FILE" 2>/dev/null; then
      STATUS="PASS"
    elif grep -q "❌ FAIL" "$OUTPUT_FILE" 2>/dev/null; then
      STATUS="FAIL"
    elif grep -q "⚠️ NEEDS_REVIEW" "$OUTPUT_FILE" 2>/dev/null; then
      STATUS="NEEDS_REVIEW"
    fi
  fi
fi

echo ""
echo "📊 Score final: $SCORE/100 ($STATUS)"

# -----------------------------------------------------------------------------
# Step 9: Create JSON report for aggregator
# -----------------------------------------------------------------------------
# Ensure all numeric variables are valid integers (default to 0)
DOMAIN_FILES_COUNT=${DOMAIN_FILES_COUNT:-0}
ADR_FILES_COUNT=${ADR_FILES_COUNT:-0}
SPEC_FILES_COUNT=${SPEC_FILES_COUNT:-0}
TEST_FILES_COUNT=${TEST_FILES_COUNT:-0}
SCORE=${SCORE:-0}

# Sanitize: ensure they are numeric
[[ "$DOMAIN_FILES_COUNT" =~ ^[0-9]+$ ]] || DOMAIN_FILES_COUNT=0
[[ "$ADR_FILES_COUNT" =~ ^[0-9]+$ ]] || ADR_FILES_COUNT=0
[[ "$SPEC_FILES_COUNT" =~ ^[0-9]+$ ]] || SPEC_FILES_COUNT=0
[[ "$TEST_FILES_COUNT" =~ ^[0-9]+$ ]] || TEST_FILES_COUNT=0
[[ "$SCORE" =~ ^[0-9]+$ ]] || SCORE=0

FORBIDDEN_COUNT=0
SIDE_EFFECTS_COUNT=0

if ! echo "$FORBIDDEN_IMPORTS" | grep -q "Aucune violation"; then
  FORBIDDEN_COUNT=$(echo "$FORBIDDEN_IMPORTS" | grep -c '.' 2>/dev/null || echo "0")
fi

if ! echo "$SIDE_EFFECTS" | grep -q "Aucun side effect"; then
  SIDE_EFFECTS_COUNT=$(echo "$SIDE_EFFECTS" | grep -c '.' 2>/dev/null || echo "0")
fi

# Ensure counts are numeric
[[ "$FORBIDDEN_COUNT" =~ ^[0-9]+$ ]] || FORBIDDEN_COUNT=0
[[ "$SIDE_EFFECTS_COUNT" =~ ^[0-9]+$ ]] || SIDE_EFFECTS_COUNT=0

# Escape feature name for JSON (remove special chars)
FEATURE_NAME_SAFE=$(echo "$FEATURE_NAME" | sed 's/["\]/\\&/g')
VALIDATION_MODE_SAFE=$(echo "$VALIDATION_MODE" | sed 's/["\]/\\&/g')
STATUS_SAFE=$(echo "$STATUS" | sed 's/["\]/\\&/g')

cat > "coherence-check-report.json" << EOF
{
  "agent": "coherence-checker",
  "feature_name": "$FEATURE_NAME_SAFE",
  "validation_mode": "$VALIDATION_MODE_SAFE",
  "domain_files_changed": $DOMAIN_FILES_COUNT,
  "adr_files_changed": $ADR_FILES_COUNT,
  "spec_files_changed": $SPEC_FILES_COUNT,
  "test_files_changed": $TEST_FILES_COUNT,
  "forbidden_imports": $FORBIDDEN_COUNT,
  "side_effects": $SIDE_EFFECTS_COUNT,
  "overall_coherence_score": $SCORE,
  "status": "$STATUS_SAFE"
}
EOF

# Validate generated JSON
if ! jq -e '.' "coherence-check-report.json" > /dev/null 2>&1; then
  echo "⚠️ JSON validation failed, creating fallback..."
  cat > "coherence-check-report.json" << EOF
{
  "agent": "coherence-checker",
  "feature_name": "unknown",
  "validation_mode": "legacy",
  "domain_files_changed": 0,
  "adr_files_changed": 0,
  "spec_files_changed": 0,
  "test_files_changed": 0,
  "forbidden_imports": 0,
  "side_effects": 0,
  "overall_coherence_score": $SCORE,
  "status": "$STATUS_SAFE"
}
EOF
fi

# Display report
echo ""
echo "📋 Rapport généré:"
echo "─────────────────────────────────────────────────────────────────"
cat "$OUTPUT_FILE"
echo "─────────────────────────────────────────────────────────────────"
echo ""

# Exit status (don't fail on NEEDS_REVIEW to allow merge with review)
if [ "$STATUS" = "FAIL" ]; then
  echo "❌ Coherence check FAILED (Score: $SCORE/100)"
  exit 1
else
  echo "✅ Coherence check completed (Score: $SCORE/100, Status: $STATUS)"
  exit 0
fi
