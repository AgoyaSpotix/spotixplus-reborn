# Constantes
$AppNameShort = "SpotiX+"
$AppName = "$AppNameShort PC Script"
$Version = "2.1-rc2"
$ByPassAdmin = $false
$NoTranslations = $false

$GithubUser = "AgoyaSpotix"
$GithubRepo = "spotixplus-reborn"
$Discord = "https://discord.gg/p3AAf7TUPv"

$WshShell = $null
$Shortcut = $null
# Logo fait avec https://patorjk.com/software/taag/
$Logo = "
       ____                    _     _  __  __
      / ___|   _ __     ___   | |_  (_) \ \/ /    _
      \___ \  | '_ \   / _ \  | __| | |  \  /   _| |_
       ___) | | |_) | | (_) | | |_  | |  /  \  |_   _|
      |____/  | .__/   \___/   \__| |_| /_/\_\   |_|
              |_|  ____      _
                  |  _ \ ___| |__   ___  _ __ _ __
                  | |_) / _ \ '_ \ / _ \| '__| '_ \
                  |  _ <  __/ |_) | (_) | |  | | | |
                  |_| \_\___|_.__/ \___/|_|  |_| |_|

       ---------------------------------------------
      /               Made with <3                 /
     /                    v$Version               /
    ----------------------------------------------
"

# Paramètres PowerShell
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function EnterToContinue {
	param (
		[bool] $DefaultPrompt = $false
	)
	if ($DefaultPrompt) {
		Write-Host "Press Enter to continue..." -NoNewLine
	}
	$Host.UI.ReadLine()
}

function SetTitle {
	param (
		[string] $Name
	)
	$Host.UI.RawUI.WindowTitle = "$AppName v$Version - $Name"
}

function StopSpotify {
	$spotify = Get-Process -Name spotify -ErrorAction SilentlyContinue
	if ($spotify) {
		Stop-Process $spotify
	}
}

function RemoveIfExists {
	param (
		[string] $Path
	)
	if (Test-Path -Path $Path) {
		Remove-Item $Path -Recurse
	}
}

function Download {
	param (
		[string] $URL,
		[string] $Path,
		[bool] $Clear = $true
	)
	$webClient = New-Object System.Net.WebClient
	$bufferSize = 8192  # 8KB
	$startTime = Get-Date
	$totalBytesReceived = 0
	$responseStream = $webClient.OpenRead($URL)
	$fileStream = [System.IO.File]::Create($Path)
	$buffer = New-Object byte[] $bufferSize
	$totalBytes = $webClient.ResponseHeaders["Content-Length"]
	$bytesReceived = 0

	while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
		$fileStream.Write($buffer, 0, $readBytes)
		$totalBytesReceived += $readBytes
		$timeElapsed = (Get-Date) - $startTime
		$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
		$percentComplete = ($totalBytesReceived / $totalBytes) * 100
		if ($Clear) {
			Clear-Host
		}
		Write-Progress -Activity "Downloading" -Status "$([math]::Round($percentComplete, 2))% done" -PercentComplete $percentComplete
	}

	$responseStream.Close()
	$fileStream.Close()
}

# Titre fenêtre
SetTitle "Loading"

# Change de répertoire
if ($PSScriptRoot) {
	Set-Location $PSScriptRoot
}

# Génére un nom de fichier de log unique basé sur la date et l'heure
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$log_dir = "$(Get-Location)\SpotiX-Logs"
$log_file_name = "logs_$date.txt"
$log_file_dir = "$log_dir\$log_file_name"

# Crée le répertoire nécessaire pour les logs
if (-not (Test-Path -Path $log_dir)) {
	New-Item -Path $log_dir -ItemType Directory
}

# Commencement des logs
Start-Transcript -Path $log_file_dir

# Vérifie si PowerShell 7 est installé
# PowerShell 7 pas installé => demande à l'utilisateur de l'installer
# PowerShell 7 est installé => exécute le script avec PowerShell 7
function GetPowershellPath {
    $pathsToTest = @(
        # Version MSI
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "$env:ProgramFiles\PowerShell\7-preview\pwsh.exe",
        
        # Version MSIX
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe",
        
        # Version MSI  (user level)
        "$env:LOCALAPPDATA\Programs\PowerShell\7\pwsh.exe",
        "$env:LOCALAPPDATA\Programs\PowerShell\7-preview\pwsh.exe"
    )

    foreach ($path in $pathsToTest) {
        if (Test-Path $path -PathType Leaf) {
            return $path
        }
    }

    $fallbackCommand = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($fallbackCommand) {
        return $fallbackCommand.Source
    }

    return $null
}

if ($args -notcontains "-FromLauncher") {

    # Si le script tourne déjà sous PowerShell 7, on continue dans la fenêtre
    # actuelle. C'est indispensable pour le mode : irm <URL> | iex, car ce
    # mode n'a aucun chemin de fichier dans $PSCommandPath.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "Loading SpotiX+..." -ForegroundColor Yellow
    }
    else {
        $powershellPath = GetPowershellPath

        if (-not $powershellPath) {
            SetTitle "Error"
            Clear-Host
            Write-Host "PowerShell 7 is not installed on this system. It is required to use $AppNameShort.`nWould you like to install it ?" -ForegroundColor Red
            $confirmation = Read-Host -Prompt "(Y/N) "

            if ($confirmation -eq "Y") {
                Clear-Host

                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    Write-Host "Download and installation of PowerShell 7 via Winget..." -ForegroundColor Green
                    Write-Host "Note : You might need to accept an UAC prompt." -ForegroundColor Yellow
                    $wingetArgs = "install --id Microsoft.PowerShell --exact --silent --accept-package-agreements --accept-source-agreements"
                    Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -NoNewWindow
                }
                else {
                    Write-Host "Winget not found. This is normal if you're running Windows 8.1 or Windows 10 LTSC." -ForegroundColor Yellow
                    Write-Host "Falling back to GitHub API..." -ForegroundColor Yellow
                    $response = Invoke-WebRequest "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -UseBasicParsing | ConvertFrom-Json
                    $powershellLatestVersion = $response.tag_name.Substring(1)

                    SetTitle "PowerShell $powershellLatestVersion"
                    Clear-Host
                    Write-Host "Download starting for PowerShell $powershellLatestVersion..." -ForegroundColor Green
                    Write-Host "Note : You might need to accept an UAC prompt." -ForegroundColor Yellow
                    $url = "https://github.com/PowerShell/PowerShell/releases/download/v$powershellLatestVersion/PowerShell-$powershellLatestVersion-win-x64.msi"
                    $fichierLocal = "$env:TEMP\PowerShell-$powershellLatestVersion-win-x64.msi"

                    Download -URL $url -Path $fichierLocal -Clear $false

                    if (Test-Path $fichierLocal) {
                        Write-Host "Download finished, installing..." -ForegroundColor Green
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$fichierLocal`" /quiet" -Verb RunAs -Wait
                    }
                    else {
                        Write-Host "An error occurred during the download." -ForegroundColor Red
                        EnterToContinue -DefaultPrompt $true
                        Stop-Transcript -ErrorAction SilentlyContinue
                        exit
                    }
                }

                $powershellPath = GetPowershellPath
                if (-not $powershellPath) {
                    Write-Host "An error occurred during the installation." -ForegroundColor Red
                    EnterToContinue -DefaultPrompt $true
                    Stop-Transcript -ErrorAction SilentlyContinue
                    exit
                }
            }
            else {
                Clear-Host
                Write-Host "You can close this window by pressing Enter." -ForegroundColor Yellow
                EnterToContinue -DefaultPrompt $true
                Stop-Transcript -ErrorAction SilentlyContinue
                exit
            }
        }

        Write-Host "Loading SpotiX+..." -ForegroundColor Yellow

        # Sous Windows PowerShell 5, irm | iex n'a pas de fichier local.
        # On télécharge donc une copie temporaire avant de lancer PowerShell 7.
        $scriptPath = $PSCommandPath
        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            $scriptPath = Join-Path $env:TEMP "SpotiXPlus-$Version.ps1"

            try {
                Invoke-WebRequest `
                    -Uri "https://github.com/$GithubUser/$GithubRepo/releases/download/nightly/script.ps1" `
                    -OutFile $scriptPath `
                    -UseBasicParsing `
                    -ErrorAction Stop
            }
            catch {
                Write-Host "Unable to download the temporary SpotiX+ script." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                EnterToContinue -DefaultPrompt $true
                Stop-Transcript -ErrorAction SilentlyContinue
                exit
            }
        }

        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            Write-Host "The SpotiX+ script file could not be found: $scriptPath" -ForegroundColor Red
            EnterToContinue -DefaultPrompt $true
            Stop-Transcript -ErrorAction SilentlyContinue
            exit
        }

        Stop-Transcript -ErrorAction SilentlyContinue

        $process = Start-Process `
            -FilePath $powershellPath `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -FromLauncher" `
            -PassThru `
            -ErrorAction SilentlyContinue

        if (-not $process) {
            Write-Host "PowerShell 7 could not be started." -ForegroundColor Red
            EnterToContinue -DefaultPrompt $true
        }

        exit
    }
}


$localizations = @"
{
	"languages_default_regions": {
		"fr": "fr-FR",
		"en": "en-US"
	},
	"translations": {
		"enter-to-continue": {
			"fr-FR": "Appuyez sur Entrée pour continuer...",
			"en-US": "Press Enter to continue..."
		},
		"downloading": {
			"fr-FR": "Téléchargement en cours",
			"en-US": "Downloading"
		},
		"percentage-done": {
			"fr-FR": "complet",
			"en-US": "done"
		},
		"loading": {
			"fr-FR": "Chargement",
			"en-US": "Loading"
		},
		"error": {
			"fr-FR": "Erreur",
			"en-US": "Error"
		},
		"powershell-7-not-installed": {
			"fr-FR": "PowerShell 7 n'est pas installé sur ce système. Ce dernier est nécessaire pour utiliser $AppNameShort.`nSouhaitez-vous l'installer ? (Y/N)",
			"en-US": "PowerShell 7 is not installed on this system. It is required to use $AppNameShort.`nWould you like to install it ? (Y/N)"
		},
		"powershell-7-download-starting": {
			"fr-FR": "Lancement du téléchargement de PowerShell `$powershellLatestVersion...",
			"en-US": "Download starting for PowerShell `$powershellLatestVersion..."
		},
		"powershell-7-download-finished": {
			"fr-FR": "Téléchargement terminé. Lancement de l'installation...",
			"en-US": "Download finished, installing..."
		},
		"powershell-7-installation-prompt": {
			"fr-FR": "Une fois l'installation terminée, appuyez sur Entrée...",
			"en-US": "Once the installation is over, press Enter..."
		},
		"powershell-7-error-installing": {
			"fr-FR": "Une erreur est survenue lors de l'installation.",
			"en-US": "An error occured during the installation."
		},
		"powershell-7-error-downloading": {
			"fr-FR": "Une erreur est survenue lors du téléchargement.",
			"en-US": "An error occured during the downloading."
		},
		"close-window-prompt": {
			"fr-FR": "Vous pouvez fermer cette fenêtre en appuyant sur Entrée.",
			"en-US": "You can close this window by pressing Enter."
		},
		"script-move": {
			"fr-FR": "Déplacement du script a cette adresse : `$newScriptPath",
			"en-US": "Moving the script at this path : `$newScriptPath"
		},
		"script-launch": {
			"fr-FR": "Lancement du script...",
			"en-US": "Launching the script..."
		},
		"no-admin-check": {
			"fr-FR": "Pour pouvoir faire fonctionner correctement le script, celui-ci ne dois pas être lancé en tant qu'administrateur.`nVeuillez redémarrer le script normalement.",
			"en-US": "For the script to work properly, it shouldn't be launched as an administrator.`nPlease restart the scropt normally."
		},
		"online-mode-skip-update": {
			"fr-FR": "Lancé en ligne, pas de vérification de mises à jour",
			"en-US": "Launched in online mode, no checks for updates"
		},
		"update-found": {
			"fr-FR": "Une mise à jour du script à été trouvée",
			"en-US": "An update has been found for the script"
		},
		"update-prompt": {
			"fr-FR": "Voulez-vous la télécharger ? Cela est fortement recommandé. (Y/N)",
			"en-US": "Would you like to download it ? It is strongly recommended. (Y/N)"
		},
		"update-downloaded": {
			"fr-FR": "Mise à jour téléchargée`nAppuyez sur Entrée pour relancer le script mis à jour...",
			"en-US": "Update downloaded`nPress Enter to restart the updated script..."
		},
		"lobby": {
			"fr-FR": "Accueil",
			"en-US": "Main menu"
		},
		"lobby-third-party-apps": {
			"fr-FR": "Apps tierces utilisées: SpotX CLI, Spicetify, SpotiFLAC",
			"en-US": "Third party apps used : SpotX CLI, Spicetify, SpotiFLAC"
		},
		"lobby-warning": {
			"fr-FR": "ATTENTION: Ce script utilise votre connexion internet pour fonctionner correctement.`nNe désactivez pas votre connexion internet pendant l'exécution du script.",
			"en-US": "WARNING : This script uses your Internet connexion to work properly.`nDo not disable your internet connexion during the execution of the script."
		},
		"lobby-menu": {
			"fr-FR": "Que voulez-vous faire ?",
			"en-US": "What do you want to do ?"
		},
		"lobby-menu1": {
			"fr-FR": "Installer $AppNameShort",
			"en-US": "Download $AppNameShort"
		},
		"lobby-menu2": {
			"fr-FR": "Activer/Désactiver la qualité très élevée",
			"en-US": "Enable/Disable high quality"
		},
		"lobby-menu3": {
			"fr-FR": "Configuration de SpotiFLAC",
			"en-US": "SpotiFLAC Configuration"
		},
		"lobby-menu4": {
			"fr-FR": "Configuration de Spicetify",
			"en-US": "Spicetify Configuration"
		},
		"lobby-menu5": {
			"fr-FR": "Créer un raccourci sur le bureau",
			"en-US": "Create shortcut on your desktop"
		},
		"lobby-menu6": {
			"fr-FR": "Désinstaller $AppNameShort",
			"en-US": "Uninstall $AppNameShort"
		},
		"lobby-menu7": {
			"fr-FR": "Ouvrir la page GitHub",
			"en-US": "Open GitHub Webpage"
		},
		"lobby-menu8": {
			"fr-FR": "Rejoindre notre serveur Discord",
			"en-US": "Join our Discord server"
		},
		"lobby-menu9": {
			"fr-FR": "Fermer le script",
			"en-US": "Close the script"
		},
		"lobby-menu7-openning-github": {
			"fr-FR": "Ouverture de la page GitHub...",
			"en-US": "Openning the GitHub Webpage..."
		},
		"lobby-menu8-openning-discord": {
			"fr-FR": "Ouverture du lien d'invitation Discord...",
			"en-US": "Openning the Discord join link..."
		},
		"lobby-menu9-goodbye": {
			"fr-FR": "A bientôt !",
			"en-US": "See you soon !"
		},
		"msstore-check-found": {
			"fr-FR": "Une version de Spotify venant du Microsoft Store (UWP) a été détectée. (Version : `$ms_version)",
			"en-US": "A version of Spotify coming from the Microsoft Store (UWP) has been found. (Version : `$ms_version)"
		},
		"msstore-check-warning": {
			"fr-FR": "Cette version peut être utilisée en paralèle de $AppNameShort, mais cela crééra deux versions de Spotify sur votre système.",
			"en-US": "This version can be usable alongside $AppNameShort, but it will create two versions of Spotify on your system."
		},
		"msstore-check-prompt": {
			"fr-FR": "Voulez-vous la désinstaller ? (Vous devez être administrateur !) (Y/N)",
			"en-US": "Would you like to uninstall it ? (You need to be an adminitrator !) (Y/N)"
		},
		"msstore-check-uninstalling": {
			"fr-FR": "Désinstalltion de Spotify UWP `$ms_version...",
			"en-US": "Uninstalling Spotify UWP `$ms_version..."
		},
		"msstore-check-uninstall-failed": {
			"fr-FR": "La désinstalltion à échoué.",
			"en-US": "The uninstallation failed."
		},
		"retry": {
			"fr-FR": "Réessayer ? (Y/N)",
			"en-US": "Retry ? (Y/N)"
		},
		"script-will-continue": {
			"fr-FR": "Le script va continuer...",
			"en-US": "The script will continue..."
		},
		"msstore-check-uninstalled-successfully": {
			"fr-FR": "Spotify UWP a été désinstallé avec succès !",
			"en-US": "Spotify UWP has been successfully uninstalled !"
		},
		"spotify-check-found": {
			"fr-FR": "Une installation de Spotify incompatible a été détectée. Pour le bon fonctionnement du script, vous devez la désinstaller.`nNous pouvons le faire pour vous.",
			"en-US": "An uncompatible installation of Spotify has been detected. For the well being of the script, you need to uninstall it.`nWe can do it for you."
		},
		"spotify-check-prompt": {
			"fr-FR": "Voulez-vous désinstaller Spotify ? (Y/N)",
			"en-US": "Would you like to uninstall Spotify ? (Y/N)"
		},
		"spotify-check-uninstalling": {
			"fr-FR": "Lancement de la désinstallation de Spotify...",
			"en-US": "Launching the uninstallation of Spotify..."
		},
		"spotify-check-uninstalling-failed": {
			"fr-FR": "La désinstallation de Spotify a échoué. Appuyez sur Entrée pour recommencer...",
			"en-US": "The uninstallation of Spotify failed. Press Enter to retry..."
		},
		"spotify-check-uninstall-successful": {
			"fr-FR": "Spotify a correctement été désinstallé !",
			"en-US": "Spotify was correctly installed !"
		},
		"spotify-check-returning": {
			"fr-FR": "Impossible d'installer $AppNameShort. Retour au menu principal dans 3 secondes...",
			"en-US": "Could not install $AppNameShort. Returning to the main menu in 3 seconds..."
		},
		"app-install-version-choice-prompt": {
			"fr-FR": "Quelle version de Spotify souhaitez-vous ?",
			"en-US": "Which Spotify version would you like ?"
		},
		"app-install-version-choice-version1": {
			"fr-FR": "Nouvelle interface - Dernière version    - Compatible avec Windows 11/10     - Plugin externe compatible - EXPERIMENTAL",
			"en-US": "New UI - Latest version      - Compatible with Windows 11/10     - External plugins compatible - EXPERIMENTAL"
		},
		"app-install-version-choice-version2": {
			"fr-FR": "Nouvelle interface - Version 1.2.78.418 - Compatible avec Windows 11/10     - Plugin externe compatible - Stable",
			"en-US": "New UI - Version 1.2.78.418 - Compatible with Windows 11/10     - External plugins compatible - Stable"
		},
		"app-install-version-choice-version3": {
			"fr-FR": "Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Plugin externe instable   - Instable",
			"en-US": "Old UI - Version 1.2.5.1006  - Compatible with Windows 11/10/8.1 - External plugins unstable   - Unstable"
		},
		"app-install-version-choice-more-info": {
			"fr-FR": "Pour en savoir plus sur les différences entre les versions, consultez la page tutoriel PC du site $AppNameShort (1/2/3)",
			"en-US": "To learn more about the differences between each versions, please consult the wiki of the $AppNameShort website (1/2/3)"
		},
		"installation": {
			"fr-FR": "Installation",
			"en-US": "Installation"
		},
		"downloading-and-installing": {
			"fr-FR": "Téléchargement et installation de Spotify...",
			"en-US": "Downloading and installing Spotify..."
		},
		"spotify-install-warning": {
			"fr-FR": "Avant de continuer, connectez-vous à votre compte Spotify afin d’éviter les déconnexions répétées.",
			"en-US": "Before continuing, log in to your Spotify account to avoid repeated disconnections."
		},
		"spotify-install-prompt": {
			"fr-FR": "Une fois Spotify installé, veuillez presser la touche Entrée...",
			"en-US": "Once Spotify is installed, please press the Enter key..."
		},
		"spotx-cli-download": {
			"fr-FR": "Téléchargement/Installation de SpotX CLI...",
			"en-US": "Downloading/Installing SpotX CLI..."
		},
		"spotx-configuration": {
			"fr-FR": "Configuration de SpotX",
			"en-US": "SpotX Configuration"
		},
		"spotx-installed": {
			"fr-FR": "Script 1/2 installés : SpotX",
			"en-US": "Script 1/2 installe