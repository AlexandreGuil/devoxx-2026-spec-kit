# ADR-0007 : Systeme de Notification par Email pour Nouveaux Talks

## Statut

Accepte

## Contexte

Les organisateurs de la conference ont besoin d'etre notifies automatiquement lorsqu'un nouveau talk est soumis. Actuellement, ils doivent verifier manuellement la liste des soumissions, ce qui cree des delais dans le processus de review.

## Decision

Implementer un systeme de notification par email utilisant SendGrid comme service d'envoi.

### Implementation technique

- Nouveau service : EmailNotificationService dans infrastructure/
- Integration SendGrid API v3
- Configuration via variables d'environnement (SENDGRID_API_KEY)
- Declenchement automatique dans SubmitTalkUseCase apres creation reussie
- Template email HTML avec details du talk (titre, speaker, duree)

### Pattern

Le service email est un adaptateur infrastructure. Il implemente une interface definie dans application/ pour respecter la Clean Architecture.

| Fichier | Modification |
|---------|-------------|
| src/infrastructure/email-notification.service.ts | Nouveau service SendGrid |
| src/application/notification.port.ts | Interface du port |
| src/application/submit-talk.usecase.ts | Injection du service notification |
| .env | SENDGRID_API_KEY, NOTIFICATION_RECIPIENTS |

## Consequences

### Avantages

- Notification instantanee des organisateurs
- Traçabilite des envois via SendGrid dashboard
- Templates personnalisables

### Inconvenients

- Dependance externe (SendGrid)
- Cout par email (plan gratuit : 100/jour)
- Necessite gestion des erreurs reseau

## Alternatives considerees

1. Webhook Slack — moins formel, pas d'historique email
2. SMS via Twilio — trop intrusif pour des notifications de soumission
3. Dashboard temps reel — plus complexe, pas necessaire a ce stade
