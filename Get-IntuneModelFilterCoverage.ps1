#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement, Microsoft.Graph.Beta.DeviceManagement

<#
.SYNOPSIS
    Inventorie en lecture seule les modeles d'appareils geres par Intune pour un
    fabricant donne et indique quels filtres d'attribution citent deja chaque modele.

.DESCRIPTION
    Get-IntuneModelFilterCoverage interroge Microsoft Graph pour lister les appareils
    geres par Intune, les regroupe par modele pour un fabricant et un systeme
    d'exploitation donnes, puis recherche le texte du modele dans la regle de chaque
    filtre d'attribution existant.

    L'outil est en lecture seule. Il ne cree ni ne modifie aucun filtre, aucune
    strategie ni aucun appareil. Il renvoie un objet par modele avec le nombre
    d'appareils et les filtres qui citent ce modele, afin de reperer les modeles
    geres qui ne figurent dans aucune regle avant de generer de nouveaux filtres.

    La recherche est purement textuelle. Elle n'evalue pas la logique du filtre:
    une regle qui exclut un modele apparaitra comme citant ce modele et une regle
    basee sur une partie seulement du code de modele ne sera pas detectee. Validez
    toujours un filtre precis dans la console Intune.

.PARAMETER Manufacturer
    Nom du fabricant a rechercher dans la propriete manufacturer des appareils
    geres. La comparaison est partielle: le nom doit etre ecrit tel qu'Intune le
    remonte. Valeur par defaut: Lenovo.

.PARAMETER OperatingSystem
    Systeme d'exploitation des appareils a inclure, compare a la propriete
    operatingSystem des appareils geres. Valeur par defaut: Windows.

.PARAMETER ExportPath
    Chemin facultatif d'un fichier CSV ou le rapport est exporte en plus d'etre
    renvoye dans le pipeline. Si le parametre est absent, aucun fichier n'est ecrit.

.EXAMPLE
    .\Get-IntuneModelFilterCoverage.ps1

    Se connecte a Microsoft Graph puis renvoie la couverture des modeles Lenovo
    sous Windows.

.EXAMPLE
    .\Get-IntuneModelFilterCoverage.ps1 -Manufacturer 'Dell' -OperatingSystem 'Windows'

    Renvoie la couverture des modeles dont le fabricant contient Dell sous Windows.

.EXAMPLE
    .\Get-IntuneModelFilterCoverage.ps1 -ExportPath '.\couverture-modeles.csv'

    Renvoie la couverture des modeles Lenovo sous Windows et exporte le rapport au
    format CSV.

.NOTES
    Modules requis: Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement,
    Microsoft.Graph.Beta.DeviceManagement (les filtres d'attribution sont lus via le
    point de terminaison beta, susceptible de changer).

    Portees deleguees requises: DeviceManagementManagedDevices.Read.All et
    DeviceManagementConfiguration.Read.All.
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter()]
    [string]$Manufacturer = 'Lenovo',

    [Parameter()]
    [string]$OperatingSystem = 'Windows',

    [Parameter()]
    [string]$ExportPath
)

$ErrorActionPreference = 'Stop'

$scopes = @(
    'DeviceManagementManagedDevices.Read.All'
    'DeviceManagementConfiguration.Read.All'
)

Connect-MgGraph -Scopes $scopes -NoWelcome

try {
    Write-Verbose "Lecture des appareils geres $OperatingSystem du fabricant '$Manufacturer'."
    $devices = Get-MgDeviceManagementManagedDevice -All -Property 'id,deviceName,manufacturer,model,operatingSystem' |
        Where-Object { $_.OperatingSystem -eq $OperatingSystem -and $_.Manufacturer -like "*$Manufacturer*" }

    if (-not $devices) {
        Write-Warning "Aucun appareil $OperatingSystem du fabricant '$Manufacturer' trouve."
        return
    }

    Write-Verbose 'Lecture des filtres d''attribution (point de terminaison beta).'
    $filters = Get-MgBetaDeviceManagementAssignmentFilter -All

    $report = $devices | Group-Object -Property Model | ForEach-Object {
        $model = $_.Name
        if ([string]::IsNullOrWhiteSpace($model)) {
            $model = '(non renseigne)'
            $matching = @()
        }
        else {
            $pattern = [regex]::Escape($model)
            $matching = @($filters | Where-Object { $_.Rule -match $pattern })
        }

        [pscustomobject]@{
            Modele          = $model
            NbAppareils     = $_.Count
            NbFiltres       = $matching.Count
            Filtres         = ($matching.DisplayName -join '; ')
            ExempleAppareil = ($_.Group | Select-Object -First 1).DeviceName
        }
    } | Sort-Object -Property NbAppareils -Descending

    $sansFiltre = @($report | Where-Object { $_.NbFiltres -eq 0 })
    Write-Verbose "$($sansFiltre.Count) modele(s) sur $(@($report).Count) ne sont cites dans aucune regle de filtre."

    if ($ExportPath) {
        $report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Verbose "Rapport exporte: $ExportPath"
    }

    $report
}
finally {
    Disconnect-MgGraph | Out-Null
}
