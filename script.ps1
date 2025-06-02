# Constantes
$AppNameShort = "SpotiX+ Reborn"
$AppName = "$AppNameShort PC Script"
$Version = "1.5"
$ByPassAdmin = $false
$NoTranslations = $false

$GithubUser = "AgoyaSpotix"
$GithubRepo = "spotixplus-reborn"
$Discord = "https://discord.gg/p3AAf7TUPv"

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

       ----------------------------------------------
      /     Merci d'avoir téléchargé le script      /
     /                Made with <3                 /
    /                Version $Version                  /
   -----------------------------------------------
"

# Paramètres PowerShell
$ErrorActionPreference = "Continue"

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
			"en-US": "Lobby"
		},
		"lobby-third-party-apps": {
			"fr-FR": "Apps tierces utilisées: SpotX CLI, Spicetify, Soggfy",
			"en-US": "Third party apps used : SpotX CLI, Spicetify, Soggfy"
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
			"fr-FR": "Activer la fonctionnalité de téléchargement",
			"en-US": "Enable the download feature"
		},
		"lobby-menu4": {
			"fr-FR": "Désinstaller $AppNameShort",
			"en-US": "Uninstall $AppNameShort"
		},
		"lobby-menu5": {
			"fr-FR": "Ouvrir la page GitHub",
			"en-US": "Open GitHub Webpage"
		},
		"lobby-menu6": {
			"fr-FR": "Rejoindre notre serveur Discord",
			"en-US": "Join our Discord server"
		},
		"lobby-menu7": {
			"fr-FR": "Fermer le script",
			"en-US": "Close the script"
		},
		"lobby-menu5-openning-github": {
			"fr-FR": "Ouverture de la page GitHub...",
			"en-US": "Openning the GitHub Webpage..."
		},
		"lobby-menu6-openning-discord": {
			"fr-FR": "Ouverture du lien d'invitation Discord...",
			"en-US": "Openning the Discord join link..."
		},
		"lobby-menu7-goodbye": {
			"fr-FR": "A bientôt !",
			"en-US": "See you soon !"
		},
		"msstore-check-found": {
			"fr-FR": "Une version de Spotify venant du Microsoft Store (UWP) a été détectée. (Version : `$ms_version)"
		},
		"msstore-check-warning": {
			"fr-FR": "Cette version peut être utilisée en paralèle de $AppNameShort, mais cela crééra deux versions de Spotify sur votre système."
		},
		"msstore-check-prompt": {
			"fr-FR": "Voulez-vous la désinstaller ? (Vous devez être administrateur !) (Y/N)"
		},
		"msstore-check-uninstalling": {
			"fr-FR": "Désinstalltion de Spotify UWP `$ms_version..."
		},
		"msstore-check-uninstall-failed": {
			"fr-FR": "La désinstalltion à échoué."
		},
		"retry": {
			"fr-FR": "Réessayer ? (Y/N)"
		},
		"script-will-continue": {
			"fr-FR": "Le script va continuer..."
		},
		"msstore-check-uninstalled-successfully": {
			"fr-FR": "Spotify UWP a été désinstallé avec succès !"
		},
		"spotify-check-found": {
			"fr-FR": "Une installation de Spotify incompatible a été détectée. Pour le bon fonctionnement du script, vous devez la désinstaller.`nNous pouvons le faire pour vous."
		},
		"spotify-check-prompt": {
			"fr-FR": "Voulez-vous désinstaller Spotify ? (Y/N)"
		},
		"spotify-check-uninstalling": {
			"fr-FR": "Lancement de la désinstallation de Spotify..."
		},
		"spotify-check-uninstalling-failed": {
			"fr-FR": "La désinstallation de Spotify a échoué. Appuyez sur Entrée pour recommencer..."
		},
		"spotify-check-uninstall-successful": {
			"fr-FR": "Spotify a correctement été désinstallé !"
		},
		"spotify-check-uninstall-successful-continue": {
			"fr-FR": "Le script va continuer..."
		},
		"spotify-check-returning": {
			"fr-FR": "Impossible d'installer $AppNameShort. Retour au menu principal dans 3 secondes..."
		},
		"app-install-version-choice-prompt": {
			"fr-FR": "Quelle version de Spotify souhaitez-vous ?"
		},
		"app-install-version-choice-version1": {
			"fr-FR": "Nouvelle interface - Dernière version    - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement instable"
		},
		"app-install-version-choice-version2": {
			"fr-FR": "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement compatible"
		},
		"app-install-version-choice-version3": {
			"fr-FR": "Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Plugin externe instable   - Mode téléchargement instable"
		},
		"app-install-version-choice-more-info": {
			"fr-FR": "Pour en savoir plus sur les différences entre les versions, consultez la page tutoriel PC du site $AppNameShort (1/2/3)"
		},
		"installation": {
			"fr-FR": "Installation",
			"en-US": "Installation"
		},
		"downloading-and-installing": {
			"fr-FR": "Téléchargement et installation de Spotify..."
		},
		"spotify-install-prompt": {
			"fr-FR": "Une fois Spotify installé, veuillez presser la touche Entrée..."
		},
		"spotx-cli-download": {
			"fr-FR": "Téléchargement/Installation de SpotX CLI..."
		},
		"spotx-configuration": {
			"fr-FR": "SpotX Configuration"
		},
		"spotx-installed": {
			"fr-FR": "Script 1/2 installés : SpotiX installé"
		},
		"spotify-closing": {
			"fr-FR": "Fermeture de Spotify pour faciliter l'exécution des scripts"
		},
		"creating-necessary-folder": {
			"fr-FR": "Création des dossiers nécessaires"
		},
		"spicetify-configuration": {
			"fr-FR": "Configuration de Spicetify",
			"en-US": "Spicetify Configuration"
		},
		"spicetify-installed": {
			"fr-FR": "Script 2/2 installés : Spicetify"
		},
		"app-configuration": {
			"fr-FR": "Configuration de $AppNameShort"
		},
		"download-app-files": {
			"fr-FR": "Une erreur s'est produite durant le téléchargement des fichiers nécessaires`nNe retentez pas de lancer le script, cela pourrait générer des conflits`nMerci de contacter le support de $AppNameShort"
		},
		"spicetify-plugins": {
			"fr-FR": "Plugins Spicetify",
			"en-US": "Spicetify plugins"
		},
		"spicetify-plugins-prompt": {
			"fr-FR": "Spicetify propose 3 plugins externes pouvant améliorer l'expérience utilisateur"
		},
		"spicetify-plugins-prompt-2": {
			"fr-FR": "Souhaitez vous installer des plugins externes ?"
		},
		"spicetify-plugins-plugin-1": {
			"fr-FR": "Reddit: récupérez des messages de n'importe quel subreddit de partage de liens Spotify"
		},
		"spicetify-plugins-plugin-2": {
			"fr-FR": "Lyrics-plus: accédez aux paroles du titre actuel grâce à divers fournisseurs,`n                tels que Musixmatch, Netease et Genius"
		},
		"spicetify-plugins-plugin-3": {
			"fr-FR": "New-releases: regroupez toutes les nouvelles sorties de vos artistes et podcasts préférés"
		},
		"spicetify-plugins-prompt-3": {
			"fr-FR": "Vous pouvez choisir plusieurs plugins externes en mettant une virgule entre chaque nombre (ex : 2,3)`nAppuyez sur Entrer en laissant vide pour ne rien installer"
		},
		"spicetify-plugin-reddit-installing": {
			"fr-FR": "Installation du plugin externe \"Reddit\"..."
		},
		"spicetify-plugin-reddit-installing-success": {
			"fr-FR": "Plugin externe \"Reddit\" installé avec succès !"
		},
		"spicetify-plugin-lyricsplus-installing": {
			"fr-FR": "Installation du plugin externe \"Lyrics-plus\"..."
		},
		"spicetify-plugin-lyricsplus-installing-success": {
			"fr-FR": "Plugin externe \"Lyrics-plus\" installé avec succès !"
		},
		"spicetify-plugin-newreleases-installing": {
			"fr-FR": "Installation du plugin externe \"New-releases\"..."
		},
		"spicetify-plugin-newreleases-installing-success": {
			"fr-FR": "Plugin externe \"New-releases\" installé avec succès !"
		},
		"install-finished": {
			"fr-FR": "Installation terminée"
		},
		"configuration-finished": {
			"fr-FR": "Fin de la configuration de $AppNameShort..."
		},
		"install-successful": {
			"fr-FR": "$AppNameShort installé avec succès !"
		},
		"uninstall-app-not-found": {
			"fr-FR": "Vous ne pouvez pas déinstaller $AppNameShort car celui-ci n'est pas installé."
		},
		"uninstall-app-confirmation": {
			"fr-FR": "Êtes vous sûr de vouloir désinstaller $AppNameShort et tout ses composants ? (Y/N)"
		},
		"uninstalling": {
			"fr-FR": "Désinstallation"
		},
		"uninstall-starting": {
			"fr-FR": "Lancement de la désinstallation de $AppNameShort..."
		},
		"spotify-uninstall": {
			"fr-FR": "Désinstallation de Spotify..."
		},
		"spotify-uninstall-fail": {
			"fr-FR": "La désinstallation de Spotify a échouée ou a été annulée. Appuyez sur Entrée pour retourner au menu principal..."
		},
		"spicetify-uninstalling": {
			"fr-FR": "Suppresion de Spicetify..."
		},
		"spotify-uninstall-complete": {
			"fr-FR": "Suppresion des résidus de Spotify..."
		},
		"spotx-uninstall": {
			"fr-FR": "Suppresion de SpotX..."
		},
		"soggfy-uninstall": {
			"fr-FR": "Suppression de Soggfy..."
		},
		"app-uninstalled-successfully": {
			"fr-FR": "$AppNameShort désinstallé avec succès !"
		},
		"cancelling": {
			"fr-FR": "Annulation..."
		},
		"audio-configuration": {
			"fr-FR": "Configuration Audio",
			"en-US": "Audio Configuration"
		},
		"app-installed-check": {
			"fr-FR": "$AppNameShort n'est pas installé sur votre PC, merci de l'installer d'abord."
		},
		"audio-warning": {
			"fr-FR": "ATTENTION: ne démarrez pas $AppNameShort pendant ce processus, cela pourrait engendrer des conflits"
		},
		"audio-prompt": {
			"fr-FR": "Quelle qualité audio souhaitez-vous ?"
		},
		"audio-high": {
			"fr-FR": "Qualité très élevée"
		},
		"audio-low": {
			"fr-FR": "Qualité basique (réglable depuis $AppNameShort)"
		},
		"audio-high-configuration": {
			"fr-FR": "Configuration de la qualité très élevée"
		},
		"audio-error": {
			"fr-FR": "Une erreur s'est produite durant le téléchargement des fichiers nécessaires.`nNe retentez pas de lancer le script, cela pourrait faire des conflits`nMerci de contacter le support de $AppNameShort"
		},
		"closing-window": {
			"fr-FR": "Fermeture de la fenêtre..."
		},
		"audio-high-done": {
			"fr-FR": "La qualité très élevée est appliquée !"
		},
		"audio-low-configuration": {
			"fr-FR": "Suppresion de la qualité très élévée"
		},
		"audio-low-done": {
			"fr-FR": "La qualité très élevée a été supprimée avec succès !"
		},
		"soggfy": {
			"fr-FR": "Fonctionnalité de téléchargement"
		},
		"soggfy-already-installed": {
			"fr-FR": "Le mode téléchargement est déjà activé pour $AppNameShort"
		},
		"soggfy-compatible-versions": {
			"fr-FR": "Voici les versions compatible avec la fonctionnalitée de téléchargement:"
		},
		"soggfy-compatible-versions-v1": {
			"fr-FR": "Nouvelle interface - Dernière version    - Compatible avec Windows 11/10     - Mode téléchargement instable"
		},
		"soggfy-compatible-versions-v2": {
			"fr-FR": "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10     - Mode téléchargement compatible"
		},
		"soggfy-compatible-versions-v3": {
			"fr-FR": "Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Mode téléchargement instable"
		},
		"soggfy-warning": {
			"fr-FR": "Le fonctionnement du mode téléchargement n'est pas garanti sur les versions \"instables\".`nIl est tout de même possible que cela fonctionne, n'hésitez pas à tester !"
		},
		"soggfy-speech": {
			"fr-FR": "La fonctionnalité de téléchargement permet de télécharger vos musiques préférées juste en les écoutant !`nIl suffit d'écouter la musique que vous souhaitez télécharger en entier, et celle-ci sera automatiquement enregistrée.`nVos musiques téléchargées seront disponible dans votre dossier Musique, puis Soggfy.`nPour en savoir plus, veuillez consulter le tutoriel ici : https://github.com/AgoyaSpotix/spotixplus-reborn/blob/main/tutos/tuto-telechargement.md"
		},
		"soggfy-confirm": {
			"fr-FR": "Souhaitez-vous activer la fonctionnalité de téléchargement ? (Y/N)"
		},
		"installing-necessary-files": {
			"fr-FR": "Installation des fichiers nécessaire"
		},
		"installing-ffmpeg": {
			"fr-FR": "Installation de FFMPEG"
		},
		"soggfy-success": {
			"fr-FR": "La fonctionnalité de téléchargement est installée avec succès !"
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
	if ($localizations["translations"][$string_id].ContainsKey($language_id_defaulted)) {
		return $localizations["translations"][$string_id][$language_id_defaulted]
	}
	# Defaults to en-US
	if ($localizations["translations"][$string_id].ContainsKey("en-US")) {
		return $localizations["translations"][$string_id]["en-US"]
	}
	# No translations found for this string ID
	return $string_id
}

function EnterToContinue {
	param (
		[bool] $DefaultPrompt = $false
	)
	if ($DefaultPrompt) {
		Write-Host (GetTranslation "enter-to-continue") -NoNewLine
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
		Write-Progress -Activity (GetTranslation "downloading") -Status "$([math]::Round($percentComplete, 2))% $(GetTranslation "percentage-done")" -PercentComplete $percentComplete
	}

	$responseStream.Close()
	$fileStream.Close()
}

# Titre fenêtre
SetTitle (GetTranslation "loading")

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
		SetTitle (GetTranslation "error")
		Clear-Host
		Write-Host (GetTranslation "powershell-7-not-installed") -ForegroundColor Red
		$confirmation = Read-Host -Prompt ""

		if ($confirmation -eq "Y") {
			# Installation de PowerShell 7
			$response = Invoke-WebRequest "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" | ConvertFrom-Json
			$powershellLatestVersion = $response.tag_name.Substring(1)

			SetTitle "PowerShell $powershellLatestVersion"
			Clear-Host
			Write-Host (GetTranslation "powershell-7-download-starting").Replace("`$powershellLatestVersion", $powershellLatestVersion) -ForegroundColor Green
			$url = "https://github.com/PowerShell/PowerShell/releases/download/v$powershellLatestVersion/PowerShell-$powershellLatestVersion-win-x64.msi"
			$fichierLocal = "$env:TEMP\PowerShell-$powershellLatestVersion-win-x64.msi"

			$webClient = New-Object System.Net.WebClient
			$webClient.DownloadFile($url, $fichierLocal)

			if (Test-Path $fichierLocal) {
				Write-Host (GetTranslation "powershell-7-download-finished") -ForegroundColor Green
				Start-Process $fichierLocal
				Write-Host (GetTranslation "powershell-7-installation-prompt") -ForegroundColor Green
				EnterToContinue
				$powershellPath = GetPowershellPath
				if (-not $powershellPath) {
					Write-Host (GetTranslation "powershell-7-error-installing") -ForegroundColor Red
					EnterToContinue -DefaultPrompt $true
					Stop-Transcript
					exit
				}
			} else {
				Write-Host (GetTranslation "powershell-7-error-downloading") -ForegroundColor Red
				EnterToContinue -DefaultPrompt $true
				Stop-Transcript
				exit
			}
		} else {
			Clear-Host
			Write-Host (GetTranslation "close-window-prompt") -ForegroundColor Yellow -NoNewLine
			EnterToContinue -DefaultPrompt $true
			Stop-Transcript
			exit
		}
	}

	Write-Host "$(GetTranslation "loading")..." -ForegroundColor Yellow
	$scriptPath = $MyInvocation.MyCommand.Path
	if ($scriptPath -match "$env:LocalAppData\Temp") {
		if (-Not (Test-Path $log_dir)) {
			New-Item -Path $log_dir -ItemType Directory -Force
		}
		$newScriptPath = Join-Path $log_dir (Split-Path -Leaf $scriptPath)
		Write-Host (GetTranslation "script-move").Replace("`$newScriptPath", $newScriptPath) -ForegroundColor Yellow
		Write-Host (GetTranslation "script-launch") -ForegroundColor Yellow
		Copy-Item -Path $scriptPath -Destination $newScriptPath -Force
		$scriptPath = $newScriptPath
	}

	Start-Process $powershellPath -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" -FromLauncher"
	exit
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
				Write-Host (GetTranslation "spotify-check-uninstall-successful-continue")
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
					$url = "https://spotixplus.com/files/windows/script/spotify-verdownload.exe"
					$spotifyInstaller = "$env:TEMP\spotify-verdownload.exe"
				}
				"3" {
					# URL et fichier pour l'ancienne interface
					$url = "https://download.scdn.co/SpotifyFull7-8-8.1.exe"
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

			#Mode téléchargement
			Soggfy

			# Renommer le raccourci Spotify du bureau
			#$oldFile = "$env:UserProfile\Desktop\Spotify.lnk"
			#$newFile = "$env:UserProfile\Desktop\$AppNameShort.lnk"
			#Rename-Item -Path $oldFile -NewName $newFile
			Rename-Item -Path "$env:UserProfile\Desktop\Spotify.lnk" -NewName "$AppNameShort.lnk"


			# Renommer le raccourci Spotify du menu démarrer
			#$oldFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
			#$newFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"
			#Rename-Item -Path $oldFile -NewName $newFile
			Rename-Item -Path "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk" -NewName "$AppNameShort.lnk"


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
		RemoveIfExists "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"

		Write-Host (GetTranslation "soggfy-uninstall")
		RemoveIfExists "$env:LocalAppData/Soggfy"

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

function Soggfy {
	#Mode téléchargement
	Clear-Host
	SetTitle (GetTranslation "soggfy")
	PrintLogo
	if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "app-installed-check")
		EnterToContinue -DefaultPrompt $true
		return
	}
	if (Test-Path -Path "$env:AppData\Spotify\SoggfyUIC.js") {
		SetTitle (GetTranslation "error")
		Write-Host (GetTranslation "soggfy-already-installed")
		EnterToContinue -DefaultPrompt $true
		return
	}
	Write-Host (GetTranslation "soggfy-compatible-versions")
	Write-Host (GetTranslation "soggfy-compatible-versions-v1")
	Write-Host (GetTranslation "soggfy-compatible-versions-v2")
	Write-Host (GetTranslation "soggfy-compatible-versions-v3")
	Write-Host ""
	Write-Host (GetTranslation "soggfy-warning")
	EnterToContinue -DefaultPrompt $true
	Write-Host ""
	Write-Host (GetTranslation "soggfy-speech")
	Write-Host ""
	$confirmation0 = Read-Host -Prompt (GetTranslation "soggfy-confirm")
	if ($confirmation0 -eq "Y") {
		StopSpotify
		Write-Host (GetTranslation "installing-necessary-files")
		Download -URL "https://spotixplus.com/files/windows/script/dpapi.dll" -Path "$env:AppData\Spotify\dpapi.dll" -Clear $false
		#2
		Download -URL "https://spotixplus.com/files/windows/script/SoggfyUIC.js" -Path "$env:AppData\Spotify\SoggfyUIC.js" -Clear $false

		#FFMPEG
		Write-Host (GetTranslation "installing-ffmpeg")
		$soggfy1 = "$env:LocalAppData/Soggfy/"
		if (-not (Test-Path -Path $soggfy1)) {
			New-Item -Path $soggfy1 -ItemType Directory
		}
		$soggfy2 = "$env:LocalAppData/Soggfy/ffmpeg/"
		if (-not (Test-Path -Path $soggfy2)) {
			New-Item -Path $soggfy2 -ItemType Directory
		}
		Download -URL "https://spotixplus.com/files/windows/script/ffmpeg.exe" -Path "$env:LocalAppData/Soggfy/ffmpeg/ffmpeg.exe" -Clear $false

		Write-Host (GetTranslation "soggfy-success")
		Write-Host (GetTranslation "script-will-continue")
		Start-Sleep -Seconds 3
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
		"4. 🗑️ $(GetTranslation "lobby-menu4")",
		"5. 🌐 $(GetTranslation "lobby-menu5")",
		"6. 📨 $(GetTranslation "lobby-menu6")",
		"7. 👋 $(GetTranslation "lobby-menu7")"
	) -join "`n`t")

	$userChoices0 = GetUserChoices -validResponses @("1", "2", "3", "4", "5", "6", "7", "8")

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
			Soggfy
			Main
		}
		"4" {
			Uninstall
			Main
		}
		"5" {
			Write-Host (GetTranslation "lobby-menu5-openning-github")
			Start-Process "https://github.com/$GithubUser/$GithubRepo"
			Main
		}
		"6" {
			Write-Host (GetTranslation "lobby-menu6-openning-discord")
			Start-Process $Discord
			Main
		}
		"7" {
			Write-Host (GetTranslation "lobby-menu7-goodbye")
			Start-Sleep -Seconds 1
			Stop-Transcript
			exit
		}
		"8" {
			InstallDev
			Main
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
