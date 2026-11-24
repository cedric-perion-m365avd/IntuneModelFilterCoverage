# Journal des modifications

Ce projet suit le format Keep a Changelog et le versionnage sémantique.

## [1.0.0] - 2026-11-06

### Ajouté

- Première version de Get-IntuneModelFilterCoverage.
- Inventaire en lecture seule des modèles d'appareils gérés par Intune pour un fabricant et un système d'exploitation donnés.
- Comparaison textuelle des modèles avec les règles des filtres d'attribution existants lus via le point de terminaison beta de Microsoft Graph.
- Sortie en objets PowerShell avec le nombre d'appareils par modèle et les filtres qui citent chaque modèle.
- Export CSV facultatif via le paramètre ExportPath.
