# Stop a la dette documentaire — Spec-kit + 3 agents IA

> **Devoxx France 2026** — Tools-in-Action 30 min
> Alexandre Guillemot & Axel [Nom] · WeScale

Governance automatisee des ADRs avec GitHub Spec-kit et 3 agents Claude IA en CI/CD.

## Le probleme

Les sachants partent, et vous heritez d'un repo sans spec, sans doc, sans ADR.
Le Time-To-Market s'effondre. L'onboarding devient un calvaire.

**Ce repo demontre comment rendre la documentation automatique et non-negociable.**

## Comment ca marche

### Spec-kit : de la spec au code

```
Constitution ──→ specify ──→ plan ──→ tasks ──→ implement
  (regles)       (spec)     (design)  (taches)   (code)
```

Chaque etape produit un artefact versionne. L'IA genere, le dev valide.

### 3 agents IA en CI

```
PR ouverte
    |
    +--------+--------+
    v        v        v        (en parallele)
 Agent 1  Agent 2  Agent 3
Structure ADR Review Coherence
  (Bash)  (Claude)  (Claude)
    |        |        |
    +--------+--------+
             v
     Score /100 → >= 80 PASS
                  <  80 FAIL
```

| Agent | Methode | Verifie |
|-------|---------|---------|
| **Agent 1** | Bash (deterministe) | Clean Architecture, imports |
| **Agent 2** | Claude Haiku 4.5 | Presence + pertinence ADR |
| **Agent 3** | Claude Haiku 4.5 | Coherence code ↔ documentation |

**1 seul FAIL → merge bloque.**

### La Regle d'Or (Principe III)

> "Toute modification dans `src/domain` ou `src/application`
> DOIT etre accompagnee d'un nouveau fichier dans `docs/adrs/`"

L'IA est le gardien — pas le redacteur.

## Architecture

```
src/
├── domain/            ← Coeur metier (0 dependances)
│   ├── talk.entity.ts
│   └── talk.repository.ts
├── application/       ← Cas d'usage
│   ├── submit-talk.usecase.ts
│   └── list-talks.usecase.ts
└── infrastructure/    ← Adaptateurs
    ├── in-memory-talk.repository.ts
    └── cli.ts
```

**Infrastructure → Application → Domain** (Domain ne depend de rien)

## Installation

```bash
git clone https://github.com/AlexandreGuil/devoxx-2026-spec-kit.git
cd devoxx-2026-spec-kit
npm install
```

### Lancer

```bash
npm run dev          # Mode developpement
npm test             # Tests unitaires (Vitest)
npm run test:compliance  # Validation governance locale
```

### Spec-kit (necessite ANTHROPIC_API_KEY)

```bash
export ANTHROPIC_API_KEY=sk-ant-...

./speckit specify ma-feature   # Genere specs/ma-feature/spec.md
./speckit plan ma-feature      # Genere specs/ma-feature/plan.md
./speckit tasks ma-feature     # Genere specs/ma-feature/tasks.md
```

## Scenarios de demo

| PR | Scenario | Score | Ce qui se passe |
|----|----------|-------|-----------------|
| #19 | Golden Path | **98/100 PASS** | Domain + ADR coherent → merge autorise |
| #17 | ADR manquant | **34/100 FAIL** | Domain modifie sans ADR → Agent 2 = 0% |
| #18 | ADR incoherent | **25/100 FAIL** | ADR parle d'emails, code valide un abstract → Agent 3 = 20% |

Le scenario #18 est le plus interessant : un outil classique dit "ADR present, check".
Claude comprend que le contenu ne correspond pas au code. **C'est de la comprehension semantique, pas un grep.**

## ADRs

- [ADR-0001](docs/adrs/0001-adoption-clean-architecture.md) — Clean Architecture
- [ADR-0002](docs/adrs/0002-utilisation-spec-kit-gouvernance.md) — Spec-kit Governance
- [ADR-0003](docs/adrs/0003-adoption-format-deep-dive.md) — Format Deep Dive (90 min)
- [ADR-0004](docs/adrs/0004-integration-gouvernance-speckit-workflow.md) — Integration CI
- [ADR-0005](docs/adrs/0005-validation-titre.md) — Validation titre

## Configuration CI

| Secret | Description |
|--------|-------------|
| `ANTHROPIC_API_KEY` | Cle API Anthropic pour Claude |

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPLIANCE_THRESHOLD` | `80` | Score minimum pour merger |

## Licence

MIT
