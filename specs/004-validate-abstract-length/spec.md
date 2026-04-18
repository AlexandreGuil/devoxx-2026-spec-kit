# Feature Specification: Talk Abstract Length Validation

**Feature Branch**: `004-validate-abstract-length`
**Created**: 2026-04-17
**Status**: Draft

## User Stories

1. [P1] Le systeme rejette un talk dont l'abstract depasse 500 caracteres
2. [P2] Le message d'erreur indique clairement la longueur actuelle et la limite

## Acceptance Scenarios

| # | Given | When | Then |
|---|-------|------|------|
| 1 | Un talk avec un abstract de 500 caracteres | Creation du talk | Talk cree avec succes |
| 2 | Un talk avec un abstract de 501 caracteres | Creation du talk | InvalidAbstractLengthError levee |
| 3 | Un talk avec un abstract vide | Creation du talk | Talk cree avec succes (pas de minimum) |
