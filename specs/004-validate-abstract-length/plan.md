# Implementation Plan: Talk Abstract Length Validation

**Branch**: `004-validate-abstract-length` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)

## Summary

Ajout d'une validation de longueur maximale (500 caracteres) pour l'abstract des talks dans l'entite domaine Talk.

## Design

| Fichier | Modification |
|---------|-------------|
| `src/domain/talk.entity.ts` | Ajout `InvalidAbstractLengthError` + validation constructeur |
| `src/domain/talk.entity.spec.ts` | Tests unitaires (500 OK, 501 KO, vide OK) |
| `docs/adrs/0007-validate-abstract-length.md` | ADR documentant la decision |
