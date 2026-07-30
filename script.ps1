# Constantes
$AppNameShort = "SpotiX+"
$AppName = "$AppNameShort PC Script"
$Version = "2.1.8b"
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
     /                    v$Version                    /
    ----------------------------------------------
"

# Paramètres PowerShell
$ErrorActionPreference = "Continue"

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
	$powershellRetailPath  = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
	$powershellPreviewPath = "$env:ProgramFiles\PowerShell\7-preview\pwsh.exe"

	if (Test-Path $powershellRetailPath) {
		return $powershellRetailPath
	}
	if (Test-Path $powershellPreviewPath) {
		return $powershellPreviewPath
	}
	return $null
}

if (($args -notcontains "-FromLauncher") -and ($PSVersionTable.PSVersion.Major -lt 7)) {
	$powershellPath = GetPowershellPath

	if (-not $powershellPath) {
		SetTitle "Error"
		Clear-Host
		Write-Host "PowerShell 7 is not installed on this system. It is required to use $AppNameShort.`nWould you like to install it ?" -ForegroundColor Red
		$confirmation = Read-Host -Prompt "(Y/N) "

		if ($confirmation -eq "Y") {
			# Installation de PowerShell 7
			$response = Invoke-WebRequest "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -UseBasicParsing | ConvertFrom-Json
			$powershellLatestVersion = $response.tag_name.Substring(1)

			SetTitle "PowerShell $powershellLatestVersion"
			Clear-Host
			Write-Host "Download starting for PowerShell $powershellLatestVersion..." -ForegroundColor Green
			Write-Host "Note : You might need to accept an UAC prompt." -ForegroundColor Yellow
			$url = "https://github.com/PowerShell/PowerShell/releases/download/v$powershellLatestVersion/PowerShell-$powershellLatestVersion-win-x64.msi"
			$fichierLocal = "$env:TEMP\PowerShell-$powershellLatestVersion-win-x64.msi"

			$webClient = New-Object System.Net.WebClient
			$webClient.DownloadFile($url, $fichierLocal)

			if (Test-Path $fichierLocal) {
				Write-Host "Download finished, installing..." -ForegroundColor Green
				Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$fichierLocal`" /quiet" -Verb RunAs -Wait
				$powershellPath = GetPowershellPath
				if (-not $powershellPath) {
					Write-Host "An error occured during the installation." -ForegroundColor Red
					EnterToContinue -DefaultPrompt $true
					Stop-Transcript
					exit
				}
			} else {
				Write-Host "An error occured during the downloading." -ForegroundColor Red
				EnterToContinue -DefaultPrompt $true
				Stop-Transcript
				exit
			}
		} else {
			Clear-Host
			Write-Host "You can close this window by pressing Enter." -ForegroundColor Yellow -NoNewLine
			EnterToContinue -DefaultPrompt $true
			Stop-Transcript
			exit
		}
	}

	Write-Host "Loading SpotiX+..." -ForegroundColor Yellow
	$scriptPath = $MyInvocation.MyCommand.Path
	if ($scriptPath -like "*$env:LocalAppData\Temp*") {
		if (-Not (Test-Path $log_dir)) {
			New-Item -Path $log_dir -ItemType Directory -Force
		}
		$newScriptPath = Join-Path $log_dir (Split-Path -Leaf $scriptPath)
		Write-Host "Moving the script at this path : $newScriptPath" -ForegroundColor Yellow
		Write-Host "Launching the script..." -ForegroundColor Yellow
		Copy-Item -Path $scriptPath -Destination $newScriptPath -Force
		$scriptPath = $newScriptPath
	}

	Start-Process $powershellPath -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" -FromLauncher"
	exit
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
		}
	}
}
"@ | ConvertFrom-Json -AsHashtable
$language_id = (Get-Culture).Name
$language_id_defaulted = $localizations["languages_default_regions"][$language_id.Substring(0, 2)]

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

function InstallDev {
	#dev
	#Delof le farfadet malicieux
	Write-Host "Bravo, vous avez trouvé le mode dev !!!"
	Write-Host "Malheuresement, il n'y a rien à voir ici"
	Write-Host "Et puis, même si y'avait un truc ici, vous ne devriez pas être là"
	Write-Host "Donc DÉGAGEZ !!!"
	Write-Host "Ou restez, jsp, je m'en fous en fait"
	Write-Host "Si vous souhaitez partir, appuyez sur la touche Entrée"
	EnterToContinue
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
			Start-Process -FilePath "$env:AppData\Spotify\Spotify.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
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
				"1. $(GetTranslation "app-install-version-choice-version1")",
				"2. $(GetTranslation "app-install-version-choice-version2")",
				"3. $(GetTranslation "app-install-version-choice-version3")"
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
				"1. $(GetTranslation "spicetify-plugins-plugin-1")",
				"2. $(GetTranslation "spicetify-plugins-plugin-2")",
				"3. $(GetTranslation "spicetify-plugins-plugin-3")"
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
		Write-Host (GetTranslation "uninstall-starting")

		# Suppression des dossiers/fichiers
		Write-Host (GetTranslation "spotify-uninstall")
		Start-Process -FilePath "$env:AppData\Spotify\Spotify.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
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
		
		Write-Host (GetTranslation "spotx-uninstall")
		RemoveIfExists "$env:AppData\Spotify"
		RemoveIfExists "$env:LocalAppData\Spotify"
		RemoveIfExists "$env:UserProfile\Desktop\$AppNameShort.lnk"
		RemoveIfExists "$env:AppData\Microsoft\Windows\Start Menu\Programs\SpotiX+ Reborn\$AppNameShort.lnk"

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
		"1. $(GetTranslation "audio-high")",
		"2. $(GetTranslation "audio-low")",
		"3. $(GetTranslation "audio-no-changes")"
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
		"1. $(GetTranslation "spotiflac-ok")",
		"2. $(GetTranslation "return")"
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
		"1. $(GetTranslation "spicetify-install")",
		"2. $(GetTranslation "spicetify-uninstall")",
		"3. $(GetTranslation "return")"
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
		"1. $(GetTranslation "create-shortcut")",
		"2. $(GetTranslation "return")"
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
		"1. 💾 $(GetTranslation "lobby-menu1")",
		"2. 🎶 $(GetTranslation "lobby-menu2")",
		"3. ⤵️ $(GetTranslation "lobby-menu3")",
		"4. 🛒 $(GetTranslation "lobby-menu4")",
		"5. 💻​ $(GetTranslation "lobby-menu5")",
		"6. 🗑️ $(GetTranslation "lobby-menu6")",
		"7. 🌐 $(GetTranslation "lobby-menu7")",
		"8. 📨 $(GetTranslation "lobby-menu8")",
		"9. 👋 $(GetTranslation "lobby-menu9")"
	) -join "`n`t")

	$userChoices0 = GetUserChoices -validResponses @("1", "2", "3", "4", "5", "6", "7", "8", "9")

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
			Uninstall
			Main
		}
		"7" {
			Write-Host (GetTranslation "lobby-menu7-openning-github")
			Start-Process "https://github.com/$GithubUser/$GithubRepo"
			Main
		}
		"8" {
			Write-Host (GetTranslation "lobby-menu8-openning-discord")
			Start-Process $Discord
			Main
		}
		"9" {
			Write-Host (GetTranslation "lobby-menu9-goodbye")
			Start-Sleep -Seconds 1
			Stop-Transcript
			exit
		}
		"10" {
			InstallDev
			Main
		}
		"11" {
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