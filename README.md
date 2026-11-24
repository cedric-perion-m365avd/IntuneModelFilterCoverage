# IntuneModelFilterCoverage

Outil PowerShell en lecture seule qui inventorie les modèles d'appareils gérés par Intune pour un fabricant donné et indique quels filtres d'attribution citent déjà chaque modèle.

## À quoi sert cet outil et pourquoi maintenant

La newsletter Intune d'Andrew Taylor du 9 octobre 2026 met en avant un script qui génère des filtres d'attribution pour les différents modèles Lenovo sans avoir à chercher soi-même tous les codes de modèle. Générer un filtre par modèle va vite. Le risque est d'obtenir des filtres qui ne correspondent à aucun appareil géré ou de rater un modèle déjà présent dans le parc.

Cet outil fait le contrôle à mener avant cette étape. Il liste les modèles réellement remontés par Intune pour un fabricant, le nombre d'appareils pour chacun et les filtres dont la règle cite déjà ce modèle. Vous repérez ainsi les modèles sans filtre avant de générer de nouveaux filtres dans le locataire.

Ce contrôle prend plus de poids avec les plans de déploiement Intune. La newsletter ne précise pas si cette fonction est en préversion ou en disponibilité générale. Vérifiez ce statut dans la documentation Microsoft avant de bâtir un pilote sur ces filtres.

L'outil ne crée ni ne modifie aucun filtre. Il travaille uniquement en lecture.

## Prérequis

Modules du SDK Microsoft Graph PowerShell v2 :

- Microsoft.Graph.Authentication
- Microsoft.Graph.DeviceManagement
- Microsoft.Graph.Beta.DeviceManagement

Portées déléguées Microsoft Graph :

- DeviceManagementManagedDevices.Read.All pour lire les appareils gérés
- DeviceManagementConfiguration.Read.All pour lire les filtres d'attribution

Rôle et visibilité :

- Un compte autorisé à consulter les appareils et les filtres dans Intune
- Selon son rôle et ses scope tags, le compte peut ne pas voir tout le parc. Interprétez le rapport en conséquence.

## Installation

Installez les modules du SDK Microsoft Graph PowerShell v2 puis téléchargez le script à la racine de votre dossier de travail.

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
Install-Module Microsoft.Graph.Beta.DeviceManagement -Scope CurrentUser
```

## Exemples d'utilisation

```powershell
.\Get-IntuneModelFilterCoverage.ps1

.\Get-IntuneModelFilterCoverage.ps1 -Manufacturer 'Dell' -OperatingSystem 'Windows'

.\Get-IntuneModelFilterCoverage.ps1 -ExportPath '.\couverture-modeles.csv'
```

Le paramètre Manufacturer fait une comparaison partielle. Il accepte donc d'autres fabricants que Lenovo à condition d'écrire le nom tel qu'Intune le remonte dans la propriété du fabricant.

## Exemple de sortie

L'exemple suivant est fictif et fourni à titre d'illustration. Il ne provient pas d'une exécution réelle.

```
Modele          : 21CB
NbAppareils     : 42
NbFiltres       : 1
Filtres         : Filtre modeles Lenovo portables
ExempleAppareil : POSTE-0001

Modele          : 20XW
NbAppareils     : 18
NbFiltres       : 0
Filtres         :
ExempleAppareil : POSTE-0042
```

Ici le modèle 20XW compte des appareils gérés mais n'est cité dans aucune règle de filtre. C'est le genre de trou que le rapport sert à repérer avant de générer de nouveaux filtres.

## Limites connues

- La recherche est textuelle. L'outil n'évalue pas la logique du filtre.
- Une règle qui exclut un modèle ou qui combine plusieurs conditions apparaîtra comme citant ce modèle sans forcément l'inclure.
- Une règle basée sur une partie seulement du code de modèle ne sera pas détectée. Pour valider un filtre précis, contrôlez dans la console Intune les appareils qu'il cible réellement.
- L'outil ne vérifie pas les attributions. Un filtre peut exister sans servir à aucune stratégie ni application.
- Les filtres sont lus via le point de terminaison beta de Microsoft Graph, susceptible de changer. Revalidez la sortie avant de bâtir une automatisation de production dessus.
- Selon le rôle et les scope tags du compte, le rapport peut ne pas couvrir tout le parc.

## Article et sources

- Article : https://trivium365.com/blog/newsletter-intune-9-octobre-2026-inventaire-modeles-filtres-attribution/
- Newsletter Intune d'Andrew Taylor du 9 octobre 2026 : https://andrewstaylor.com/2026/10/09/intune-newsletter-9th-october-2026/
- Sources Microsoft citées dans l'article :
  - Remote PC connections in Windows App on Windows : https://techcommunity.microsoft.com/t5/windows-it-pro-blog/remote-pc-connections-in-windows-app-on-windows-is-now-generally/ba-p/4561186
  - Windows news you can use September 2026 : https://techcommunity.microsoft.com/t5/windows-it-pro-blog/windows-news-you-can-use-september-2026/ba-p/4552395


## Démonstration en vidéo

https://www.youtube.com/watch?v=bW7Nl_S6Bc8
