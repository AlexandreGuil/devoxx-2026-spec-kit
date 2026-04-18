# Agent 1: Structure Validator

## Tâche

Vérifier que la structure Clean Architecture existe.

## Étapes à Exécuter

Exécute ces commandes dans l'ordre :

### Étape 1: Vérifier les répertoires obligatoires

```bash
echo "=== VÉRIFICATION STRUCTURE ==="

# Vérifier src/domain
test -d src/domain && echo "✅ src/domain OK" || echo "❌ src/domain MANQUANT"

# Vérifier src/application
test -d src/application && echo "✅ src/application OK" || echo "❌ src/application MANQUANT"

# Vérifier src/infrastructure
test -d src/infrastructure && echo "✅ src/infrastructure OK" || echo "❌ src/infrastructure MANQUANT"

# Vérifier docs/adrs
test -d docs/adrs && echo "✅ docs/adrs OK" || echo "❌ docs/adrs MANQUANT"
```

### Étape 2: Compter les ADRs

```bash
ADR_COUNT=$(ls docs/adrs/*.md 2>/dev/null | wc -l)
echo "📚 Nombre d'ADRs: $ADR_COUNT"
```

### Étape 3: Vérifier les imports interdits

```bash
echo "=== VÉRIFICATION IMPORTS ==="

# Domain ne doit PAS importer infrastructure ou application
FORBIDDEN_DOMAIN=$(grep -r "from.*infrastructure\|from.*application" src/domain/ 2>/dev/null | wc -l)
echo "Imports interdits dans domain: $FORBIDDEN_DOMAIN"

# Application ne doit PAS importer infrastructure
FORBIDDEN_APP=$(grep -r "from.*infrastructure" src/application/ 2>/dev/null | wc -l)
echo "Imports interdits dans application: $FORBIDDEN_APP"
```

## Output

Après avoir exécuté les commandes, crée le fichier `structure-validation-report.json` avec ce contenu :

```json
{
  "agent": "structure-validator",
  "checks": {
    "src_domain_exists": true,
    "src_application_exists": true,
    "src_infrastructure_exists": true,
    "docs_adrs_exists": true,
    "forbidden_imports_count": 0
  },
  "adr_count": 4,
  "status": "PASS"
}
```

## Règles de Décision

- **PASS** si :
  - Les 4 répertoires existent
  - ET aucun import interdit (forbidden_imports_count = 0)

- **FAIL** si :
  - Un répertoire manque
  - OU imports interdits détectés

---

## Mode Spec-kit (si contexte disponible)

Si la variable d'environnement `SPECKIT_VALIDATION_MODE` est `speckit`, alors:

### Vérifications additionnelles

1. **Vérifier que les fichiers planifiés existent** :
   - Lire `SPECKIT_PLANNED_FILES` (JSON array)
   - Pour chaque fichier dans le tableau, vérifier qu'il existe
   - Vérifier qu'il est dans la bonne couche (domain/application/infrastructure)

```bash
# Si SPECKIT_VALIDATION_MODE=speckit
if [ "$SPECKIT_VALIDATION_MODE" = "speckit" ]; then
  echo "=== MODE SPEC-KIT ACTIVÉ ==="
  echo "Fichiers planifiés: $SPECKIT_PLANNED_FILES"

  # Extraire et vérifier chaque fichier
  echo "$SPECKIT_PLANNED_FILES" | jq -r '.[]' 2>/dev/null | while read FILE; do
    if [ -f "$FILE" ]; then
      echo "✅ $FILE existe"
    else
      echo "❌ $FILE MANQUANT (planifié mais non créé)"
    fi
  done
fi
```

### Scoring Spec-kit

- +20 points si tous les fichiers planifiés existent
- +10 points si tous sont dans la bonne couche

### Output enrichi

Ajouter au JSON :

```json
{
  "speckit_mode": true,
  "planned_files": {
    "total": 5,
    "created": 5,
    "missing": []
  }
}
```

## Mode Fallback (si pas de contexte)

Si `SPECKIT_VALIDATION_MODE` est `legacy` ou absent :

- Comportement standard (vérification de la structure de base uniquement)
- Ajouter au JSON : `"speckit_mode": false`
