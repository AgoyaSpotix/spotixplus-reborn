# Constantes
$AppNameShort = "SpotiX+"
$AppName = "$AppNameShort PC Script"
$Version = "3.0 rc1"
$ByPassAdmin = $false
$NoTranslations = $false

$GithubUser = "AgoyaSpotix"
$GithubRepo = "spotixplus-reborn"
$Discord = "https://discord.gg/p3AAf7TUPv"
$DiscordApplicationId = "1534250854087921725"
$DiscordLargeImageKey = "spotixplus"
$SpotiXWebsite = "https://spotixplus.fr"
$SpotiXGithub = "https://github.com/$GithubUser/$GithubRepo"

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

# Génère un nom de fichier de log unique basé sur la date et l'heure
$date = Get-Date -Format "yyyyMMdd_HHmmss"

# Ne pas utiliser Get-Location ici : avec irm | iex, PowerShell peut démarrer
# dans C:\Windows\System32, où un utilisateur standard ne peut pas écrire.
$log_base_dir = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { $env:TEMP }
$log_dir = Join-Path $log_base_dir "SpotiX-Logs"
$log_file_name = "logs_$date.txt"
$log_file_dir = Join-Path $log_dir $log_file_name

# Crée le répertoire nécessaire pour les logs dans un emplacement utilisateur.
if (-not (Test-Path -LiteralPath $log_dir)) {
	New-Item -Path $log_dir -ItemType Directory -Force | Out-Null
}

# Commencement des logs
Start-Transcript -Path $log_file_dir -Force

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
			"fr-FR": "Configurer la Rich Presence Discord",
			"en-US": "Configure Discord Rich Presence"
		},
		"lobby-menu7": {
			"fr-FR": "Désinstaller $AppNameShort",
			"en-US": "Uninstall $AppNameShort"
		},
		"lobby-menu8": {
			"fr-FR": "Ouvrir la page GitHub",
			"en-US": "Open GitHub Webpage"
		},
		"lobby-menu9": {
			"fr-FR": "Rejoindre notre serveur Discord",
			"en-US": "Join our Discord server"
		},
		"lobby-menu10": {
			"fr-FR": "Fermer le script",
			"en-US": "Close the script"
		},
		"lobby-menu8-openning-github": {
			"fr-FR": "Ouverture de la page GitHub...",
			"en-US": "Openning the GitHub Webpage..."
		},
		"lobby-menu9-openning-discord": {
			"fr-FR": "Ouverture du lien d'invitation Discord...",
			"en-US": "Openning the Discord join link..."
		},
		"lobby-menu10-goodbye": {
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
			"fr-FR": "Nouvelle interface - Version 1.2.78.418 - Compatible avec Windows 11/10     - Plugin externe compatible - Stable, `e[1mRECOMMANDÉ`e[0m",
			"en-US": "New UI - Version 1.2.78.418 - Compatible with Windows 11/10     - External plugins compatible - Stable, `e[1mRECOMMANDED`e[0m"
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
			"en-US": "Script 1/2 installed : SpotX"
		},
		"spotify-closing": {
			"fr-FR": "Fermeture de Spotify pour faciliter l'exécution des scripts",
			"en-US": "Closing Spotify to facilitate the execution of the scripts"
		},
		"creating-necessary-folder": {
			"fr-FR": "Création des dossiers nécessaires",
			"en-US": "Creating necessary folders"
		},
		"spicetify-configuration": {
			"fr-FR": "Configuration de Spicetify",
			"en-US": "Spicetify Configuration"
		},
		"spicetify-installed": {
			"fr-FR": "Script 2/2 installés : Spicetify",
			"en-US": "Script 2/2 installed : Spicetify"
		},
		"spicetify-installed2": {
			"fr-FR": "Spicetify est installée",
			"en-US": "Spicetify installed"
		},
		"app-configuration": {
			"fr-FR": "Configuration de $AppNameShort",
			"en-US": "Configuring $AppNameShort"
		},
		"download-app-files": {
			"fr-FR": "Une erreur s'est produite durant le téléchargement des fichiers nécessaires`nNe retentez pas de lancer le script, cela pourrait générer des conflits`nMerci de contacter le support de $AppNameShort",
			"en-US": "An error occured during the downloading of the necessary files`nDo not try to relaunch the script, it can cause conflits`nPlease contact the $AppNameShort"
		},
		"spicetify-plugins": {
			"fr-FR": "Plugins Spicetify",
			"en-US": "Spicetify plugins"
		},
		"spicetify-plugins-prompt": {
			"fr-FR": "Spicetify propose 3 plugins externes pouvant améliorer l'expérience utilisateur",
			"en-US": "Spicetify proposes 3 external plugins that can improve the user experience"
		},
		"spicetify-plugins-prompt-2": {
			"fr-FR": "Souhaitez vous installer des plugins externes ?",
			"en-US": "Would you like to install external plugins ?"
		},
		"spicetify-plugins-plugin-1": {
			"fr-FR": "Reddit: récupérez des messages de n'importe quel subreddit de partage de liens Spotify",
			"en-US": "Reddit: get messages from any Spotify sharing links subreddits"
		},
		"spicetify-plugins-plugin-2": {
			"fr-FR": "Lyrics-plus: accédez aux paroles du titre actuel grâce à divers fournisseurs,`n                tels que Musixmatch, Netease et Genius",
			"en-US": "Lyrics-plus: access to lyrics of the current title thanks to multiple providers,`n                such as Musixmatch, Netease and Genius"
		},
		"spicetify-plugins-plugin-3": {
			"fr-FR": "New-releases: regroupez toutes les nouvelles sorties de vos artistes et podcasts préférés",
			"en-US": "New-releases: regroup new releases from your favorite artists and podcasts"
		},
		"spicetify-plugins-prompt-3": {
			"fr-FR": "Vous pouvez choisir plusieurs plugins externes en mettant une virgule entre chaque nombre (ex : 2,3)`nAppuyez sur Entrer en laissant vide pour ne rien installer",
			"en-US": "You have the choice between multiple plugins by putting a comma (ex : 2,3)`nPress Enter while leaving it empty to install none of them"
		},
		"spicetify-plugin-reddit-installing": {
			"fr-FR": "Installation du plugin externe \"Reddit\"...",
			"en-US": "Installing external plugin \"Reddit\"..."
		},
		"spicetify-plugin-reddit-installing-success": {
			"fr-FR": "Plugin externe \"Reddit\" installé avec succès !",
			"en-US": "External plugin \"Reddit\" installed successfully !"
		},
		"spicetify-plugin-lyricsplus-installing": {
			"fr-FR": "Installation du plugin externe \"Lyrics-plus\"...",
			"en-US": "Installing external plugin \"Lyrics-plus\"..."
		},
		"spicetify-plugin-lyricsplus-installing-success": {
			"fr-FR": "Plugin externe \"Lyrics-plus\" installé avec succès !",
			"en-US": "External plugin \"Lyrics-plus\" installed successfully !"
		},
		"spicetify-plugin-newreleases-installing": {
			"fr-FR": "Installation du plugin externe \"New-releases\"...",
			"en-US": "Installing external plugin \"New-releases\"..."
		},
		"spicetify-plugin-newreleases-installing-success": {
			"fr-FR": "Plugin externe \"New-releases\" installé avec succès !",
			"en-US": "External plugin \"New-releases\" installed successfully !"
		},
		"install-finished": {
			"fr-FR": "Installation terminée",
			"en-US": "Installation finished"
		},
		"configuration-finished": {
			"fr-FR": "Fin de la configuration de $AppNameShort...",
			"en-US": "End of the configuration of $AppNameShort..."
		},
		"install-successful": {
			"fr-FR": "$AppNameShort installé avec succès !",
			"en-US": "$AppNameShort installed successfully !"
		},
		"uninstall-app-not-found": {
			"fr-FR": "Vous ne pouvez pas désinstaller $AppNameShort car celui-ci n'est pas installé.",
			"en-US": "You cannot uninstall $AppNameShort since it isn't installed."
		},
		"uninstall-app-confirmation": {
			"fr-FR": "Êtes vous sûr de vouloir désinstaller $AppNameShort et tout ses composants ? (Y/N)",
			"en-US": "Are you sure to uninstall $AppNameShort and its components ? (Y/N)"
		},
		"uninstalling": {
			"fr-FR": "Désinstallation",
			"en-US": "Unintallation"
		},
		"uninstall-starting": {
			"fr-FR": "Lancement de la désinstallation de $AppNameShort...",
			"en-US": "Starting the uninstallation of $AppNameShort..."
		},
		"spotify-uninstall": {
			"fr-FR": "Désinstallation de Spotify...",
			"en-US": "Deleting Spotify..."
		},
		"spotify-uninstall-fail": {
			"fr-FR": "La désinstallation de Spotify a échouée ou a été annulée. Appuyez sur Entrée pour retourner au menu principal...",
			"en-US": "The uninstallation of Spotify failed or was cancelled. Please press Enter to return to the main menu..."
		},
		"spicetify-uninstalling": {
			"fr-FR": "Suppresion de Spicetify...",
			"en-US": "Deleting Spicetify..."
		},
		"spotiflac-uninstalling": {
			"fr-FR": "Suppresion de SpotiFLAC...",
			"en-US": "Deleting SpotiFLAC..."
		},
		"spotify-uninstall-complete": {
			"fr-FR": "Suppresion des résidus de Spotify...",
			"en-US": "Deleting residual files from Spotify..."
		},
		"spotx-uninstall": {
			"fr-FR": "Suppresion de SpotX...",
			"en-US": "Deleting SpotX..."
		},
		"soggfy-uninstall": {
			"fr-FR": "Suppression de Soggfy...",
			"en-US": "Deleting Soggfy..."
		},
		"app-uninstalled-successfully": {
			"fr-FR": "$AppNameShort désinstallé avec succès !",
			"en-US": "$AppNameShort uninstalled successfully !"
		},
		"cancelling": {
			"fr-FR": "Annulation...",
			"en-US": "Canceling..."
		},
		"audio-configuration": {
			"fr-FR": "Configuration Audio",
			"en-US": "Audio Configuration"
		},
		"app-installed-check": {
			"fr-FR": "$AppNameShort n'est pas installé sur votre PC, merci de l'installer d'abord.",
			"en-US": "$AppNameShort is not installed on your PC, please install it first."
		},
		"audio-warning": {
			"fr-FR": "ATTENTION: ne démarrez pas $AppNameShort pendant ce processus, cela pourrait engendrer des conflits",
			"en-US": "WARNING: do not start $AppNameShort during the processus, it could cause conflits"
		},
		"audio-prompt": {
			"fr-FR": "Quelle qualité audio souhaitez-vous ?",
			"en-US": "Which audio quality would you like ?"
		},
		"audio-high": {
			"fr-FR": "Qualité très élevée",
			"en-US": "High quality"
		},
		"audio-low": {
			"fr-FR": "Qualité basique (réglable depuis $AppNameShort)",
			"en-US": "Basic quality (adjustable in $AppNameShort)"
		},
		"audio-no-changes": {
			"fr-FR": "Laisser tel quel",
			"en-US": "Do not change it"
		},
		"audio-high-configuration": {
			"fr-FR": "Configuration de la qualité très élevée",
			"en-US": "Configuring the high quality"
		},
		"audio-error": {
			"fr-FR": "Une erreur s'est produite durant le téléchargement des fichiers nécessaires.`nNe retentez pas de lancer le script, cela pourrait faire des conflits`nMerci de contacter le support de $AppNameShort",
			"en-US": "An error occured during the installation of the necessary files.`nDo not try to relaunch the script, it can cause conflits`nPlease contact the $AppNameShort"
		},
		"closing-window": {
			"fr-FR": "Fermeture de la fenêtre...",
			"en-US": "Closing the window..."
		},
		"audio-high-done": {
			"fr-FR": "La qualité très élevée est appliquée !",
			"en-US": "High quality has been successfully applied !"
		},
		"audio-low-configuration": {
			"fr-FR": "Suppresion de la qualité très élévée",
			"en-US": "Removing the high quality"
		},
		"audio-low-done": {
			"fr-FR": "La qualité très élevée a été supprimée avec succès !",
			"en-US": "High quality removed successfully !"
		},
		"soggfy": {
			"fr-FR": "Fonctionnalité de téléchargement",
			"en-US": "Download feature"
		},
		"soggfy-already-installed": {
			"fr-FR": "Le mode téléchargement est déjà activé pour $AppNameShort",
			"en-US": "The download feature has already been enabled for $AppNameShort"
		},
		"soggfy-compatible-versions": {
			"fr-FR": "Voici les versions compatible avec la fonctionnalitée de téléchargement :",
			"en-US": "Here are the compatible versions with the download feature :"
		},
		"soggfy-compatible-versions-v1": {
			"fr-FR": "Nouvelle interface - Dernière version    - Compatible avec Windows 11/10     - Mode téléchargement instable",
			"en-US": "New UI - Latest version      - Compatible with Windows 11/10     - Download feature unstable"
		},
		"soggfy-compatible-versions-v2": {
			"fr-FR": "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10     - Mode téléchargement compatible",
			"en-US": "New UI - Version 1.2.31.1205 - Compatible with Windows 11/10     - Download feature compatible"
		},
		"soggfy-compatible-versions-v3": {
			"fr-FR": "Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Mode téléchargement instable",
			"en-US": "Old UI - Version 1.2.5.1006  - Compatible with Windows 11/10/8.1 - Download feature unstable"
		},
		"soggfy-warning": {
			"fr-FR": "Le fonctionnement du mode téléchargement n'est pas garanti sur les versions \"instables\".`nIl est tout de même possible que cela fonctionne, n'hésitez pas à tester !",
			"en-US": "The download feature is not guaranteed to work on \"unstable\" versions.`nBut there is still a chance it could work, so you can try it !"
		},
		"soggfy-speech": {
			"fr-FR": "La fonctionnalité de téléchargement permet de télécharger vos musiques préférées juste en les écoutant !`nIl suffit d'écouter la musique que vous souhaitez télécharger en entier, et celle-ci sera automatiquement enregistrée.`nVos musiques téléchargées seront disponible dans votre dossier Musique, puis Soggfy.`nPour en savoir plus, veuillez consulter le tutoriel ici : https://github.com/AgoyaSpotix/spotixplus-reborn/blob/main/tutos/tuto-telechargement.md",
			"en-US": "The download feature allows you to download your favorite songs while listening to them !`nYou just have to listen to the song you want to donwload in its entirety, and it will be automatically downloaded.`nYour songs will be avaiable in your Musics folder, then Soggfy.`nTo learn more about it, please consult the wiki there : https://github.com/AgoyaSpotix/spotixplus-reborn/blob/main/tutos/tuto-telechargement.md"
		},
		"soggfy-confirm": {
			"fr-FR": "Souhaitez-vous activer la fonctionnalité de téléchargement ? (Y/N)",
			"en-US": "Would you like to enable the download feature ? (Y/N)"
		},
		"installing-necessary-files": {
			"fr-FR": "Installation des fichiers nécessaire",
			"en-US": "Installing necessary files"
		},
		"installing-ffmpeg": {
			"fr-FR": "Installation de FFMPEG",
			"en-US": "Installing FFMPEG"
		},
		"soggfy-success": {
			"fr-FR": "La fonctionnalité de téléchargement est installée avec succès !",
			"en-US": "The download feature has been enabled successfully"
		},
		"soggfy-dead": {
			"fr-FR": "Malheureusement, Soggfy n’est plus maintenu par ses développeurs. `nNous avons donc dû le retirer, car il ne fonctionne plus. Nous vous proposons toutefois une alternative.",
			"en-US": "Unfortunately, Soggfy is no longer maintained by its developers and no longer works properly. `nWe’ve therefore had to remove it, but don’t worry — an alternative is available!"
		},
		"soggfy-dead1": {
			"fr-FR": "SpotiFLAC est un outil simple et pratique qui vous permet de télécharger facilement vos musiques en qualité Hi-Res FLAC certifiée, avec les pochettes d’album et les paroles ! `nhttps://github.com/spotbye/SpotiFLAC",
			"en-US": "SpotiFLAC is a simple and convenient tool that lets you easily download your music in certified Hi-Res FLAC quality, complete with album artwork and lyrics! `nhttps://github.com/spotbye/SpotiFLAC"
		},
		"spicetify-helper": {
			"fr-FR": "Configuration de Spicetify",
			"en-US": "Spicetify Configuration"
		},
		"spicetify-ok": {
			"fr-FR": "Spicetify installé",
			"en-US": "Spicetify installed"
		},
		"spicetify-no": {
			"fr-FR": "Spicetify non installé",
			"en-US": "Spicetify not installed"
		},
		"spicetify-configh": {
			"fr-FR": "Vous pouvez installer ou désinstaller Spicetify en cas de problème.",
			"en-US": "You can install or uninstall Spicetify if you’re experiencing any issues."
		},
		"spicetify-configh1": {
			"fr-FR": "Que souhaitez-vous faire ?",
			"en-US": "What would you like to do?"
		},
		"spicetify-install": {
			"fr-FR": "Installer Spicetify",
			"en-US": "Install Spicetify"
		},
		"spicetify-uninstall": {
			"fr-FR": "Désintaller Spicetify",
			"en-US": "Uninstall Spicetify"
		},
		"spicetify-uninstall-done": {
			"fr-FR": "Désinstallation de Spicetify terminée",
			"en-US": "Spicetify uninstall completed"
		},
		"return": {
			"fr-FR": "Retourner à la page d'accueil",
			"en-US": "Return to the home page"
		},
		"create-shortcut-on-desktop-title": {
			"fr-FR": "Créer un raccourci sur le bureau",
			"en-US": "Create shortcut on the desktop"
		},
		"create-shortcut-on-desktop": {
			"fr-FR": "Souhaitez-vous créer un raccourci SpotiX+ sur le bureau ?",
			"en-US": "Would you like to create a desktop shortcut for SpotiX+?"
		},
		"create-shortcut": {
			"fr-FR": "Créer le raccourci",
			"en-US": "Create shortcut"
		},
		"create-shortcut-done": {
			"fr-FR": "Le raccourci à était créé sur le bureau !",
			"en-US": "The shortcut has been created on the desktop!"
		},
		"spotiflac": {
			"fr-FR": "Configuration de SpotiFLAC",
			"en-US": "SpotiFLAC Configuration"
		},
		"spotiflac-confirm": {
			"fr-FR": "Souhaitez-vous l'installer sur votre PC ?",
			"en-US": "Would you like to install it on your PC?"
		},
		"spotiflac-ok": {
			"fr-FR": "Installer SpotiFLAC",
			"en-US": "Install SpotiFLAC"
		},
		"spotiflac-error1": {
			"fr-FR": "Une erreur est survenue avec le dépôt GitHub : aucun fichier exécutable n’a été trouvé. Merci de contacter l’administrateur du script.",
			"en-US": "An error occurred with the GitHub repository: no executable file was found. Please contact the script administrator."
		},
		"spotiflac-error2": {
		"fr-FR": "Une erreur est survenue lors du téléchargement. Le fichier semble corrompu. Veuillez réessayer dans quelques instants.",
		"en-US": "An error occurred during the download. The file appears to be corrupted. Please try again in a few moments."
		},
		"spotiflac-download": {
		"fr-FR": "Téléchargement de SpotiFLAC `$(`$Release.tag_name)...",
		"en-US": "Downloading SpotiFLAC `$(`$Release.tag_name)..."
		},
		"spotiflac-done": {
		"fr-FR": "SpotiFLAC a été installé avec succès !",
		"en-US": "SpotiFLAC was installed successfully!"
		},
		"spotiflac-location": {
		"fr-FR": "Emplacement : `$SpotiFLACExe",
		"en-US": "Location : `$SpotiFLACExe"
		},
		"spotiflac-install-error": {
		"fr-FR": "Une erreur est survenue lors de l’installation de SpotiFLAC.",
		"en-US": "An error occurred while installing SpotiFLAC."
		},
		"discord-rpc-title": {
			"fr-FR": "Rich Presence Discord",
			"en-US": "Discord Rich Presence"
		},
		"discord-rpc-confirm": {
			"fr-FR": "Souhaitez-vous activer la Rich Presence Discord de SpotiX+ ?",
			"en-US": "Would you like to enable SpotiX+ Discord Rich Presence?"
		},
		"discord-rpc-enable": {
			"fr-FR": "Activer la Rich Presence",
			"en-US": "Enable Rich Presence"
		},
		"discord-rpc-disable": {
			"fr-FR": "Ne pas l'activer",
			"en-US": "Do not enable it"
		},
		"discord-rpc-installing": {
			"fr-FR": "Installation de la Rich Presence Discord...",
			"en-US": "Installing Discord Rich Presence..."
		},
		"discord-rpc-installed": {
			"fr-FR": "La Rich Presence Discord a été activée avec succès !",
			"en-US": "Discord Rich Presence has been enabled successfully!"
		},
		"discord-rpc-disabled": {
			"fr-FR": "La Rich Presence Discord est désactivée.",
			"en-US": "Discord Rich Presence is disabled."
		},
		"discord-rpc-error": {
			"fr-FR": "Une erreur est survenue pendant l'installation de la Rich Presence Discord.",
			"en-US": "An error occurred while installing Discord Rich Presence."
		},
		"companion-installing": {
			"fr-FR": "Installation de SpotiX+ Companion...",
			"en-US": "Installing SpotiX+ Companion..."
		},
		"companion-installed": {
			"fr-FR": "SpotiX+ Companion a été installé avec succès !",
			"en-US": "SpotiX+ Companion was installed successfully!"
		},
		"companion-error": {
			"fr-FR": "Une erreur est survenue pendant l’installation de SpotiX+ Companion.",
			"en-US": "An error occurred while installing SpotiX+ Companion."
		},
		"companion-spotify-not-found": {
			"fr-FR": "Spotify doit être installé avant SpotiX+ Companion.",
			"en-US": "Spotify must be installed before SpotiX+ Companion."
		}
	}
}
"@ | ConvertFrom-Json -AsHashtable
$language_id = (Get-Culture).Name
$language_id_defaulted = $localizations["languages_default_regions"][$language_id.Substring(0, 2)]

function RemoveIfExists {
	param (
		[string] $Path
	)
	if (Test-Path -Path $Path) {
		Remove-Item $Path -Recurse
	}
}
function GetTranslation {
	param (
		[string] $string_id
	)
	# No such string ID
	if ($NoTranslations -or -not $localizations["translations"].ContainsKey($string_id)) {
		return $string_id
	}
	# Language found
	if ($localizations["translations"][$string_id].ContainsKey($language_id)) {
		return $localizations["translations"][$string_id][$language_id]
	}
	# Language for default region found
	if (($language_id_defaulted -ne $null) -and ($localizations["translations"][$string_id].ContainsKey($language_id_defaulted))) {
		return $localizations["translations"][$string_id][$language_id_defaulted]
	}
	# Defaults to en-US
	if ($localizations["translations"][$string_id].ContainsKey("en-US")) {
		return $localizations["translations"][$string_id]["en-US"]
	}
	# No translations found for this string ID
	return $string_id
}

# Verification admin ou pas
if ((-not $ByPassAdmin) -and ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Host (GetTranslation "no-admin-check") -ForegroundColor Red
	EnterToContinue -DefaultPrompt $true
	exit 1
}

function PrintLogo {
	Clear-Host
	Write-Host $Logo -ForegroundColor Green
	Write-Host ""
}

function GetUserChoices {
	param (
		[string[]]$validResponses,
		[bool] $Multiple = $false
	)

	$responses = $null
	do {
		Write-Host " > " -NoNewLine
		$responses = $Host.UI.ReadLine().Replace(" ", "")
		if ($Multiple) {
			$responses = $responses.Split(",") -ne ''
		}
	} while ($responses -eq $null)

	return $responses
}


function StopDiscordRichPresence {
    $PresenceFolder = Join-Path $env:LOCALAPPDATA "SpotiXPresence"
    $PidFile = Join-Path $PresenceFolder "SpotiXPresence.pid"

    if (-not (Test-Path -LiteralPath $PidFile -PathType Leaf)) {
        return
    }

    try {
        $PresencePid = [int](Get-Content -LiteralPath $PidFile -Raw -ErrorAction Stop).Trim()
        $PresenceProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $PresencePid" -ErrorAction SilentlyContinue

        if ($PresenceProcess -and $PresenceProcess.CommandLine -like "*SpotiXPresence.ps1*") {
            Stop-Process -Id $PresencePid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 300
        }
    }
    catch {
        # Le processus n'existe probablement plus
    }

    Remove-Item -LiteralPath $PidFile -Force -ErrorAction SilentlyContinue
}

function RemoveDiscordRichPresence {
    StopDiscordRichPresence

    $PresenceFolder = Join-Path $env:LOCALAPPDATA "SpotiXPresence"
    $StartupFolder = [Environment]::GetFolderPath("Startup")
    $StartupShortcut = Join-Path $StartupFolder "SpotiXPresence.lnk"

    Remove-Item -LiteralPath $StartupShortcut -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $PresenceFolder -Recurse -Force -ErrorAction SilentlyContinue
}

function InstallDiscordRichPresence {
    SetTitle (GetTranslation "discord-rpc-title")
    PrintLogo

    $RichPresenceChoice = Read-Host -Prompt ((
        (GetTranslation "discord-rpc-confirm"),
		"1. $(GetTranslation 'discord-rpc-enable')",
		"2. $(GetTranslation 'discord-rpc-disable')"
    ) -join "`n")

    if ($RichPresenceChoice -ne "1") {
        RemoveDiscordRichPresence
        Write-Host (GetTranslation "discord-rpc-disabled") -ForegroundColor Yellow
        EnterToContinue -DefaultPrompt $true
        return
    }

    Write-Host (GetTranslation "discord-rpc-installing") -ForegroundColor Yellow

    $PresenceFolder = Join-Path $env:LOCALAPPDATA "SpotiXPresence"
    $PresenceScript = Join-Path $PresenceFolder "SpotiXPresence.ps1"
    $StartupFolder = [Environment]::GetFolderPath("Startup")
    $StartupShortcut = Join-Path $StartupFolder "SpotiXPresence.lnk"
    $WindowsPowerShell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

    try {
        StopDiscordRichPresence
        New-Item -ItemType Directory -Path $PresenceFolder -Force | Out-Null

        $PresenceSource = @'
$ErrorActionPreference = "SilentlyContinue"

$ClientId = "__CLIENT_ID__"
$LargeImageKey = "__LARGE_IMAGE_KEY__"
$SpotiXVersion = "__VERSION__"
$WebsiteUrl = "__WEBSITE_URL__"
$GithubUrl = "__GITHUB_URL__"
$PresenceName = "SpotiX+ Reborn"
$PresenceDetails = "Custom Spotify"

$PresenceFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$PidFile = Join-Path $PresenceFolder "SpotiXPresence.pid"
$LogFile = Join-Path $PresenceFolder "SpotiXPresence.log"

function Write-PresenceLog {
    param([string] $Message)

    try {
        if ((Test-Path -LiteralPath $LogFile) -and ((Get-Item -LiteralPath $LogFile).Length -gt 262144)) {
            Remove-Item -LiteralPath $LogFile -Force -ErrorAction SilentlyContinue
        }
        Add-Content -LiteralPath $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" -Encoding UTF8
    }
    catch {
    }
}

$CreatedNew = $false
$PresenceMutex = [System.Threading.Mutex]::new($true, "Local\SpotiXPresence", [ref]$CreatedNew)
if (-not $CreatedNew) {
    exit
}

try {
    Set-Content -LiteralPath $PidFile -Value $PID -Encoding ASCII -Force
}
catch {
}

try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class SpotiXPipeNative
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool PeekNamedPipe(
        IntPtr hNamedPipe,
        IntPtr lpBuffer,
        uint nBufferSize,
        IntPtr lpBytesRead,
        out uint lpTotalBytesAvail,
        IntPtr lpBytesLeftThisMessage
    );
}
"@
}
catch {
}

function Write-RpcFrame {
    param(
        [System.IO.Pipes.NamedPipeClientStream] $Pipe,
        [int] $Opcode,
        [byte[]] $PayloadBytes
    )

    $Header = New-Object byte[] 8
    [Array]::Copy([BitConverter]::GetBytes([int]$Opcode), 0, $Header, 0, 4)
    [Array]::Copy([BitConverter]::GetBytes([int]$PayloadBytes.Length), 0, $Header, 4, 4)

    $Pipe.Write($Header, 0, $Header.Length)
    if ($PayloadBytes.Length -gt 0) {
        $Pipe.Write($PayloadBytes, 0, $PayloadBytes.Length)
    }
    $Pipe.Flush()
}

function Write-RpcJson {
    param(
        [System.IO.Pipes.NamedPipeClientStream] $Pipe,
        [int] $Opcode,
        [object] $Payload
    )

    $Json = $Payload | ConvertTo-Json -Depth 12 -Compress
    $PayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($Json)
    Write-RpcFrame -Pipe $Pipe -Opcode $Opcode -PayloadBytes $PayloadBytes
}

function Read-ExactBytes {
    param(
        [System.IO.Pipes.NamedPipeClientStream] $Pipe,
        [int] $Count,
        [int] $TimeoutMilliseconds = 3000
    )

    $Buffer = New-Object byte[] $Count
    $Offset = 0

    while ($Offset -lt $Count) {
        $AsyncResult = $Pipe.BeginRead($Buffer, $Offset, $Count - $Offset, $null, $null)
        try {
            if (-not $AsyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
                throw "Discord RPC read timeout."
            }
            $Read = $Pipe.EndRead($AsyncResult)
        }
        finally {
            $AsyncResult.AsyncWaitHandle.Close()
        }

        if ($Read -le 0) {
            throw "Discord RPC connection closed."
        }
        $Offset += $Read
    }

    return ,$Buffer
}

function Read-RpcFrame {
    param([System.IO.Pipes.NamedPipeClientStream] $Pipe)

    $Header = Read-ExactBytes -Pipe $Pipe -Count 8
    $Opcode = [BitConverter]::ToInt32($Header, 0)
    $PayloadLength = [BitConverter]::ToInt32($Header, 4)

    if ($PayloadLength -lt 0 -or $PayloadLength -gt 1048576) {
        throw "Invalid Discord RPC payload length."
    }

    $PayloadBytes = if ($PayloadLength -gt 0) {
        Read-ExactBytes -Pipe $Pipe -Count $PayloadLength
    }
    else {
        New-Object byte[] 0
    }

    [PSCustomObject]@{
        Opcode = $Opcode
        PayloadBytes = $PayloadBytes
        PayloadText = [System.Text.Encoding]::UTF8.GetString($PayloadBytes)
    }
}

function Get-PipeAvailableBytes {
    param([System.IO.Pipes.NamedPipeClientStream] $Pipe)

    [uint32]$Available = 0
    $Handle = $Pipe.SafePipeHandle.DangerousGetHandle()
    $Success = [SpotiXPipeNative]::PeekNamedPipe(
        $Handle,
        [IntPtr]::Zero,
        0,
        [IntPtr]::Zero,
        [ref]$Available,
        [IntPtr]::Zero
    )

    if (-not $Success) {
        throw "Unable to inspect Discord RPC pipe."
    }

    return [int]$Available
}

function Connect-DiscordRpc {
    foreach ($Index in 0..9) {
        $Pipe = $null
        try {
            $Pipe = [System.IO.Pipes.NamedPipeClientStream]::new(
                ".",
                "discord-ipc-$Index",
                [System.IO.Pipes.PipeDirection]::InOut,
                [System.IO.Pipes.PipeOptions]::Asynchronous
            )
            $Pipe.Connect(300)

            Write-RpcJson -Pipe $Pipe -Opcode 0 -Payload ([ordered]@{
                v = 1
                client_id = $ClientId
            })

            $ReadyFrame = Read-RpcFrame -Pipe $Pipe
            if ($ReadyFrame.Opcode -eq 1) {
                Write-PresenceLog "Connected to Discord IPC $Index."
                return $Pipe
            }
        }
        catch {
            if ($Pipe) {
                $Pipe.Dispose()
            }
        }
    }

    return $null
}

function Set-SpotiXActivity {
    param(
        [System.IO.Pipes.NamedPipeClientStream] $Pipe,
        [long] $StartedAt
    )

    $Activity = [ordered]@{
        type = 2
        details = $PresenceDetails
        state = "Version $SpotiXVersion"
        timestamps = [ordered]@{
            start = $StartedAt
        }
        assets = [ordered]@{
            large_image = $LargeImageKey
            large_text = $PresenceName
        }
        buttons = @(
            [ordered]@{
                label = "Site officiel"
                url = $WebsiteUrl
            },
            [ordered]@{
                label = "GitHub"
                url = $GithubUrl
            }
        )
        instance = $false
    }

    Write-RpcJson -Pipe $Pipe -Opcode 1 -Payload ([ordered]@{
        cmd = "SET_ACTIVITY"
        args = [ordered]@{
            pid = $PID
            activity = $Activity
        }
        nonce = [Guid]::NewGuid().ToString()
    })
}

function Clear-SpotiXActivity {
    param([System.IO.Pipes.NamedPipeClientStream] $Pipe)

    Write-RpcJson -Pipe $Pipe -Opcode 1 -Payload ([ordered]@{
        cmd = "SET_ACTIVITY"
        args = [ordered]@{
            pid = $PID
            activity = $null
        }
        nonce = [Guid]::NewGuid().ToString()
    })
}

$DiscordPipe = $null
$SpotifyWasRunning = $false
$StartedAt = 0

Write-PresenceLog "SpotiXPresence started."

try {
    while ($true) {
        $SpotifyRunning = $null -ne (Get-Process -Name "Spotify" -ErrorAction SilentlyContinue | Select-Object -First 1)

        if ($SpotifyRunning) {
            if (-not $SpotifyWasRunning) {
                $StartedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                Write-PresenceLog "Spotify detected."
            }

            if (($null -eq $DiscordPipe) -or (-not $DiscordPipe.IsConnected)) {
                if ($DiscordPipe) {
                    $DiscordPipe.Dispose()
                }
                $DiscordPipe = Connect-DiscordRpc

                if ($DiscordPipe) {
                    Set-SpotiXActivity -Pipe $DiscordPipe -StartedAt $StartedAt
                    Write-PresenceLog "Rich Presence enabled."
                }
            }

            if ($DiscordPipe) {
                try {
                    while ((Get-PipeAvailableBytes -Pipe $DiscordPipe) -gt 0) {
                        $Frame = Read-RpcFrame -Pipe $DiscordPipe

                        if ($Frame.Opcode -eq 3) {
                            Write-RpcFrame -Pipe $DiscordPipe -Opcode 4 -PayloadBytes $Frame.PayloadBytes
                        }
                        elseif ($Frame.Opcode -eq 2) {
                            throw "Discord closed the RPC connection."
                        }
                    }
                }
                catch {
                    Write-PresenceLog "Discord RPC disconnected: $($_.Exception.Message)"
                    $DiscordPipe.Dispose()
                    $DiscordPipe = $null
                }
            }
        }
        else {
            if ($SpotifyWasRunning) {
                Write-PresenceLog "Spotify closed."
            }

            if ($DiscordPipe) {
                try {
                    Clear-SpotiXActivity -Pipe $DiscordPipe
                    Start-Sleep -Milliseconds 100
                }
                catch {
                }
                $DiscordPipe.Dispose()
                $DiscordPipe = $null
            }

            $StartedAt = 0
        }

        $SpotifyWasRunning = $SpotifyRunning
        Start-Sleep -Seconds 3
    }
}
finally {
    if ($DiscordPipe) {
        try {
            Clear-SpotiXActivity -Pipe $DiscordPipe
        }
        catch {
        }
        $DiscordPipe.Dispose()
    }

    Remove-Item -LiteralPath $PidFile -Force -ErrorAction SilentlyContinue
    if ($PresenceMutex) {
        $PresenceMutex.ReleaseMutex()
        $PresenceMutex.Dispose()
    }
}
'@

        $PresenceSource = $PresenceSource.Replace("__CLIENT_ID__", $DiscordApplicationId)
        $PresenceSource = $PresenceSource.Replace("__LARGE_IMAGE_KEY__", $DiscordLargeImageKey)
        $PresenceSource = $PresenceSource.Replace("__VERSION__", $Version)
        $PresenceSource = $PresenceSource.Replace("__WEBSITE_URL__", $SpotiXWebsite)
        $PresenceSource = $PresenceSource.Replace("__GITHUB_URL__", $SpotiXGithub)

        # Le helper est un fichier local exécuté par Windows PowerShell 5.1 :
        # le BOM UTF-8 est volontaire pour conserver correctement les accents.
        $Utf8WithBom = [System.Text.UTF8Encoding]::new($true)
        [System.IO.File]::WriteAllText($PresenceScript, $PresenceSource, $Utf8WithBom)

        $WshShellPresence = New-Object -ComObject WScript.Shell
        $PresenceShortcutObject = $WshShellPresence.CreateShortcut($StartupShortcut)
        $PresenceShortcutObject.TargetPath = $WindowsPowerShell
        $PresenceShortcutObject.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PresenceScript`""
        $PresenceShortcutObject.WorkingDirectory = $PresenceFolder
        $PresenceShortcutObject.Description = "SpotiX+ Reborn Discord Rich Presence"
        $PresenceShortcutObject.WindowStyle = 7
        $PresenceShortcutObject.Save()

        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($PresenceShortcutObject)
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($WshShellPresence)

        Start-Process `
            -FilePath $WindowsPowerShell `
            -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PresenceScript`"" `
            -WindowStyle Hidden `
            -ErrorAction Stop

        Write-Host (GetTranslation "discord-rpc-installed") -ForegroundColor Green
        EnterToContinue -DefaultPrompt $true
    }
    catch {
        Write-Host (GetTranslation "discord-rpc-error") -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        RemoveDiscordRichPresence
        EnterToContinue -DefaultPrompt $true
    }
}

function StopSpotiXCompanion {
    $CurrentProcessId = $PID
    $InstalledCompanionScript = Join-Path `
        (Join-Path $env:LOCALAPPDATA "SpotiXPlus") `
        "SpotiXCompanion.ps1"

    $InstalledCompanionPattern = [regex]::Escape(
        [System.IO.Path]::GetFullPath($InstalledCompanionScript)
    )

    try {
        Get-CimInstance Win32_Process -ErrorAction Stop |
            Where-Object {
                $_.ProcessId -ne $CurrentProcessId -and
                $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
                (
                    $_.CommandLine -match $InstalledCompanionPattern -or
                    $_.CommandLine -match 'SpotiXTray-test-v[2-5](\.1)?\.ps1' -or
                    $_.CommandLine -match 'SpotiXPlus-Companion-test-v6\.ps1' -or
                    $_.CommandLine -match 'SpotiXPlus-test-v(?:[7-9]|10|11|12(?:\.1)?|13(?:\.1)?)\.ps1'
                )
            } |
            ForEach-Object {
                Invoke-CimMethod `
                    -InputObject $_ `
                    -MethodName Terminate `
                    -ErrorAction SilentlyContinue | Out-Null
            }

        Start-Sleep -Milliseconds 350
    }
    catch {
        # L'ancien compagnon n'est probablement pas lancé.
    }
}

function RemoveSpotiXCompanion {
    StopSpotiXCompanion

    $CompanionFolder = Join-Path $env:LOCALAPPDATA "SpotiXPlus"
    $StartupFolder = [Environment]::GetFolderPath("Startup")
    $StartupShortcut = Join-Path $StartupFolder "SpotiX+ Companion.lnk"

    Remove-Item -LiteralPath $StartupShortcut -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $CompanionFolder -Recurse -Force -ErrorAction SilentlyContinue
}


function WriteSpotiXEmbeddedFile {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $IndentedContent,

        [bool] $Utf8Bom = $true
    )

    $Content = [regex]::Replace(
        $IndentedContent,
        '(?m)^\t',
        ''
    )

    $Encoding = New-Object System.Text.UTF8Encoding($Utf8Bom)

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        $Encoding
    )
}

function InstallSpotiXCompanion {
    Write-Host (GetTranslation "companion-installing") -ForegroundColor Yellow

    $SpotifyFolder = Join-Path $env:APPDATA "Spotify"
    $SpotifyExe = Join-Path $SpotifyFolder "Spotify.exe"
    $SpotifyIcon = Join-Path $SpotifyFolder "iconapp.ico"
    $CompanionFolder = Join-Path $env:LOCALAPPDATA "SpotiXPlus"
    $CompanionScript = Join-Path $CompanionFolder "SpotiXCompanion.ps1"
    $LauncherScript = Join-Path $CompanionFolder "SpotiXLauncher.ps1"
    $LauncherVbs = Join-Path $CompanionFolder "SpotiXLauncher.vbs"
    $CompanionIcon = Join-Path $CompanionFolder "iconapp.ico"
    $StartupFolder = [Environment]::GetFolderPath("Startup")
    $StartupShortcut = Join-Path $StartupFolder "SpotiX+ Companion.lnk"
    $WindowsPowerShell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

    if (-not (Test-Path -LiteralPath $SpotifyExe -PathType Leaf)) {
        Write-Host (GetTranslation "companion-spotify-not-found") -ForegroundColor Red
        return $false
    }

    try {
        StopSpotiXCompanion
        New-Item -ItemType Directory -Path $CompanionFolder -Force | Out-Null

        $CompanionSource = @'
	param(
	    [switch]$NoAutoStartSpotify
	)
	
	$ErrorActionPreference = 'Stop'
	
	if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
	    throw 'SpotiX+ Companion fonctionne uniquement sous Windows.'
	}
	
	# WinForms doit tourner en 64 bits et sur un thread STA.
	if (-not [Environment]::Is64BitProcess) {
	    $PowerShell64 = "$env:WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
	    if (-not (Test-Path -LiteralPath $PowerShell64)) {
	        throw 'PowerShell 64 bits est introuvable.'
	    }
	
	    $Arguments = @(
	        '-NoProfile', '-STA', '-WindowStyle', 'Hidden',
	        '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
	    )
	    if ($NoAutoStartSpotify) { $Arguments += '-NoAutoStartSpotify' }
	
	    Start-Process -FilePath $PowerShell64 -ArgumentList $Arguments -WindowStyle Hidden
	    exit
	}
	
	if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
	    $CurrentPowerShell = (Get-Process -Id $PID).Path
	    $Arguments = @(
	        '-NoProfile', '-STA', '-WindowStyle', 'Hidden',
	        '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
	    )
	    if ($NoAutoStartSpotify) { $Arguments += '-NoAutoStartSpotify' }
	
	    Start-Process -FilePath $CurrentPowerShell -ArgumentList $Arguments -WindowStyle Hidden
	    exit
	}
	
	$DataDirectory = Join-Path $env:LOCALAPPDATA 'SpotiXPlus'
	$LogDirectory = Join-Path $env:LOCALAPPDATA 'SpotiX-Logs'
	$LogPath = Join-Path $LogDirectory 'SpotiXCompanion.log'
	$SpotifyLogDirectory = Join-Path (Join-Path $env:LOCALAPPDATA 'Spotify') 'Logs'
	$TrayIdCachePath = Join-Path $DataDirectory 'spotify-tray-uid.txt'
	
	New-Item -Path $DataDirectory -ItemType Directory -Force | Out-Null
	New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
	New-Item -Path $SpotifyLogDirectory -ItemType Directory -Force | Out-Null
	
	$Utf8Bom = New-Object System.Text.UTF8Encoding($true)
	$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($LogPath, '', $Utf8Bom)
	
	function Write-BootLog {
	    param([Parameter(Mandatory)][string]$Message)
	    try {
	        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
	        [System.IO.File]::AppendAllText(
	            $LogPath,
	            "$Timestamp | POWERSHELL | $Message`r`n",
	            $Utf8NoBom
	        )
	    }
	    catch { }
	}
	
	$IconCandidates = @(
	    (Join-Path $PSScriptRoot 'iconapp.ico'),
	    (Join-Path $env:APPDATA 'Spotify\iconapp.ico'),
	    (Join-Path $DataDirectory 'iconapp.ico')
	)
	
	$IconPath = $IconCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
	if (-not $IconPath) {
	    $DownloadedIcon = Join-Path $DataDirectory 'iconapp.ico'
	    try {
	        Invoke-WebRequest -Uri 'https://spotixplus.fr/assets/icons/iconapp.ico' -OutFile $DownloadedIcon -UseBasicParsing
	        $IconPath = $DownloadedIcon
	    }
	    catch {
	        $IconPath = ''
	    }
	}
	
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	
	Write-BootLog "Démarrage. PowerShell=$($PSVersionTable.PSVersion), Processus64=$([Environment]::Is64BitProcess), STA=$([Threading.Thread]::CurrentThread.ApartmentState)."
	
	$Source = @'
	using System;
	using System.Collections.Generic;
	using System.Diagnostics;
	using System.Drawing;
	using System.Globalization;
	using System.IO;
	using System.Net;
	using System.Runtime.InteropServices;
	using System.Text;
	using System.Threading;
	using System.Windows.Forms;
	using Microsoft.Win32;
	
	namespace SpotiXPlusCompanion
	{
	    internal static class NativeMethods
	    {
	        internal const int SW_HIDE = 0;
	        internal const int SW_SHOW = 5;
	        internal const int SW_RESTORE = 9;
	        internal const uint GW_OWNER = 4;
	
	        internal delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
	
	        [DllImport("user32.dll")]
	        internal static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
	
	        [DllImport("user32.dll")]
	        internal static extern bool SetForegroundWindow(IntPtr hWnd);
	
	        [DllImport("user32.dll")]
	        internal static extern bool IsWindow(IntPtr hWnd);
	
	        [DllImport("user32.dll")]
	        internal static extern bool IsWindowVisible(IntPtr hWnd);
	
	        [DllImport("user32.dll")]
	        internal static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
	
	        [DllImport("user32.dll")]
	        internal static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
	
	        [DllImport("user32.dll")]
	        internal static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
	
	        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
	        internal static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
	
	        [DllImport("user32.dll")]
	        internal static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
	
	        internal static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
	        internal const uint WM_SETTINGCHANGE = 0x001A;
	        internal const uint SMTO_ABORTIFHUNG = 0x0002;
	
	        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	        internal static extern IntPtr SendMessageTimeout(
	            IntPtr hWnd,
	            uint Msg,
	            IntPtr wParam,
	            string lParam,
	            uint fuFlags,
	            uint uTimeout,
	            out IntPtr lpdwResult);
	    }
	
	    internal sealed class NativeSpotifyTrayRemover : IDisposable
	    {
	        private const uint NIM_DELETE = 0x00000002;
	        private static readonly IntPtr HWND_MESSAGE = new IntPtr(-3);
	
	        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	        private struct NOTIFYICONDATA
	        {
	            internal uint cbSize;
	            internal IntPtr hWnd;
	            internal uint uID;
	            internal uint uFlags;
	            internal uint uCallbackMessage;
	            internal IntPtr hIcon;
	
	            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
	            internal string szTip;
	
	            internal uint dwState;
	            internal uint dwStateMask;
	
	            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
	            internal string szInfo;
	
	            internal uint uTimeoutOrVersion;
	
	            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
	            internal string szInfoTitle;
	
	            internal uint dwInfoFlags;
	            internal Guid guidItem;
	            internal IntPtr hBalloonIcon;
	        }
	
	        [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	        [return: MarshalAs(UnmanagedType.Bool)]
	        private static extern bool Shell_NotifyIconW(uint dwMessage, ref NOTIFYICONDATA lpData);
	
	        [DllImport("user32.dll", SetLastError = true)]
	        private static extern bool EnumChildWindows(
	            IntPtr hWndParent,
	            NativeMethods.EnumWindowsProc lpEnumFunc,
	            IntPtr lParam);
	
	        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	        private static extern IntPtr FindWindowExW(
	            IntPtr hWndParent,
	            IntPtr hWndChildAfter,
	            string lpszClass,
	            string lpszWindow);
	
	        private sealed class IconIdentifier
	        {
	            internal readonly IntPtr HWnd;
	            internal readonly uint Id;
	
	            internal IconIdentifier(IntPtr hWnd, uint id)
	            {
	                HWnd = hWnd;
	                Id = id;
	            }
	
	            public override string ToString()
	            {
	                return "hWnd=0x" + HWnd.ToInt64().ToString("X") + ", uID=" + Id;
	            }
	        }
	
	        private readonly Action<string> log;
	        private readonly string cachePath;
	        private readonly object stateLock = new object();
	        private readonly System.Threading.Timer workerTimer;
	
	        private bool enabled;
	        private bool disposed;
	        private int generation;
	        private int callbackRunning;
	        private string processFingerprint = String.Empty;
	        private IconIdentifier knownIdentifier;
	        private Nullable<uint> cachedId;
	        private int retryStage;
	        private int scanFailures;
	        private bool scanFailureLogged;
	
	        internal NativeSpotifyTrayRemover(Action<string> logger, string identifierCachePath)
	        {
	            log = logger;
	            cachePath = identifierCachePath;
	            cachedId = LoadCachedId();
	            workerTimer = new System.Threading.Timer(
	                WorkerCallback,
	                null,
	                Timeout.Infinite,
	                Timeout.Infinite);
	
	            if (cachedId.HasValue)
	                log("Identifiant Spotify mémorisé chargé : uID=" + cachedId.Value + ".");
	        }
	
	        internal void Start()
	        {
	            int currentGeneration;
	
	            lock (stateLock)
	            {
	                if (disposed)
	                    return;
	
	                enabled = true;
	                generation++;
	                currentGeneration = generation;
	                processFingerprint = String.Empty;
	                knownIdentifier = null;
	                retryStage = 0;
	                scanFailures = 0;
	                scanFailureLogged = false;
	            }
	
	            Schedule(50, currentGeneration);
	        }
	
	        internal void Stop()
	        {
	            lock (stateLock)
	            {
	                enabled = false;
	                generation++;
	                processFingerprint = String.Empty;
	                knownIdentifier = null;
	                retryStage = 0;
	                scanFailures = 0;
	
	                try { workerTimer.Change(Timeout.Infinite, Timeout.Infinite); }
	                catch (ObjectDisposedException) { }
	            }
	        }
	
	        private Nullable<uint> LoadCachedId()
	        {
	            try
	            {
	                if (String.IsNullOrWhiteSpace(cachePath) || !File.Exists(cachePath))
	                    return null;
	
	                string value = File.ReadAllText(cachePath).Trim();
	                uint parsed;
	                if (UInt32.TryParse(value, out parsed))
	                    return parsed;
	            }
	            catch (Exception ex)
	            {
	                log("Lecture du cache d'identifiant ignorée : " + ex.Message);
	            }
	
	            return null;
	        }
	
	        private void SaveCachedId(uint id)
	        {
	            cachedId = id;
	
	            try
	            {
	                string directory = Path.GetDirectoryName(cachePath);
	                if (!String.IsNullOrWhiteSpace(directory))
	                    Directory.CreateDirectory(directory);
	
	                File.WriteAllText(cachePath, id.ToString());
	            }
	            catch (Exception ex)
	            {
	                log("Écriture du cache d'identifiant ignorée : " + ex.Message);
	            }
	        }
	
	        private void Schedule(int delayMilliseconds, int expectedGeneration)
	        {
	            lock (stateLock)
	            {
	                if (disposed || !enabled || generation != expectedGeneration)
	                    return;
	
	                try
	                {
	                    workerTimer.Change(
	                        Math.Max(1, delayMilliseconds),
	                        Timeout.Infinite);
	                }
	                catch (ObjectDisposedException) { }
	            }
	        }
	
	        private void WorkerCallback(object state)
	        {
	            if (Interlocked.Exchange(ref callbackRunning, 1) != 0)
	                return;
	
	            int currentGeneration;
	
	            try
	            {
	                lock (stateLock)
	                {
	                    if (disposed || !enabled)
	                        return;
	
	                    currentGeneration = generation;
	                }
	
	                HashSet<uint> spotifyProcessIds = GetSpotifyProcessIds();
	                if (spotifyProcessIds.Count == 0)
	                {
	                    Schedule(1000, currentGeneration);
	                    return;
	                }
	
	                string fingerprint = BuildFingerprint(spotifyProcessIds);
	                IconIdentifier identifier;
	
	                lock (stateLock)
	                {
	                    if (generation != currentGeneration || !enabled)
	                        return;
	
	                    if (!String.Equals(processFingerprint, fingerprint, StringComparison.Ordinal))
	                    {
	                        processFingerprint = fingerprint;
	                        knownIdentifier = null;
	                        retryStage = 0;
	                        scanFailures = 0;
	                        scanFailureLogged = false;
	                    }
	
	                    identifier = knownIdentifier;
	                }
	
	                if (identifier == null)
	                {
	                    identifier = FindIdentifier(spotifyProcessIds);
	
	                    if (identifier != null)
	                    {
	                        lock (stateLock)
	                        {
	                            if (generation != currentGeneration || !enabled)
	                                return;
	
	                            knownIdentifier = identifier;
	                            retryStage = 0;
	                        }
	
	                        SaveCachedId(identifier.Id);
	                        log("Icône Spotify supprimée ; identifiant conservé pour les prochains passages : " +
	                            identifier + ".");
	                        Schedule(400, currentGeneration);
	                        return;
	                    }
	
	                    scanFailures++;
	
	                    if (scanFailures >= 5 && !scanFailureLogged)
	                    {
	                        scanFailureLogged = true;
	                        log("Suppression Spotify : aucun identifiant valide trouvé après " +
	                            scanFailures + " recherches. Nouvelle tentative espacée.");
	                    }
	
	                    // Le scan complet est coûteux : rapide seulement au lancement,
	                    // puis fortement ralenti s'il ne trouve rien.
	                    Schedule(scanFailures < 5 ? 1200 : 10000, currentGeneration);
	                    return;
	                }
	
	                // Une seule requête NIM_DELETE est envoyée. Aucun nouveau scan 0..1024
	                // tant que les processus Spotify n'ont pas changé.
	                DeleteByIdentifier(identifier.HWnd, identifier.Id);
	
	                int delay;
	                lock (stateLock)
	                {
	                    if (generation != currentGeneration || !enabled)
	                        return;
	
	                    retryStage++;
	
	                    // Quelques reprises rapprochées au démarrage, puis seulement
	                    // une requête légère toutes les 2 secondes.
	                    if (retryStage == 1)
	                        delay = 600;
	                    else if (retryStage == 2)
	                        delay = 1200;
	                    else
	                        delay = 2000;
	                }
	
	                Schedule(delay, currentGeneration);
	            }
	            catch (Exception ex)
	            {
	                try { log("Suppression Spotify en arrière-plan : " + ex.Message); }
	                catch { }
	
	                lock (stateLock)
	                {
	                    currentGeneration = generation;
	                }
	
	                Schedule(5000, currentGeneration);
	            }
	            finally
	            {
	                Interlocked.Exchange(ref callbackRunning, 0);
	            }
	        }
	
	        private static string BuildFingerprint(HashSet<uint> processIds)
	        {
	            List<uint> sorted = new List<uint>(processIds);
	            sorted.Sort();
	
	            StringBuilder builder = new StringBuilder();
	            foreach (uint processId in sorted)
	            {
	                if (builder.Length > 0)
	                    builder.Append(',');
	
	                builder.Append(processId);
	            }
	
	            return builder.ToString();
	        }
	
	        private static HashSet<uint> GetSpotifyProcessIds()
	        {
	            Process[] processes = Process.GetProcessesByName("Spotify");
	            HashSet<uint> result = new HashSet<uint>();
	
	            try
	            {
	                foreach (Process process in processes)
	                    result.Add((uint)process.Id);
	            }
	            finally
	            {
	                foreach (Process process in processes)
	                    process.Dispose();
	            }
	
	            return result;
	        }
	
	        private IconIdentifier FindIdentifier(HashSet<uint> spotifyProcessIds)
	        {
	            List<IntPtr> windows = EnumerateSpotifyWindows(spotifyProcessIds);
	            if (windows.Count == 0)
	                return null;
	
	            // Le uID trouvé lors du précédent lancement est presque toujours stable.
	            if (cachedId.HasValue)
	            {
	                foreach (IntPtr hWnd in windows)
	                {
	                    if (DeleteByIdentifier(hWnd, cachedId.Value))
	                        return new IconIdentifier(hWnd, cachedId.Value);
	                }
	            }
	
	            uint[] commonIds = new uint[] { 0, 1, 2, 3, 4, 5, 10, 11, 12, 100, 101, 102, 1000 };
	
	            foreach (IntPtr hWnd in windows)
	            {
	                foreach (uint id in commonIds)
	                {
	                    if (cachedId.HasValue && id == cachedId.Value)
	                        continue;
	
	                    if (DeleteByIdentifier(hWnd, id))
	                        return new IconIdentifier(hWnd, id);
	                }
	            }
	
	            // Dernier recours : un seul scan complet, sur un thread de fond,
	            // arrêté dès que l'identifiant valide est trouvé.
	            foreach (IntPtr hWnd in windows)
	            {
	                for (uint id = 0; id <= 1024; id++)
	                {
	                    if (cachedId.HasValue && id == cachedId.Value)
	                        continue;
	
	                    bool isCommon = false;
	                    foreach (uint commonId in commonIds)
	                    {
	                        if (id == commonId)
	                        {
	                            isCommon = true;
	                            break;
	                        }
	                    }
	
	                    if (isCommon)
	                        continue;
	
	                    if (DeleteByIdentifier(hWnd, id))
	                        return new IconIdentifier(hWnd, id);
	                }
	            }
	
	            return null;
	        }
	
	        private static bool DeleteByIdentifier(IntPtr hWnd, uint id)
	        {
	            NOTIFYICONDATA data = new NOTIFYICONDATA();
	            data.cbSize = (uint)Marshal.SizeOf(typeof(NOTIFYICONDATA));
	            data.hWnd = hWnd;
	            data.uID = id;
	            data.szTip = String.Empty;
	            data.szInfo = String.Empty;
	            data.szInfoTitle = String.Empty;
	
	            return Shell_NotifyIconW(NIM_DELETE, ref data);
	        }
	
	        private static List<IntPtr> EnumerateSpotifyWindows(HashSet<uint> spotifyProcessIds)
	        {
	            HashSet<IntPtr> result = new HashSet<IntPtr>();
	            List<IntPtr> topLevel = new List<IntPtr>();
	
	            NativeMethods.EnumWindows(
	                delegate(IntPtr hWnd, IntPtr lParam)
	                {
	                    uint processId;
	                    NativeMethods.GetWindowThreadProcessId(hWnd, out processId);
	
	                    if (spotifyProcessIds.Contains(processId))
	                    {
	                        result.Add(hWnd);
	                        topLevel.Add(hWnd);
	                    }
	
	                    return true;
	                },
	                IntPtr.Zero);
	
	            foreach (IntPtr parent in topLevel)
	            {
	                EnumChildWindows(
	                    parent,
	                    delegate(IntPtr hWnd, IntPtr lParam)
	                    {
	                        uint processId;
	                        NativeMethods.GetWindowThreadProcessId(hWnd, out processId);
	                        if (spotifyProcessIds.Contains(processId))
	                            result.Add(hWnd);
	                        return true;
	                    },
	                    IntPtr.Zero);
	            }
	
	            IntPtr messageWindow = IntPtr.Zero;
	            while (true)
	            {
	                messageWindow = FindWindowExW(HWND_MESSAGE, messageWindow, null, null);
	                if (messageWindow == IntPtr.Zero)
	                    break;
	
	                uint processId;
	                NativeMethods.GetWindowThreadProcessId(messageWindow, out processId);
	                if (spotifyProcessIds.Contains(processId))
	                    result.Add(messageWindow);
	            }
	
	            return new List<IntPtr>(result);
	        }
	
	        public void Dispose()
	        {
	            lock (stateLock)
	            {
	                if (disposed)
	                    return;
	
	                disposed = true;
	                enabled = false;
	                generation++;
	
	                try { workerTimer.Change(Timeout.Infinite, Timeout.Infinite); }
	                catch { }
	
	                workerTimer.Dispose();
	                knownIdentifier = null;
	            }
	        }
	    }
	
	    internal sealed class CompanionContext : ApplicationContext
	    {
	        private readonly NotifyIcon notifyIcon;
	        private readonly Icon loadedIcon;
	        private readonly System.Windows.Forms.Timer monitorTimer;
	        private readonly string logPath;
	        private readonly string spotifyLogsDirectory;
	        private readonly bool autoStartSpotify;
	        private readonly bool isFrench;
	        private readonly ToolStripMenuItem visibilitySpotifyItem;
	        private readonly ToolStripMenuItem manageSpotiXItem;
	        private readonly ContextMenuStrip contextMenu;
	        private readonly NativeSpotifyTrayRemover trayRemover;
	        private readonly object logLock = new object();
	        private readonly object spotifyOutputLock = new object();
	        private readonly object launchedProcessesLock = new object();
	        private readonly List<Process> launchedSpotifyProcesses = new List<Process>();
	        private readonly EventWaitHandle launchSpotifyEvent;
	        private readonly Thread launchSpotifyThread;
	        private volatile bool shuttingDown;
	        private volatile bool launchRequested;
	        private bool autoStartAttempted;
	        private bool waitingLogged;
	        private bool lastSpotifyRunning;
	        private bool manageScriptBusy;
	        private int initialTicks;
	        private IntPtr spotifyWindowHandle = IntPtr.Zero;
	
	        internal CompanionContext(
	            string iconPath,
	            string outputLogPath,
	            string spotifyOutputDirectory,
	            string trayIdCachePath,
	            bool shouldAutoStartSpotify)
	        {
	            logPath = outputLogPath;
	            spotifyLogsDirectory = spotifyOutputDirectory;
	            Directory.CreateDirectory(spotifyLogsDirectory);
	            autoStartSpotify = shouldAutoStartSpotify;
	            isFrench = String.Equals(
	                CultureInfo.CurrentUICulture.TwoLetterISOLanguageName,
	                "fr",
	                StringComparison.OrdinalIgnoreCase);
	            loadedIcon = LoadTrayIcon(iconPath);
	            trayRemover = new NativeSpotifyTrayRemover(Log, trayIdCachePath);
	
	            bool launchEventCreated;
	            launchSpotifyEvent = new EventWaitHandle(
	                false,
	                EventResetMode.AutoReset,
	                @"Local\SpotiXPlus_Companion_LaunchSpotify",
	                out launchEventCreated);
	            launchSpotifyThread = new Thread(WaitForSpotifyLaunchRequests);
	            launchSpotifyThread.IsBackground = true;
	            launchSpotifyThread.Name = "SpotiX+ Spotify launcher";
	            launchSpotifyThread.Start();
	
	            contextMenu = new ContextMenuStrip();
	            ContextMenuStrip menu = contextMenu;
	            menu.Opening += delegate { UpdateVisibilityMenu(); };
	
	            visibilitySpotifyItem = new ToolStripMenuItem(T(
	                "Minimiser dans la barre des tâches",
	                "Minimize to tray"));
	            visibilitySpotifyItem.Click += delegate { ToggleSpotifyWindow(); };
	            menu.Items.Add(visibilitySpotifyItem);
	
	            ToolStripMenuItem reloadSpotify = new ToolStripMenuItem(T("Recharger Spotify", "Reload Spotify"));
	            reloadSpotify.Click += delegate { ReloadSpotify(); };
	            menu.Items.Add(reloadSpotify);
	
	            menu.Items.Add(new ToolStripSeparator());
	
	            ToolStripMenuItem settingsFolder = new ToolStripMenuItem(
	                T("Paramètres de SpotiX+", "SpotiX+ Settings"));
	
	            ToolStripMenuItem openSpotiXLogs = new ToolStripMenuItem(
	                T("Logs de SpotiX+", "SpotiX+ logs"));
	            openSpotiXLogs.Click += delegate { OpenSpotiXLogs(); };
	            settingsFolder.DropDownItems.Add(openSpotiXLogs);
	
	            ToolStripMenuItem openSpotifyLogs = new ToolStripMenuItem(
	                T("Logs de Spotify", "Spotify logs"));
	            openSpotifyLogs.Click += delegate { OpenSpotifyLogs(); };
	            settingsFolder.DropDownItems.Add(openSpotifyLogs);
	
	            settingsFolder.DropDownItems.Add(new ToolStripSeparator());
	
	            manageSpotiXItem = new ToolStripMenuItem(
	                T("Gérer SpotiX+", "Manage SpotiX+"));
	            manageSpotiXItem.ToolTipText = T(
	                "Configurer, réparer ou réinstaller SpotiX+, gérer la qualité audio etc..",
	                "Configure, repair or reinstall SpotiX+, manage audio quality, etc.");
	            manageSpotiXItem.Click += delegate { ManageSpotiXPlus(); };
	            settingsFolder.DropDownItems.Add(manageSpotiXItem);
	
	            menu.Items.Add(settingsFolder);
	
	            ToolStripMenuItem linksFolder = new ToolStripMenuItem(T("Liens et aide", "Links and help"));
	
	            ToolStripMenuItem officialWebsite = new ToolStripMenuItem(T("Site officiel", "Official website"));
	            officialWebsite.Click += delegate { OpenUrl("https://spotixplus.fr/"); };
	            linksFolder.DropDownItems.Add(officialWebsite);
	
	            ToolStripMenuItem githubPage = new ToolStripMenuItem(T("Page GitHub", "GitHub page"));
	            githubPage.Click += delegate { OpenUrl("https://github.com/AgoyaSpotix/spotixplus-reborn"); };
	            linksFolder.DropDownItems.Add(githubPage);
	
	            ToolStripMenuItem discordPage = new ToolStripMenuItem("Discord");
	            discordPage.Click += delegate { OpenUrl("https://discord.gg/xcCsz4QpTA"); };
	            linksFolder.DropDownItems.Add(discordPage);
	
	            menu.Items.Add(linksFolder);
	            menu.Items.Add(new ToolStripSeparator());
	
	            ToolStripMenuItem quitSpotify = new ToolStripMenuItem(T("Quitter Spotify", "Quit Spotify"));
	            quitSpotify.Click += delegate { QuitSpotify(); };
	            menu.Items.Add(quitSpotify);
	
	            notifyIcon = new NotifyIcon();
	            notifyIcon.Icon = loadedIcon;
	            notifyIcon.Text = "SpotiX+ Reborn";
	            notifyIcon.ContextMenuStrip = menu;
	            notifyIcon.Visible = false;
	            notifyIcon.MouseDoubleClick += delegate { ShowOrStartSpotify(); };
	
	            Log("Démarrage de SpotiX+ Companion. Langue=" + (isFrench ? "fr" : "en") + ", icône='" + iconPath + "'.");
	            Log("Le processus reste actif en arrière-plan ; l'icône SpotiX+ apparaît uniquement lorsque Spotify tourne.");
	            Log("Suppression native de l’icône Spotify active sur un thread de fond ; journalisation Spotify détaillée disponible pour les lancements effectués par SpotiX+.");
	
	            monitorTimer = new System.Windows.Forms.Timer();
	            monitorTimer.Interval = 750;
	            monitorTimer.Tick += MonitorTick;
	            monitorTimer.Start();
	        }
	
	        private string T(string french, string english)
	        {
	            return isFrench ? french : english;
	        }
	
	        private void WaitForSpotifyLaunchRequests()
	        {
	            while (!shuttingDown)
	            {
	                try
	                {
	                    if (!launchSpotifyEvent.WaitOne(1000))
	                        continue;
	                }
	                catch
	                {
	                    break;
	                }
	
	                if (shuttingDown)
	                    break;
	
	                launchRequested = true;
	            }
	        }
	
	        private static Icon LoadTrayIcon(string iconPath)
	        {
	            try
	            {
	                if (String.IsNullOrWhiteSpace(iconPath) || !File.Exists(iconPath))
	                    return (Icon)SystemIcons.Application.Clone();
	
	                return new Icon(iconPath, 32, 32);
	            }
	            catch
	            {
	                try { return new Icon(iconPath); }
	                catch { return (Icon)SystemIcons.Application.Clone(); }
	            }
	        }
	
	        private void MonitorTick(object sender, EventArgs e)
	        {
	            initialTicks++;
	
	            if (launchRequested)
	            {
	                launchRequested = false;
	                Log("Demande de lancement ou d’affichage de Spotify reçue depuis un raccourci SpotiX+.");
	                ShowOrStartSpotify();
	            }
	
	            if (autoStartSpotify && !autoStartAttempted && initialTicks >= 2)
	            {
	                autoStartAttempted = true;
	                StartSpotifyIfNeeded();
	            }
	
	            bool spotifyRunning = IsSpotifyRunning();
	
	            if (spotifyRunning != lastSpotifyRunning)
	            {
	                lastSpotifyRunning = spotifyRunning;
	                if (spotifyRunning)
	                {
	                    notifyIcon.Text = T("SpotiX+ Reborn - Spotify actif", "SpotiX+ Reborn - Spotify running");
	                    notifyIcon.Visible = true;
	                    trayRemover.Start();
	                    waitingLogged = false;
	                    FindSpotifyMainWindow();
	                    UpdateVisibilityMenu();
	                    Log("Spotify détecté : icône SpotiX+ affichée.");
	                }
	                else
	                {
	                    notifyIcon.Visible = false;
	                    trayRemover.Stop();
	                    spotifyWindowHandle = IntPtr.Zero;
	                    Log("Spotify fermé : icône SpotiX+ masquée. Le compagnon attend le prochain lancement.");
	                }
	            }
	
	            if (!spotifyRunning && autoStartAttempted && !waitingLogged && initialTicks >= 120)
	            {
	                waitingLogged = true;
	                Log("Spotify n'est pas lancé. Le compagnon reste invisible en arrière-plan.");
	            }
	
	            // Ce minuteur ne fait plus aucun scan d'icône. Il surveille seulement
	            // l'état de Spotify ; la suppression native tourne sur un thread séparé.
	            monitorTimer.Interval = spotifyRunning ? 750 : 1000;
	        }
	
	        private static bool IsSpotifyRunning()
	        {
	            Process[] processes = Process.GetProcessesByName("Spotify");
	            bool result = processes.Length > 0;
	            foreach (Process process in processes)
	                process.Dispose();
	            return result;
	        }
	
	        private List<IntPtr> GetSpotifyTopLevelWindows()
	        {
	            Process[] processes = Process.GetProcessesByName("Spotify");
	            HashSet<uint> spotifyProcessIds = new HashSet<uint>();
	            List<IntPtr> windows = new List<IntPtr>();
	
	            try
	            {
	                foreach (Process process in processes)
	                    spotifyProcessIds.Add((uint)process.Id);
	
	                NativeMethods.EnumWindows(
	                    delegate(IntPtr hWnd, IntPtr lParam)
	                    {
	                        uint processId;
	                        NativeMethods.GetWindowThreadProcessId(hWnd, out processId);
	                        if (!spotifyProcessIds.Contains(processId))
	                            return true;
	
	                        if (NativeMethods.GetWindow(hWnd, NativeMethods.GW_OWNER) != IntPtr.Zero)
	                            return true;
	
	                        StringBuilder className = new StringBuilder(256);
	                        NativeMethods.GetClassName(hWnd, className, className.Capacity);
	                        string classValue = className.ToString();
	
	                        if (classValue.IndexOf("Chrome_WidgetWin", StringComparison.OrdinalIgnoreCase) >= 0)
	                            windows.Add(hWnd);
	
	                        return true;
	                    },
	                    IntPtr.Zero);
	            }
	            finally
	            {
	                foreach (Process process in processes)
	                    process.Dispose();
	            }
	
	            return windows;
	        }
	
	        private IntPtr FindSpotifyMainWindow()
	        {
	            if (spotifyWindowHandle != IntPtr.Zero && NativeMethods.IsWindow(spotifyWindowHandle))
	                return spotifyWindowHandle;
	
	            List<IntPtr> windows = GetSpotifyTopLevelWindows();
	            foreach (IntPtr window in windows)
	            {
	                if (NativeMethods.IsWindowVisible(window))
	                {
	                    spotifyWindowHandle = window;
	                    return window;
	                }
	            }
	
	            if (windows.Count > 0)
	            {
	                spotifyWindowHandle = windows[0];
	                return spotifyWindowHandle;
	            }
	
	            spotifyWindowHandle = IntPtr.Zero;
	            return IntPtr.Zero;
	        }
	
	        private bool AnySpotifyWindowVisible()
	        {
	            List<IntPtr> windows = GetSpotifyTopLevelWindows();
	            foreach (IntPtr window in windows)
	            {
	                if (NativeMethods.IsWindowVisible(window))
	                    return true;
	            }
	            return false;
	        }
	
	        private void HideAllSpotifyWindows()
	        {
	            List<IntPtr> windows = GetSpotifyTopLevelWindows();
	            foreach (IntPtr window in windows)
	                NativeMethods.ShowWindowAsync(window, NativeMethods.SW_HIDE);
	        }
	
	        private void StartSpotifyIfNeeded()
	        {
	            if (IsSpotifyRunning())
	            {
	                Log(
	                    "Spotify était déjà lancé. Les logs internes détaillés de cette session " +
	                    "ne peuvent pas être activés après son démarrage.");
	                return;
	            }
	
	            string spotifyPath = Path.Combine(
	                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
	                "Spotify",
	                "Spotify.exe");
	
	            try
	            {
	                if (File.Exists(spotifyPath))
	                {
	                    StartSpotifyWithLogging(spotifyPath);
	                }
	                else
	                {
	                    Process.Start(new ProcessStartInfo("spotify:") { UseShellExecute = true });
	                    Log(
	                        "Spotify démarré via le protocole spotify:. " +
	                        "La journalisation Chromium détaillée n'est pas disponible avec ce mode.");
	                }
	            }
	            catch (Exception ex)
	            {
	                Log("Impossible de démarrer Spotify avec les logs : " + ex.Message);
	                ShowLocalizedMessage(
	                    T(
	                        "Spotify n'a pas pu être démarré avec la journalisation active.",
	                        "Spotify could not be started with logging enabled."),
	                    MessageBoxIcon.Error);
	            }
	        }
	
	        private void StartSpotifyWithLogging(string spotifyPath)
	        {
	            Directory.CreateDirectory(spotifyLogsDirectory);
	
	            string sessionId = DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
	            string chromiumLogPath = Path.Combine(
	                spotifyLogsDirectory,
	                "Spotify-Chromium-" + sessionId + ".log");
	            string stdoutLogPath = Path.Combine(
	                spotifyLogsDirectory,
	                "Spotify-stdout-" + sessionId + ".log");
	            string stderrLogPath = Path.Combine(
	                spotifyLogsDirectory,
	                "Spotify-stderr-" + sessionId + ".log");
	            string sessionInfoPath = Path.Combine(
	                spotifyLogsDirectory,
	                "Spotify-session-" + sessionId + ".txt");
	
	            File.WriteAllText(
	                sessionInfoPath,
	                "SpotiX+ Spotify logging session" + Environment.NewLine +
	                "Started: " + DateTime.Now.ToString("O") + Environment.NewLine +
	                "Spotify: " + spotifyPath + Environment.NewLine +
	                "Chromium log: " + chromiumLogPath + Environment.NewLine +
	                "Standard output: " + stdoutLogPath + Environment.NewLine +
	                "Standard error: " + stderrLogPath + Environment.NewLine,
	                Encoding.UTF8);
	
	            ProcessStartInfo startInfo = new ProcessStartInfo();
	            startInfo.FileName = spotifyPath;
	            startInfo.Arguments =
	                "--enable-logging --v=1 --log-file=" + QuoteArgument(chromiumLogPath);
	            startInfo.WorkingDirectory = Path.GetDirectoryName(spotifyPath);
	            startInfo.UseShellExecute = false;
	            startInfo.CreateNoWindow = true;
	            startInfo.RedirectStandardOutput = true;
	            startInfo.RedirectStandardError = true;
	            startInfo.EnvironmentVariables["CHROME_LOG_FILE"] = chromiumLogPath;
	
	            Process spotifyProcess = new Process();
	            spotifyProcess.StartInfo = startInfo;
	            spotifyProcess.EnableRaisingEvents = true;
	
	            spotifyProcess.OutputDataReceived +=
	                delegate(object sender, DataReceivedEventArgs eventArgs)
	                {
	                    if (!String.IsNullOrEmpty(eventArgs.Data))
	                        AppendSpotifyOutput(stdoutLogPath, eventArgs.Data);
	                };
	
	            spotifyProcess.ErrorDataReceived +=
	                delegate(object sender, DataReceivedEventArgs eventArgs)
	                {
	                    if (!String.IsNullOrEmpty(eventArgs.Data))
	                        AppendSpotifyOutput(stderrLogPath, eventArgs.Data);
	                };
	
	            spotifyProcess.Exited +=
	                delegate(object sender, EventArgs eventArgs)
	                {
	                    try
	                    {
	                        File.AppendAllText(
	                            sessionInfoPath,
	                            "Launcher process exited: " +
	                            DateTime.Now.ToString("O") +
	                            Environment.NewLine,
	                            Encoding.UTF8);
	                    }
	                    catch { }
	                };
	
	            if (!spotifyProcess.Start())
	                throw new InvalidOperationException("Spotify.exe n'a pas démarré.");
	
	            lock (launchedProcessesLock)
	            {
	                launchedSpotifyProcesses.Add(spotifyProcess);
	            }
	
	            spotifyProcess.BeginOutputReadLine();
	            spotifyProcess.BeginErrorReadLine();
	
	            Log(
	                "Spotify démarré avec les logs détaillés. Chromium='" +
	                chromiumLogPath + "', stdout='" + stdoutLogPath +
	                "', stderr='" + stderrLogPath + "'.");
	        }
	
	        private static string QuoteArgument(string value)
	        {
	            if (String.IsNullOrEmpty(value))
	                return "\"\"";
	
	            return "\"" + value.Replace("\"", "\\\"") + "\"";
	        }
	
	        private void AppendSpotifyOutput(string filePath, string line)
	        {
	            lock (spotifyOutputLock)
	            {
	                try
	                {
	                    File.AppendAllText(
	                        filePath,
	                        DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") +
	                        " | " + line + Environment.NewLine,
	                        Encoding.UTF8);
	                }
	                catch { }
	            }
	        }
	
	        private void ShowOrStartSpotify()
	        {
	            IntPtr window = FindSpotifyMainWindow();
	            if (window == IntPtr.Zero)
	            {
	                StartSpotifyIfNeeded();
	                return;
	            }
	
	            NativeMethods.ShowWindowAsync(window, NativeMethods.SW_SHOW);
	            NativeMethods.ShowWindowAsync(window, NativeMethods.SW_RESTORE);
	            NativeMethods.SetForegroundWindow(window);
	            UpdateVisibilityMenu();
	            Log("Fenêtre Spotify affichée.");
	        }
	
	        private void ToggleSpotifyWindow()
	        {
	            if (!IsSpotifyRunning())
	            {
	                StartSpotifyIfNeeded();
	                return;
	            }
	
	            if (AnySpotifyWindowVisible())
	            {
	                HideAllSpotifyWindows();
	                Log("Fenêtre Spotify cachée : Spotify et la musique restent actifs.");
	            }
	            else
	            {
	                IntPtr window = FindSpotifyMainWindow();
	                if (window != IntPtr.Zero)
	                {
	                    NativeMethods.ShowWindowAsync(window, NativeMethods.SW_SHOW);
	                    NativeMethods.ShowWindowAsync(window, NativeMethods.SW_RESTORE);
	                    NativeMethods.SetForegroundWindow(window);
	                    Log("Fenêtre Spotify réaffichée.");
	                }
	            }
	
	            UpdateVisibilityMenu();
	        }
	
	        private void UpdateVisibilityMenu()
	        {
	            IntPtr window = FindSpotifyMainWindow();
	            bool spotifyRunning = IsSpotifyRunning();
	            bool windowVisible = AnySpotifyWindowVisible();
	
	            visibilitySpotifyItem.Enabled = spotifyRunning && window != IntPtr.Zero;
	            visibilitySpotifyItem.Text = windowVisible
	                ? T("Minimiser dans la barre des tâches", "Minimize to tray")
	                : T("Afficher Spotify", "Show Spotify");
	        }
	
	        private void ReloadSpotify()
	        {
	            IntPtr window = FindSpotifyMainWindow();
	            if (window == IntPtr.Zero)
	            {
	                StartSpotifyIfNeeded();
	                Log("Rechargement demandé mais Spotify n'avait aucune fenêtre détectable.");
	                return;
	            }
	
	            bool wasHidden = !NativeMethods.IsWindowVisible(window);
	
	            try
	            {
	                NativeMethods.ShowWindow(window, NativeMethods.SW_SHOW);
	                NativeMethods.ShowWindow(window, NativeMethods.SW_RESTORE);
	                NativeMethods.SetForegroundWindow(window);
	                Thread.Sleep(150);
	
	                SendKeys.SendWait("^+r");
	                Thread.Sleep(150);
	
	                if (wasHidden)
	                    NativeMethods.ShowWindow(window, NativeMethods.SW_HIDE);
	
	                UpdateVisibilityMenu();
	                Log("Commande de rechargement Ctrl+Maj+R envoyée à Spotify.");
	            }
	            catch (Exception ex)
	            {
	                Log("Échec du rechargement de Spotify : " + ex.Message);
	            }
	        }
	
	        private void OpenSpotiXLogs()
	        {
	            string logsDirectory = Path.Combine(
	                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
	                "SpotiX-Logs");
	
	            OpenLogDirectory(
	                logsDirectory,
	                T("les logs de SpotiX+", "SpotiX+ logs"));
	        }
	
	        private void OpenSpotifyLogs()
	        {
	            OpenLogDirectory(
	                spotifyLogsDirectory,
	                T("les logs de Spotify", "Spotify logs"));
	        }
	
	        private void OpenLogDirectory(string directoryPath, string localizedName)
	        {
	            try
	            {
	                Directory.CreateDirectory(directoryPath);
	                Process.Start(
	                    new ProcessStartInfo(directoryPath)
	                    {
	                        UseShellExecute = true
	                    });
	                Log("Dossier ouvert pour " + localizedName + " : " + directoryPath);
	            }
	            catch (Exception ex)
	            {
	                Log(
	                    "Impossible d'ouvrir le dossier pour " +
	                    localizedName + " : " + ex.Message);
	                ShowLocalizedMessage(
	                    T(
	                        "Impossible d'ouvrir ce dossier de logs.",
	                        "Unable to open this logs folder."),
	                    MessageBoxIcon.Error);
	            }
	        }
	
	        private void ManageSpotiXPlus()
	        {
	            if (manageScriptBusy)
	                return;
	
	            manageScriptBusy = true;
	            manageSpotiXItem.Enabled = false;
	            manageSpotiXItem.Text = T(
	                "Démarrage du script…",
	                "Starting script…");
	
	            ThreadPool.QueueUserWorkItem(
	                delegate
	                {
	                    string downloadedScript = Path.Combine(
	                        Path.GetTempPath(),
	                        "SpotiXPlus-Latest-" + Guid.NewGuid().ToString("N") + ".ps1");
	
	                    const string stableSource =
	                        "https://github.com/AgoyaSpotix/spotixplus-reborn/releases/latest/download/script.ps1";
	
	                    string selectedSource = String.Empty;
	                    Exception lastError = null;
	
	                    try
	                    {
	                        try
	                        {
	                            ServicePointManager.SecurityProtocol =
	                                ServicePointManager.SecurityProtocol |
	                                SecurityProtocolType.Tls12;
	                        }
	                        catch { }
	
	                        try
	                        {
	                            if (File.Exists(downloadedScript))
	                                File.Delete(downloadedScript);
	
	                            using (WebClient client = new WebClient())
	                            {
	                                client.Headers[HttpRequestHeader.UserAgent] =
	                                    "SpotiXPlus-Companion/3.0";
	                                client.Headers[HttpRequestHeader.CacheControl] =
	                                    "no-cache";
	                                client.DownloadFile(stableSource, downloadedScript);
	                            }
	
	                            if (!LooksLikeSpotiXScript(downloadedScript))
	                                throw new InvalidDataException(
	                                    "GitHub n'a pas retourné un script SpotiX+ stable valide.");
	
	                            selectedSource = stableSource;
	                        }
	                        catch (Exception sourceError)
	                        {
	                            lastError = sourceError;
	                            Log(
	                                "Téléchargement de la dernière version stable impossible depuis GitHub : " +
	                                sourceError.Message);
	                        }
	
	                        if (String.IsNullOrEmpty(selectedSource))
	                        {
	                            throw new InvalidOperationException(
	                                "La dernière release stable SpotiX+ n'est pas accessible.",
	                                lastError);
	                        }
	
	                        ProcessStartInfo startInfo = new ProcessStartInfo();
	                        startInfo.FileName = "powershell.exe";
	                        startInfo.Arguments =
	                            "-NoProfile -ExecutionPolicy Bypass -File \"" +
	                            downloadedScript.Replace("\"", "\\\"") + "\"";
	                        startInfo.WorkingDirectory =
	                            Path.GetDirectoryName(downloadedScript);
	                        startInfo.UseShellExecute = true;
	                        startInfo.WindowStyle = ProcessWindowStyle.Normal;
	
	                        Process.Start(startInfo);
	                        Log(
	                            "Dernière version de SpotiX+ lancée depuis '" +
	                            selectedSource + "'. Fichier temporaire='" +
	                            downloadedScript + "'.");
	                    }
	                    catch (Exception ex)
	                    {
	                        Log(
	                            "Impossible de télécharger ou lancer la dernière version de SpotiX+ : " +
	                            ex.Message);
	
	                        RunOnUi(
	                            delegate
	                            {
	                                MessageBox.Show(
	                                    T(
	                                        "Une connexion Internet est requise pour ouvrir la dernière version stable de SpotiX+.\r\n\r\nVérifiez votre connexion, puis réessayez.",
	                                        "An Internet connection is required to open the latest stable version of SpotiX+.\r\n\r\nCheck your connection, then try again."),
	                                    "SpotiX+ Reborn",
	                                    MessageBoxButtons.OK,
	                                    MessageBoxIcon.Warning);
	                            });
	                    }
	                    finally
	                    {
	                        RunOnUi(
	                            delegate
	                            {
	                                manageScriptBusy = false;
	                                manageSpotiXItem.Enabled = true;
	                                manageSpotiXItem.Text =
	                                    T("Gérer SpotiX+", "Manage SpotiX+");
	                            });
	                    }
	                });
	        }
	
	        private static bool LooksLikeSpotiXScript(string filePath)
	        {
	            try
	            {
	                FileInfo info = new FileInfo(filePath);
	                if (!info.Exists || info.Length < 2048)
	                    return false;
	
	                string content = File.ReadAllText(filePath);
	                bool mentionsSpotiX =
	                    content.IndexOf(
	                        "SpotiX+",
	                        StringComparison.OrdinalIgnoreCase) >= 0 ||
	                    content.IndexOf(
	                        "spotixplus",
	                        StringComparison.OrdinalIgnoreCase) >= 0;
	
	                bool looksLikePowerShell =
	                    content.IndexOf(
	                        "$Version",
	                        StringComparison.OrdinalIgnoreCase) >= 0 ||
	                    content.IndexOf(
	                        "function ",
	                        StringComparison.OrdinalIgnoreCase) >= 0 ||
	                    content.IndexOf(
	                        "param(",
	                        StringComparison.OrdinalIgnoreCase) >= 0;
	
	                return mentionsSpotiX && looksLikePowerShell;
	            }
	            catch
	            {
	                return false;
	            }
	        }
	
	        private void RunOnUi(MethodInvoker action)
	        {
	            try
	            {
	                if (contextMenu.IsDisposed)
	                    return;
	
	                if (contextMenu.InvokeRequired)
	                    contextMenu.BeginInvoke(action);
	                else
	                    action();
	            }
	            catch { }
	        }
	
	        private void ShowLocalizedMessage(string message, MessageBoxIcon icon)
	        {
	            MessageBox.Show(
	                message,
	                "SpotiX+ Reborn",
	                MessageBoxButtons.OK,
	                icon);
	        }
	
	        private void OpenUrl(string url)
	        {
	            try
	            {
	                Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
	                Log("Lien ouvert : " + url);
	            }
	            catch (Exception ex)
	            {
	                Log("Impossible d'ouvrir le lien '" + url + "' : " + ex.Message);
	            }
	        }
	
	        private void QuitSpotify()
	        {
	            Process[] processes = Process.GetProcessesByName("Spotify");
	            try
	            {
	                foreach (Process process in processes)
	                {
	                    try
	                    {
	                        if (!process.HasExited)
	                            process.Kill();
	                    }
	                    catch { }
	                }
	                Log("Fermeture de Spotify demandée.");
	            }
	            finally
	            {
	                foreach (Process process in processes)
	                    process.Dispose();
	            }
	        }
	
	        private void Log(string message)
	        {
	            lock (logLock)
	            {
	                try
	                {
	                    File.AppendAllText(
	                        logPath,
	                        DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + " | " + message + Environment.NewLine,
	                        Encoding.UTF8);
	                }
	                catch { }
	            }
	        }
	
	        protected override void ExitThreadCore()
	        {
	            shuttingDown = true;
	            try { launchSpotifyEvent.Set(); }
	            catch { }
	            try { launchSpotifyThread.Join(1500); }
	            catch { }
	            try { launchSpotifyEvent.Dispose(); }
	            catch { }
	
	            monitorTimer.Stop();
	            monitorTimer.Dispose();
	            notifyIcon.Visible = false;
	            notifyIcon.Dispose();
	            loadedIcon.Dispose();
	            trayRemover.Dispose();
	
	            lock (launchedProcessesLock)
	            {
	                foreach (Process process in launchedSpotifyProcesses.ToArray())
	                {
	                    try
	                    {
	                        process.CancelOutputRead();
	                        process.CancelErrorRead();
	                    }
	                    catch { }
	
	                    try { process.Dispose(); }
	                    catch { }
	                }
	
	                launchedSpotifyProcesses.Clear();
	            }
	
	            Log("Arrêt de SpotiX+ Companion.");
	            base.ExitThreadCore();
	        }
	    }
	
	    public static class EntryPoint
	    {
	        private static Mutex instanceMutex;
	
	        public static void Run(
	            string iconPath,
	            string logPath,
	            string spotifyLogsDirectory,
	            string trayIdCachePath,
	            bool autoStartSpotify)
	        {
	            bool createdNew;
	            instanceMutex = new Mutex(
	                true,
	                "SpotiXPlus_Companion_1534250854087921725",
	                out createdNew);
	
	            if (!createdNew)
	                return;
	
	            Application.EnableVisualStyles();
	            Application.SetCompatibleTextRenderingDefault(false);
	            Application.Run(
	                new CompanionContext(
	                    iconPath,
	                    logPath,
	                    spotifyLogsDirectory,
	                    trayIdCachePath,
	                    autoStartSpotify));
	            GC.KeepAlive(instanceMutex);
	        }
	    }
	}
	'@
	
	try {
	    $CompilerReferences = @(
	        [System.Windows.Forms.NotifyIcon].Assembly.Location
	        [System.Drawing.Icon].Assembly.Location
	    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
	
	    Write-BootLog ("Compilation C# avec les références : " + ($CompilerReferences -join '; '))
	    Add-Type -TypeDefinition $Source -Language CSharp -ReferencedAssemblies $CompilerReferences
	    Write-BootLog 'Compilation terminée. Lancement de SpotiXPlusCompanion.EntryPoint.'
	    [SpotiXPlusCompanion.EntryPoint]::Run(
	        $IconPath,
	        $LogPath,
	        $SpotifyLogDirectory,
	        $TrayIdCachePath,
	        $false
	    )
	}
	catch {
	    $ErrorDetails = $_ | Out-String
	    Write-BootLog ("ÉCHEC : " + $ErrorDetails.Trim())
	
	    $Message = "SpotiX+ Companion n'a pas pu démarrer.`r`n`r`n$($_.Exception.Message)`r`n`r`nLog :`r`n$LogPath"
	    [System.Windows.Forms.MessageBox]::Show(
	        $Message,
	        'SpotiX+ Reborn',
	        [System.Windows.Forms.MessageBoxButtons]::OK,
	        [System.Windows.Forms.MessageBoxIcon]::Error
	    ) | Out-Null
	}
	
'@

        $LauncherSource = @'
	$ErrorActionPreference = "SilentlyContinue"
	
	$CompanionFolder = Join-Path $env:LOCALAPPDATA "SpotiXPlus"
	$CompanionScript = Join-Path $CompanionFolder "SpotiXCompanion.ps1"
	$PowerShellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
	$EventName = "Local\SpotiXPlus_Companion_LaunchSpotify"
	
	function Send-SpotiXLaunchRequest {
	    try {
	        $LaunchEvent = [Threading.EventWaitHandle]::OpenExisting($EventName)
	        try {
	            [void]$LaunchEvent.Set()
	            return $true
	        }
	        finally {
	            $LaunchEvent.Dispose()
	        }
	    }
	    catch {
	        return $false
	    }
	}
	
	if (Send-SpotiXLaunchRequest) {
	    exit 0
	}
	
	if (Test-Path -LiteralPath $CompanionScript -PathType Leaf) {
	    Start-Process `
	        -FilePath $PowerShellExe `
	        -ArgumentList "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$CompanionScript`" -NoAutoStartSpotify" `
	        -WindowStyle Hidden `
	        -ErrorAction SilentlyContinue
	
	    for ($Attempt = 0; $Attempt -lt 40; $Attempt++) {
	        Start-Sleep -Milliseconds 250
	        if (Send-SpotiXLaunchRequest) {
	            exit 0
	        }
	    }
	}
	
	# Secours : si le compagnon ne répond pas, Spotify reste lançable.
	$SpotifyExe = Join-Path $env:APPDATA "Spotify\Spotify.exe"
	if (Test-Path -LiteralPath $SpotifyExe -PathType Leaf) {
	    Start-Process -FilePath $SpotifyExe -ErrorAction SilentlyContinue
	}
	
'@

        $LauncherVbsSource = @'
	Option Explicit
	Dim shell, fso, folder, scriptPath, command
	Set shell = CreateObject("WScript.Shell")
	Set fso = CreateObject("Scripting.FileSystemObject")
	folder = fso.GetParentFolderName(WScript.ScriptFullName)
	scriptPath = fso.BuildPath(folder, "SpotiXLauncher.ps1")
	command = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """"
	shell.Run command, 0, False
	
'@

        WriteSpotiXEmbeddedFile `
            -Path $CompanionScript `
            -IndentedContent $CompanionSource `
            -Utf8Bom $true

        WriteSpotiXEmbeddedFile `
            -Path $LauncherScript `
            -IndentedContent $LauncherSource `
            -Utf8Bom $true

        WriteSpotiXEmbeddedFile `
            -Path $LauncherVbs `
            -IndentedContent $LauncherVbsSource `
            -Utf8Bom $false

        if (Test-Path -LiteralPath $SpotifyIcon -PathType Leaf) {
            Copy-Item -LiteralPath $SpotifyIcon -Destination $CompanionIcon -Force
        }

        $WshShell = New-Object -ComObject WScript.Shell
        try {
            $Shortcut = $WshShell.CreateShortcut($StartupShortcut)
            $Shortcut.TargetPath = $WindowsPowerShell
            $Shortcut.Arguments = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$CompanionScript`" -NoAutoStartSpotify"
            $Shortcut.WorkingDirectory = $CompanionFolder
            if (Test-Path -LiteralPath $CompanionIcon) {
                $Shortcut.IconLocation = "$CompanionIcon,0"
            }
            $Shortcut.Description = "SpotiX+ Companion"
            $Shortcut.WindowStyle = 7
            $Shortcut.Save()
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($Shortcut)
        }
        finally {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell)
        }

        Start-Process `
            -FilePath $WindowsPowerShell `
            -ArgumentList "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$CompanionScript`" -NoAutoStartSpotify" `
            -WindowStyle Hidden `
            -ErrorAction Stop

        $Desktop = [Environment]::GetFolderPath("Desktop")
        $StartMenu = [Environment]::GetFolderPath("Programs")
        $Documents = [Environment]::GetFolderPath("MyDocuments")
        $ShortcutIcon = if (Test-Path -LiteralPath $SpotifyIcon) { $SpotifyIcon } else { $CompanionIcon }

        @(
            (Join-Path $Desktop "SpotiX+.lnk"),
            (Join-Path (Join-Path $StartMenu "SpotiX+ Reborn") "SpotiX+.lnk"),
            (Join-Path (Join-Path $Documents "SpotiX+ Reborn") "SpotiX+.lnk")
        ) | ForEach-Object {
            SetSpotiXShortcutTarget -ShortcutPath $_ -IconPath $ShortcutIcon | Out-Null
        }

        Write-Host (GetTranslation "companion-installed") -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host (GetTranslation "companion-error") -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        return $false
    }
}

function SetSpotiXShortcutTarget {
    param(
        [Parameter(Mandatory)][string]$ShortcutPath,
        [Parameter(Mandatory)][string]$IconPath,
        [string]$Description = "SpotiX+ Reborn by Voltan, made with <3"
    )

    $LauncherVbs = Join-Path (Join-Path $env:LOCALAPPDATA "SpotiXPlus") "SpotiXLauncher.vbs"
    $WscriptExe = Join-Path $env:WINDIR "System32\wscript.exe"

    if (-not (Test-Path -LiteralPath $LauncherVbs -PathType Leaf)) {
        return $false
    }

    $ShortcutFolder = Split-Path -Parent $ShortcutPath
    if ($ShortcutFolder -and -not (Test-Path -LiteralPath $ShortcutFolder)) {
        New-Item -ItemType Directory -Path $ShortcutFolder -Force | Out-Null
    }

    $WshShell = New-Object -ComObject WScript.Shell
    try {
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $WscriptExe
        $Shortcut.Arguments = "`"$LauncherVbs`""
        $Shortcut.WorkingDirectory = Split-Path -Parent $LauncherVbs
        $Shortcut.IconLocation = "$IconPath,0"
        $Shortcut.Description = $Description
        $Shortcut.WindowStyle = 7
        $Shortcut.Save()
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($Shortcut)
        return $true
    }
    finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell)
    }
}

function InstallDev {
	#dev
	#Delof le farfadet malicieux
	Write-Host "Bravo, vous avez trouvé le mode dev !!!"
	Write-Host "Malheuresement, il n'y a rien à voir ici"
	Write-Host "Et puis, même si y'avait un truc ici, vous ne devriez pas être là"
	Write-Host "Donc DÉGAGEZ !!!"
	Write-Host "Ou restez, jsp, je m'en fous en fait"
	Write-Host "Si vous souhaitez partir, appuyez sur la touche Entrée"
	EnterToContinue -DefaultPrompt $true
}

# Désinstaller Spotify (UWP)
function Msstore {
	PrintLogo
	$spotifymsstore = Get-AppxPackage -Name "SpotifyAB.SpotifyMusic"
	if ($spotifymsstore) {
		Write-Host (GetTranslation "msstore-check-found").Replace("`$ms_version", $spotifymsstore.Version) -ForegroundColor Yellow
		Write-Host (GetTranslation "msstore-check-warning")
		$confirmation3 = Read-Host -Prompt (GetTranslation "msstore-check-prompt")
		if ($confirmation3 -eq "Y") {
			Write-Host (GetTranslation "msstore-check-uninstalling").Replace("`$ms_version", $spotifymsstore.Version)
			Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command `"Get-AppxPackage -Name 'SpotifyAB.SpotifyMusic' | Remove-AppxPackage`"" -Wait -Verb RunAs
			Start-Sleep -Seconds 2
			$spotifymsstore = Get-AppxPackage -Name "SpotifyAB.SpotifyMusic"
			if ($spotifymsstore) {
				Write-Host (GetTranslation "msstore-check-uninstall-failed") -Foregroundcolor Red
				# En cas d'échec de la désinstallation
				$confirmation4 = Read-Host -Prompt (GetTranslation "retry")
				if ($confirmation4 -eq "Y") {
					Msstore
				} else {
					Write-Host (GetTranslation "script-will-continue")
					Start-Sleep -Seconds 2
					Install
					Main
				}
			} else {
				Write-Host (GetTranslation "msstore-check-uninstalled-successfully") -ForegroundColor Green
				EnterToContinue -DefaultPrompt $true
				Install
				Main
			}

		} else {
			Write-Host (GetTranslation "script-will-continue")
			Start-Sleep -Seconds 2
			Install
			Main
		}

	} else {
		Install
		Main
	}

}

function Install {
	# Installation
	PrintLogo
	# Détection d'une installation de Spotify (Win32)
	if (Test-Path "$env:AppData\Spotify\Spotify.exe") {
		Write-Host (GetTranslation "spotify-check-found") -ForegroundColor Yellow
		$confirmation1 = Read-Host -Prompt (GetTranslation "spotify-check-prompt")
		if ($confirmation1 -eq "Y") {
			# Lancement de la désinstallation
			Write-Host (GetTranslation "spotify-check-uninstalling")
			if (Test-Path "$env:AppData\Spotify\uninstall.exe") {
			Start-Process -FilePath "$env:AppData\Spotify\uninstall.exe" -NoNewWindow -Wait
			}
			else {
				Start-Process -FilePath "$env:AppData\Spotify\Spotify.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
			}
			if (Test-Path "$env:AppData\Spotify\Spotify.exe") {
				Write-Host (GetTranslation "spotify-check-uninstalling-failed") -ForegroundColor Red
				EnterToContinue
			} else {
				Write-Host (GetTranslation "spotify-check-uninstall-successful") -ForegroundColor Green
				Write-Host (GetTranslation "script-will-continue")
				Start-Sleep -Seconds 3
				Install
				Main
			}
		} else {
			Write-Host (GetTranslation "spotify-check-returning") -ForegroundColor Red
			Start-Sleep -Seconds 3
			return
		}
	} else {
			Write-Host ((
				(GetTranslation "app-install-version-choice-prompt"),
				"1. $(GetTranslation 'app-install-version-choice-version1')",
				"2. $(GetTranslation 'app-install-version-choice-version2')",
				"3. $(GetTranslation 'app-install-version-choice-version3')"
			) -join "`n`t")
			Write-Host (GetTranslation "app-install-version-choice-more-info")
			$confirmation2 = GetUserChoices -validResponses @("1", "2", "3")
			switch ($confirmation2.Trim()) {
				"1"{
					# URL et fichier pour la nouvelle interface
					$url = "https://download.scdn.co/SpotifySetup.exe"
					$spotifyInstaller = "$env:TEMP\SpotifySetup.exe"
				}
				"2" {
					$url = "https://spotixplus.fr/files/windows/script/spotify1.2.78.exe"
					$spotifyInstaller = "$env:TEMP\spotify1.2.78.exe"
				}
				"3" {ping 
					# URL et fichier pour l'ancienne interface
					$url = "https://spotixplus.fr/files/windows/script/SpotifyFull7-8-8.1.exe"
					$spotifyInstaller = "$env:TEMP\SpotifyFull7-8-8.1.exe"
				}
			}

			# Installation de Spotify
			SetTitle (GetTranslation "installation")
			PrintLogo

			Write-Host (GetTranslation "downloading-and-installing")

			$webClient = New-Object System.Net.WebClient
			$webClient.DownloadFile($url, $spotifyInstaller)

			Start-Process $spotifyInstaller
			Write-Host (GetTranslation "spotify-install-warning") -ForegroundColor Red
			Write-Host (GetTranslation "spotify-install-prompt")
			EnterToContinue

			# SpotX
			Write-Host (GetTranslation "spotx-cli-download")
			SetTitle (GetTranslation "spotx-configuration")
			Clear-Host
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/main/run.ps1').Content) }"
			Write-Host (GetTranslation "spotx-installed")

			# Fermeture de Spotify
			Write-Host (GetTranslation "spotify-closing")
			StopSpotify

			# Dossier Spicetify
			Write-Host "Création des dossiers nécessaires"
			if (-not (Test-Path -Path "$env:AppData\spicetify\")) {
				New-Item -Path "$env:AppData\spicetify\" -ItemType Directory
			}

			# Spicetify
			SetTitle (GetTranslation "spicetify-configuration")
			Clear-Host
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1').Content) }"
			Write-Host (GetTranslation "spicetify-installed")
			StopSpotify

			# Modification interface
			Write-Host (GetTranslation "app-configuration")
			Download -URL "https://spotixplus.fr/files/windows/script/frdesactived.mo" -Path "$env:AppData\Spotify\locales\frdesactived.mo"

			if (Test-Path "$env:AppData\Spotify\locales\frdesactived.mo") {
				$asupp = "$env:AppData\Spotify\locales\fr.mo"
				Remove-Item -Path $asupp
				$oldFile1 = "$env:AppData\Spotify\locales\frdesactived.mo"
				$newFile1 = "$env:AppData\Spotify\locales\fr.mo"
				Rename-Item -Path $oldFile1 -NewName $newFile1
			} else {
				SetTitle (GetTranslation "error")
				Write-Host (GetTranslation "download-app-files") -ForegroundColor Red
				EnterToContinue
				exit
			}

			# Modification license
			$asupp0 = "$env:AppData\Spotify\Apps\xpui\licenses.html"
			Remove-Item -Path $asupp0
			$fredirect = "$env:AppData\Spotify\Apps\xpui"
			if (-not (Test-Path -Path $fredirect)) {
				New-Item -Path $fredirect -ItemType Directory
			}
			$redirect = "licenses.html"
			$licensesfiles = Join-Path $fredirect $redirect
			$contenu = "<iframe src=`"https://spotixplus.fr/redirect.php`" width=`"590`" height=`"317`" allow=`"fullscreen`"></iframe>"
			$contenu | Out-File -FilePath $licensesfiles

			# Conditions
			Write-Host (GetTranslation "app-configuration")
			$pathconfig = "$env:AppData\Spotify\"
			New-Item -Path $pathconfig -Name "config.need" -ItemType "File" -Force

			# Plugins
			SetTitle (GetTranslation "spicetify-plugins")
			PrintLogo

			Write-Host (GetTranslation "spicetify-plugins-prompt")
			Write-Host ((
				(GetTranslation "spicetify-plugins-prompt-2"),
				"1. $(GetTranslation 'spicetify-plugins-plugin-1')",
				"2. $(GetTranslation 'spicetify-plugins-plugin-2')",
				"3. $(GetTranslation 'spicetify-plugins-plugin-3')"
			) -join "`n`t")
			Write-Host (GetTranslation "spicetify-plugins-prompt-3")
			$userChoices = GetUserChoices -validResponses @("1", "2", "3") -Multiple $true

			# Installation des plugins en fonction des réponses
			foreach ($choice in $userChoices) {
				switch ($choice.Trim()) {
					"1" {
						Write-Output (GetTranslation "spicetify-plugin-reddit-installing")
						spicetify config custom_apps reddit
						spicetify apply
						Write-Output (GetTranslation "spicetify-plugin-reddit-installing-success")
					}
					"2" {
						Write-Output (GetTranslation "spicetify-plugin-lyricsplus-installing")
						spicetify config custom_apps lyrics-plus
						spicetify apply
						Write-Output (GetTranslation "spicetify-plugin-lyricsplus-installing-success")
					}
					"3" {
						Write-Output (GetTranslation "spicetify-plugin-lyricsplus-installing")
						spicetify config custom_apps new-releases
						spicetify apply
						Write-Output (GetTranslation "spicetify-plugin-lyricsplus-installing-success")
					}
				}
			}
			StopSpotify
			Clear-Host

			#Qualité audio
			HighQuality

			#SpotiFLAC
			SpotiFLAC

			#Rich Presence Discord
			InstallDiscordRichPresence

			Write-Host ".."
			# Renommer le raccourci Spotify du bureau
			#$oldFile = "$env:UserProfile\Desktop\Spotify.lnk"
			#$newFile = "$env:UserProfile\Desktop\$AppNameShort.lnk"
			#Rename-Item -Path $oldFile -NewName $newFile
			#Rename-Item -Path "$env:UserProfile\Desktop\Spotify.lnk" -NewName "$AppNameShort.lnk"


			# Renommer le raccourci Spotify du menu démarrer
			#$oldFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
			#$newFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"
			#Rename-Item -Path $oldFile -NewName $newFile
			#Rename-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk" -NewName "$AppNameShort.lnk"

			$SpotifyFolder = Join-Path $env:APPDATA "Spotify"
			$SpotifyExe     = Join-Path $SpotifyFolder "Spotify.exe"
			$IconPath      = Join-Path $SpotifyFolder "iconapp.ico"
			$IconUrl       = "https://spotixplus.fr/assets/icons/iconapp.ico"
			$Desktop       = [Environment]::GetFolderPath("Desktop")
			$PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
			$ShortcutPath  = Join-Path $Desktop "SpotiX+.lnk"
			$StartMenu         = [Environment]::GetFolderPath("Programs")
			$StartMenuFolder   = Join-Path $StartMenu "SpotiX+ Reborn"
			$StartMenuShortcut = Join-Path $StartMenuFolder "SpotiX+.lnk"
			$DocumentsFolder  = [Environment]::GetFolderPath("MyDocuments")
			$SpotiXDocuments  = Join-Path $DocumentsFolder "SpotiX+ Reborn"
			$DocumentsShortcut = Join-Path $SpotiXDocuments "SpotiX+.lnk"

			# Créer le dossier Documents\SpotiX+ Reborn s’il n’existe pas
			if (-not (Test-Path -LiteralPath $SpotiXDocuments)) {
    			New-Item `
        		-ItemType Directory `
        		-Path $SpotiXDocuments `
       		 -Force | Out-Null
			}

			try {
   				Invoke-WebRequest `
      			-Uri $IconUrl `
      			-OutFile $IconPath `
       			-UseBasicParsing `
        		-ErrorAction Stop

    		 @(
        		(Join-Path $Desktop "Spotify.lnk"),
        		(Join-Path $PublicDesktop "Spotify.lnk"),
        		(Join-Path $StartMenu "Spotify.lnk"),
        		(Join-Path $StartMenu "SpotiX+.lnk"),
        		$ShortcutPath,
        		$StartMenuShortcut

    		) | ForEach-Object {
       			 Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue
    		}

    		New-Item `
        		-ItemType Directory `
        		-Path $StartMenuFolder `
        		-Force | Out-Null
    		
			$WshShell = New-Object -ComObject WScript.Shell

			$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

			$Shortcut = $WshShell.CreateShortcut($StartMenuShortcut)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

			# Raccourci dans Documents\SpotiX+ Reborn
			$Shortcut = $WshShell.CreateShortcut($DocumentsShortcut)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

    		[void][Runtime.InteropServices.Marshal]::ReleaseComObject($Shortcut)
    		[void][Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell)

    		Start-Process `
        		-FilePath "$env:WINDIR\System32\ie4uinit.exe" `
        		-ArgumentList "-show" `
        		-WindowStyle Hidden `
       		 	-ErrorAction SilentlyContinue
		}
			catch {
   		 	Write-Host "Erreur pendant la création du raccourci Spotify :" -ForegroundColor Red
    		Write-Host $_.Exception.Message -ForegroundColor DarkRed
	}

			# SpotiX+ Companion : icône de notification, suppression de l’icône native,
			# journalisation Spotify et gestion rapide depuis la barre des tâches.
			$null = InstallSpotiXCompanion

			SetTitle (GetTranslation "install-finished")
			PrintLogo
			Write-Host (GetTranslation "configuration-finished")
			StopSpotify
			Write-Host (GetTranslation "install-successful") -Foregroundcolor Green
			EnterToContinue -DefaultPrompt $true
			return
	}
}

function Uninstall {
	PrintLogo
	# Désinstallation

	if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "uninstall-app-not-found")
		EnterToContinue -DefaultPrompt $true
		return
	}

	$confirmation = Read-Host -Prompt (GetTranslation "uninstall-app-confirmation")
	PrintLogo
	if ($confirmation -eq "Y") {
		SetTitle (GetTranslation "uninstalling")
		StopSpotify
		RemoveDiscordRichPresence
		Write-Host (GetTranslation "uninstall-starting")

		# Suppression des dossiers/fichiers
		Write-Host (GetTranslation "spotify-uninstall")
		if (Test-Path "$env:AppData\Spotify\uninstall.exe") {
			Start-Process -FilePath "$env:AppData\Spotify\uninstall.exe" -NoNewWindow -Wait
		}
		else {
			Start-Process -FilePath "$env:AppData\Spotify\Spotify.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
		}
		if (Test-Path "$env:AppData\Spotify\Spotify.exe") {
			Write-Host (GetTranslation "spotify-uninstall-fail") -Foregroundcolor Red
			EnterToContinue
			Main
		}
		Write-Host (GetTranslation "spicetify-uninstalling")
		RemoveIfExists "$env:AppData\spicetify"

		Write-Host (GetTranslation "spotify-uninstall-complete")

		$prefs = "$env:AppData\Spotify\prefs"
		if (Test-Path -Path $prefs) {
			Set-ItemProperty -Path $prefs -Name IsReadOnly -Value $false
		}
		$tmp = "$env:AppData\Spotify\prefs.tmp"
		if (Test-Path -Path $tmp) {
			Set-ItemProperty -Path $tmp -Name IsReadOnly -Value $false
		}
		
		RemoveSpotiXCompanion

		Write-Host (GetTranslation "spotx-uninstall")
		RemoveIfExists "$env:AppData\Spotify"
		RemoveIfExists "$env:LocalAppData\Spotify"
		RemoveIfExists "$env:UserProfile\Desktop\$AppNameShort.lnk"
		RemoveIfExists "$env:AppData\Microsoft\Windows\Start Menu\Programs\SpotiX+ Reborn"

		Write-Host (GetTranslation "spotiflac-uninstalling")
		RemoveIfExists "$env:UserProfile\Documents\SpotiX+ Reborn"
		RemoveIfExists "$env:UserProfile\Desktop\SpotiFLAC.lnk"
		RemoveIfExists "$env:AppData\SpotiFLAC.exe"

		Write-Host (GetTranslation "app-uninstalled-successfully")
		EnterToContinue -DefaultPrompt $true
		return
	} else {
		Write-Host (GetTranslation "cancelling")
		Start-Sleep -Seconds 3
		return
	}
}

function HighQuality {
	# Qualité audio
	SetTitle (GetTranslation "audio-configuration")
	PrintLogo

	if (-not (Test-Path -Path "$env:AppData\Spotify")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "app-installed-check")
		EnterToContinue -DefaultPrompt $true
		return
	}

	# Fichier trouvé
	Write-Host (GetTranslation "audio-warning") -ForegroundColor Red
	Write-Host ((
		(GetTranslation "audio-prompt"),
		"1. $(GetTranslation 'audio-high')",
		"2. $(GetTranslation 'audio-low')",
		"3. $(GetTranslation 'audio-no-changes')"
	) -join "`n`t")
	$userChoices = GetUserChoices -validResponses @("1", "2", "3")
	PrintLogo
	SetTitle (GetTranslation "audio-configuration")

	switch ($userChoices.Trim()) {
		"1" {
			StopSpotify
			Write-Host (GetTranslation "audio-high-configuration")
			$audioveryhigh = (
				"audio.sync_bitrate=320000",
				"audio.play_bitrate=320000"
			)

			$prefs = "$env:AppData\Spotify\prefs"
			$tmp = "$env:AppData\Spotify\prefs.tmp"
			Add-Content -Path $prefs -Value $audioveryhigh
			Set-ItemProperty -Path $prefs -Name IsReadOnly -Value $true
			Write-Host "."
			Add-Content -Path $tmp -Value $audioveryhigh
			Set-ItemProperty -Path $tmp -Name IsReadOnly -Value $true
			Write-Host ".."
			Download -URL "https://spotixplus.fr/files/windows/script/fractived.mo" -Path "$env:AppData\Spotify\locales\fractived.mo"

			if (Test-Path "$env:AppData\Spotify\locales\fractived.mo") {
				Write-Host "..."
				$asupp = "$env:AppData\Spotify\locales\fr.mo"
				Remove-Item -Path $asupp
				$oldFile1 = "$env:AppData\Spotify\locales\fractived.mo"
				$newFile1 = "$env:AppData\Spotify\locales\fr.mo"
				Rename-Item -Path $oldFile1 -NewName $newFile1
			} else {
				SetTitle (GetTranslation "error")
				Write-Host (GetTranslation "audio-error") -ForegroundColor Red
				EnterToContinue
				Write-Host (GetTranslation "closing-window")
				Stop-Transcript
				exit
			}
			Write-Host (GetTranslation "audio-high-done")
			EnterToContinue -DefaultPrompt $true
		}
		"2" {
			StopSpotify
			Write-Host (GetTranslation "audio-low-configuration")
			$audioveryhigh = (
				"audio.sync_bitrate=320000",
				"audio.play_bitrate=320000"
			)

			$prefs = "$env:AppData\Spotify\prefs"
			$tmp = "$env:AppData\Spotify\prefs.tmp"
			Set-ItemProperty -Path $prefs -Name IsReadOnly -Value $false
			Set-ItemProperty -Path $tmp -Name IsReadOnly -Value $false
			if (Test-Path -Path $prefs) {
				$content = Get-Content -Path $prefs
				$newContent = $content | Where-Object { $_ -notmatch "audio.sync_bitrate=320000" -and $_ -notmatch "audio.play_bitrate=320000" }
				Set-Content -Path $prefs -Value $newContent
				Write-Host "."
			}
			if (Test-Path -Path $tmp) {
				$content = Get-Content -Path $tmp
				$newContent = $content | Where-Object { $_ -notmatch "audio.sync_bitrate=320000" -and $_ -notmatch "audio.play_bitrate=320000" }
				Set-Content -Path $tmp -Value $newContent
				Write-Host ".."
			}

			Download -URL "https://spotixplus.fr/files/windows/script/frdesactived.mo" -Path "$env:AppData\Spotify\locales\frdesactived.mo"

			if (Test-Path "$env:AppData\Spotify\locales\frdesactived.mo") {
				Write-Host "..."
				$asupp = "$env:AppData\Spotify\locales\fr.mo"
				Remove-Item -Path $asupp
				$oldFile1 = "$env:AppData\Spotify\locales\frdesactived.mo"
				$newFile1 = "$env:AppData\Spotify\locales\fr.mo"
				Rename-Item -Path $oldFile1 -NewName $newFile1
			} else {
				SetTitle (GetTranslation "error")
				Write-Host (GetTranslation "audio-error") -ForegroundColor Red
				EnterToContinue
				Write-Host (GetTranslation "closing-window")
				Stop-Transcript
				exit
			}
			Write-Host (GetTranslation "audio-low-done")
			EnterToContinue -DefaultPrompt $true
		}
	}
}

function SpotiFLAC {
	#Mode téléchargement
	Clear-Host
	SetTitle (GetTranslation "spotiflac")
	PrintLogo
	if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "app-installed-check")
		EnterToContinue -DefaultPrompt $true
		return
	}
	Write-Host (GetTranslation "soggfy-dead")
	Write-Host (GetTranslation "soggfy-dead1")
	Write-Host ""
	Write-Host ((
		(GetTranslation "spotiflac-confirm"),
		"1. $(GetTranslation 'spotiflac-ok')",
		"2. $(GetTranslation 'return')"
	) -join "`n`t")
	$userChoices = GetUserChoices -validResponses @("1", "2")
	switch ($userChoices.Trim()) {
		"1" {
    $DocumentsFolder = [Environment]::GetFolderPath("MyDocuments")
    $SpotiXFolder    = Join-Path $DocumentsFolder "SpotiX+ Reborn"
    $SpotiFLACExe  = Join-Path $SpotiXFolder "SpotiFLAC.exe"
	$Desktop       = [Environment]::GetFolderPath("Desktop")
	$PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
	$ShortcutPath  = Join-Path $Desktop "SpotiFLAC.lnk"
    $TemporaryFile = Join-Path $env:TEMP "SpotiFLAC.download"
    $StartMenu         = [Environment]::GetFolderPath("Programs")
    $StartMenuFolder   = Join-Path $StartMenu "SpotiX+ Reborn"
    $StartMenuShortcut = Join-Path $StartMenuFolder "SpotiFLAC.lnk"
    $GitHubApi = "https://api.github.com/repos/spotbye/SpotiFLAC/releases/latest"

    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.SecurityProtocolType]::Tls12

        if (-not (Test-Path -LiteralPath $SpotiXFolder)) {
            New-Item `
                -ItemType Directory `
                -Path $SpotiXFolder `
                -Force | Out-Null
        }
        if (-not (Test-Path -LiteralPath $StartMenuFolder)) {
            New-Item `
                -ItemType Directory `
                -Path $StartMenuFolder `
                -Force | Out-Null
        }

		#check la derniere ver de spotiflac
        $Release = Invoke-RestMethod `
            -Uri $GitHubApi `
            -Headers @{
                "Accept"               = "application/vnd.github+json"
                "User-Agent"           = "SpotiXPlus-Reborn"
                "X-GitHub-Api-Version" = "2022-11-28"
            } `
            -ErrorAction Stop

        $Asset = $Release.assets |
            Where-Object {
                $_.name -eq "SpotiFLAC.exe"
            } |
            Select-Object -First 1

        if (-not $Asset) {
            $Asset = $Release.assets |
                Where-Object {
                    $_.name -match "(?i)^SpotiFLAC.*\.exe$" -and
                    $_.name -notmatch "(?i)setup|installer"
                } |
                Select-Object -First 1
        }
        if (-not $Asset) {
            Write-Host (GetTranslation "spotiflac-error1") ForegroundColor Red
			return
        }

        Remove-Item `
            -LiteralPath $TemporaryFile `
            -Force `
            -ErrorAction SilentlyContinue

		Write-Host ""
        Write-Host (GetTranslation "spotiflac-download").Replace("`$(`$Release.tag_name)", $($Release.tag_name)) `
            -ForegroundColor Cyan

        Invoke-WebRequest `
            -Uri $Asset.browser_download_url `
            -OutFile $TemporaryFile `
            -UseBasicParsing `
            -Headers @{
                "User-Agent" = "SpotiXPlus-Reborn"
            } `
            -ErrorAction Stop

        if (
            -not (Test-Path -LiteralPath $TemporaryFile) -or
            (Get-Item -LiteralPath $TemporaryFile).Length -lt 100KB
        ) {
            Write-Host (GetTranslation "spotiflac-error2") ForegroundColor Red
			return
        }

        Move-Item `
            -LiteralPath $TemporaryFile `
            -Destination $SpotiFLACExe `
            -Force `
            -ErrorAction Stop
        Remove-Item `
            -LiteralPath $StartMenuShortcut `
            -Force `
            -ErrorAction SilentlyContinue

        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($StartMenuShortcut)
        $Shortcut.TargetPath       = $SpotiFLACExe
        $Shortcut.WorkingDirectory = $SpotiXFolder
        $Shortcut.IconLocation     = "$SpotiFLACExe,0"
        $Shortcut.Description      = "SpotiFLAC - https://github.com/spotbye/SpotiFLAC"
        $Shortcut.WindowStyle      = 1
        $Shortcut.Save()

		$WshShell = New-Object -ComObject WScript.Shell
		$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
		$Shortcut.TargetPath       = $SpotiFLACExe
		$Shortcut.WorkingDirectory = $SpotiXFolder
		$Shortcut.IconLocation     = "$SpotiFLACExe,0"
		$Shortcut.Description      = "SpotiFLAC - https://github.com/spotbye/SpotiFLAC"
		$Shortcut.Save()

        Write-Host (GetTranslation "spotiflac-done") `
            -ForegroundColor Green

        Write-Host (GetTranslation "spotiflac-location").Replace("`$SpotiFLACExe", $SpotiFLACExe) `
            -ForegroundColor DarkGray
		Write-Host (GetTranslation "enter-to-continue")
			EnterToContinue
    }
    catch {
        Remove-Item `
            -LiteralPath $TemporaryFile `
            -Force `
            -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host (GetTranslation "spotiflac-install-error") `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor DarkRed
    }
    finally {
        if ($Shortcut) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
                $Shortcut
            )
        }
        if ($WshShell) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject(
                $WshShell
            )
        }
    }
  }
}

}

function SpicetifyH {
	SetTitle (GetTranslation "spicetify-helper")
	PrintLogo
	if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "uninstall-app-not-found")
		EnterToContinue -DefaultPrompt $true
		return
	}

	#check si spicetify est installer
	$SpicetifyExe = Join-Path $env:LOCALAPPDATA "spicetify\spicetify.exe"

	if (Test-Path -LiteralPath $SpicetifyExe) {
		Write-Host (GetTranslation "spicetify-ok")  -ForegroundColor Green
	}
	else {
		Write-Host (GetTranslation "spicetify-no")  -ForegroundColor Red
	}

	Write-Host ""
	Write-Host (GetTranslation "spicetify-configh") 
	Write-Host ((
		(GetTranslation "spicetify-configh1"),
		"1. $(GetTranslation 'spicetify-install')",
		"2. $(GetTranslation 'spicetify-uninstall')",
		"3. $(GetTranslation 'return')"
	) -join "`n`t")
	$userChoices = GetUserChoices -validResponses @("1", "2", "3")
	PrintLogo
	SetTitle (GetTranslation "spicetify-helper")

	switch ($userChoices.Trim()) {
		"1" {
			StopSpotify
			SetTitle (GetTranslation "spicetify-configuration")
			Clear-Host
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1').Content) }"
			Write-Host (GetTranslation "spicetify-installed2")
			EnterToContinue -DefaultPrompt $true
		}
		"2" {
			StopSpotify
			Write-Host (GetTranslation "spicetify-uninstalling")
			RemoveIfExists "$env:AppData\spicetify"

			Write-Host (GetTranslation "spicetify-uninstall-done")
			EnterToContinue -DefaultPrompt $true
		}
	}
}

function CreateShortcutOnDesktop {
	SetTitle (GetTranslation "create-shortcut-on-desktop-title")
	PrintLogo
	if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "uninstall-app-not-found")
		EnterToContinue -DefaultPrompt $true
		return
	}

	Write-Host ((
		(GetTranslation "create-shortcut-on-desktop"),
		"1. $(GetTranslation 'create-shortcut')",
		"2. $(GetTranslation 'return')"
	) -join "`n`t")
	$userChoices = GetUserChoices -validResponses @("1", "2")
	PrintLogo
	SetTitle (GetTranslation "create-shortcut-on-desktop-title")

	switch ($userChoices.Trim()) {
		"1" {
			SetTitle (GetTranslation "create-shortcut-on-desktop-title")
			$SpotifyFolder = Join-Path $env:APPDATA "Spotify"
			$SpotifyExe     = Join-Path $SpotifyFolder "Spotify.exe"
			$IconPath      = Join-Path $SpotifyFolder "iconapp.ico"
			$IconUrl       = "https://spotixplus.fr/assets/icons/iconapp.ico"
			$Desktop       = [Environment]::GetFolderPath("Desktop")
			$PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
			$ShortcutPath  = Join-Path $Desktop "SpotiX+.lnk"
			$StartMenu         = [Environment]::GetFolderPath("Programs")
			$StartMenuFolder   = Join-Path $StartMenu "SpotiX+ Reborn"
			$StartMenuShortcut = Join-Path $StartMenuFolder "SpotiX+.lnk"
			$DocumentsFolder  = [Environment]::GetFolderPath("MyDocuments")
			$SpotiXDocuments  = Join-Path $DocumentsFolder "SpotiX+ Reborn"
			$DocumentsShortcut = Join-Path $SpotiXDocuments "SpotiX+.lnk"

			# Créer le dossier Documents\SpotiX+ Reborn s’il n’existe pas
			if (-not (Test-Path -LiteralPath $SpotiXDocuments)) {
    			New-Item `
        		-ItemType Directory `
        		-Path $SpotiXDocuments `
       		 -Force | Out-Null
			}

			try {
   				Invoke-WebRequest `
      			-Uri $IconUrl `
      			-OutFile $IconPath `
       			-UseBasicParsing `
        		-ErrorAction Stop

    		 @(
        		(Join-Path $Desktop "Spotify.lnk"),
        		(Join-Path $PublicDesktop "Spotify.lnk"),
        		(Join-Path $StartMenu "Spotify.lnk"),
        		(Join-Path $StartMenu "SpotiX+.lnk"),
        		$ShortcutPath,
        		$StartMenuShortcut

    		) | ForEach-Object {
       			 Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue
    		}

    		New-Item `
        		-ItemType Directory `
        		-Path $StartMenuFolder `
        		-Force | Out-Null
    		
			$WshShell = New-Object -ComObject WScript.Shell

			$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

			$Shortcut = $WshShell.CreateShortcut($StartMenuShortcut)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

			# Raccourci dans Documents\SpotiX+ Reborn
			$Shortcut = $WshShell.CreateShortcut($DocumentsShortcut)
			$Shortcut.TargetPath       = $SpotifyExe
			$Shortcut.WorkingDirectory = $SpotifyFolder
			$Shortcut.IconLocation     = "$IconPath,0"
			$Shortcut.Description      = "SpotiX+ Reborn by Voltan, made with <3"
			$Shortcut.Save()

    		[void][Runtime.InteropServices.Marshal]::ReleaseComObject($Shortcut)
    		[void][Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell)

    		Start-Process `
        		-FilePath "$env:WINDIR\System32\ie4uinit.exe" `
        		-ArgumentList "-show" `
        		-WindowStyle Hidden `
       		 	-ErrorAction SilentlyContinue
		}
			catch {
   		 	Write-Host "Erreur pendant la création du raccourci Spotify :" -ForegroundColor Red
    		Write-Host $_.Exception.Message -ForegroundColor DarkRed
	}
			$null = InstallSpotiXCompanion

			Write-Host (GetTranslation "create-shortcut-done")
			EnterToContinue -DefaultPrompt $true
		}
	}
}

function Main {
	# Changement nom fenêtre
	SetTitle (GetTranslation "lobby")

	# Affichage du logo
	PrintLogo

	# Accueil du script
	Write-Host (GetTranslation "lobby-third-party-apps")
	Write-Host ""
	Write-Host (GetTranslation "lobby-warning") -ForegroundColor Yellow
	Write-Host ""

	Write-Host ((
		(GetTranslation "lobby-menu"),
		"1. 💾 $(GetTranslation 'lobby-menu1')",
		"2. 🎶 $(GetTranslation 'lobby-menu2')",
		"3. ⤵️ $(GetTranslation 'lobby-menu3')",
		"4. 🛒 $(GetTranslation 'lobby-menu4')",
		"5. 💻​ $(GetTranslation 'lobby-menu5')",
		"6. 🎮 $(GetTranslation 'lobby-menu6')",
		"7. 🗑️ $(GetTranslation 'lobby-menu7')",
		"8. 🌐 $(GetTranslation 'lobby-menu8')",
		"9. 📨 $(GetTranslation 'lobby-menu9')",
		"10. 👋 $(GetTranslation 'lobby-menu10')"
	) -join "`n`t")

	$userChoices0 = GetUserChoices -validResponses @("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "50", "99")

	# Exécute les commandes en fonction des réponses
	switch ($userChoices0.Trim()) {
		"1" {
			Msstore
			Main
		}
		"2" {
			HighQuality
			Main
		}
		"3" {
			SpotiFLAC
			Main
		}
		"4" {
			SpicetifyH
			Main
		}
		"5" {
			CreateShortcutOnDesktop
			Main
		}
		"6" {
			InstallDiscordRichPresence
			Main
		}
		"7" {
			Uninstall
			Main
		}
		"8" {
			Write-Host (GetTranslation "lobby-menu8-openning-github")
			Start-Process "https://github.com/$GithubUser/$GithubRepo"
			Main
		}
		"9" {
			Write-Host (GetTranslation "lobby-menu9-openning-discord")
			Start-Process $Discord
			Main
		}
		"10" {
			Write-Host (GetTranslation "lobby-menu10-goodbye")
			Start-Sleep -Seconds 1
			Stop-Transcript
			exit
		}
		"11" {
			InstallDev
			Main
		}
		"50" {
			SetTitle "SpotiX+ Companion"
			PrintLogo

			$CompanionInstalled = InstallSpotiXCompanion

			if (-not $CompanionInstalled) {
				Write-Host ""
				Write-Host (GetTranslation "companion-error") -ForegroundColor Red
			}

			EnterToContinue -DefaultPrompt $true
			Main
		}
		"99" {
			CheckUpdate
			main
		}
	}
}

function CheckUpdate {
	if (-not $PSCommandPath) {
		Write-Host (GetTranslation "online-mode-skip-update")
		return
	}
	$response = Invoke-WebRequest "https://api.github.com/repos/$GithubUser/$GithubRepo/releases/latest" | ConvertFrom-Json
	$latestVersion = $response.tag_name
	if ($latestVersion -eq "v$Version") { return }

	PrintLogo
	Write-Host (GetTranslation "update-found")
	Write-Host "v$Version -> $latestVersion"
	$confirmation = Read-Host -Prompt (GetTranslation "update-prompt")
	if ($confirmation -eq "N") { return }

	Invoke-WebRequest "https://github.com/AgoyaSpotix/spotixplus-reborn-windows/releases/download/$latestVersion/script.ps1" -OutFile $PSCommandPath
	Write-Host (GetTranslation "update-downloaded")
	EnterToContinue
	Start-Process "$PSHOME\pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -FromLauncher"
	exit
}

CheckUpdate
Main
