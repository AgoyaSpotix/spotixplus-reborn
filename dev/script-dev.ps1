﻿# Constantes
$AppNameShort = "SpotiX+ Reborn"
$AppName = "$AppNameShort PC Script"
$Version = "1.5"
$base = $PSScriptRoot
$temp = "$base\temp"
$ByPassAdmin = $false

$GithubUser = "AgoyaSpotix"
$GithubRepo = "spotixplus-reborn-windows"
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
     / 		      Made with <3                 /
    /                Version $Version                  /
   -----------------------------------------------
"

# Paramètres PowerShell
$ErrorActionPreference = "Continue"

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
}
"@ -Language CSharp
Start-Sleep -Milliseconds 500
$hWnd = [WinAPI]::GetForegroundWindow()
$X = 500      # Position X (à partir du coin gauche de l'écran)
$Y = 300      # Position Y (à partir du haut de l'écran)
$Width = 1500 # Largeur de la fenêtre
$Height = 800 # Hauteur de la fenêtre

[WinAPI]::MoveWindow($hWnd, $X, $Y, $Width, $Height, $true)


function EnterToContinue {
	param (
		[bool] $DefaultPrompt = $false
	)
	if ($DefaultPrompt) {
		Write-Host "Appuyez sur Entrée pour continuer..." -NoNewLine
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

# Titre fenêtre
SetTitle "Chargement"

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
		SetTitle "Erreur"
		Clear-Host
		Write-Host "PowerShell 7 n'est pas installé sur ce système." -ForegroundColor Red
		$confirmation = Read-Host -Prompt "Souhaitez-vous installer PowerShell 7 ? (Y/N)"

		if ($confirmation -eq "Y") {
			# Installation de PowerShell 7
			$response = Invoke-WebRequest "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" | ConvertFrom-Json
			$powershellLatestVersion = $response.tag_name.Substring(1)

			SetTitle "PowerShell $powershellLatestVersion"
			Clear-Host
			Write-Host "Lancement du téléchargement de PowerShell $powershellLatestVersion..." -ForegroundColor Green
			$url = "https://github.com/PowerShell/PowerShell/releases/download/v$powershellLatestVersion/PowerShell-$powershellLatestVersion-win-x64.msi"
			$fichierLocal = "$env:TEMP\PowerShell-$powershellLatestVersion-win-x64.msi"

			$webClient = New-Object System.Net.WebClient
			$webClient.DownloadFile($url, $fichierLocal)

			if (Test-Path $fichierLocal) {
				Write-Host "Téléchargement terminé. Lancement de l'installation..." -ForegroundColor Green
				Start-Process $fichierLocal
				Write-Host "Une fois l'installation terminée, appuyez sur Entrée..." -ForegroundColor Green
				EnterToContinue
				$powershellPath = GetPowershellPath
				if (-not $powershellPath) {
					Write-Host "Une erreur est survenue lors de l'installation." -ForegroundColor Red
					EnterToContinue -DefaultPrompt $true
					Stop-Transcript
					exit
				}
			} else {
				Write-Host "Une erreur est survenue lors du téléchargement." -ForegroundColor Red
				EnterToContinue -DefaultPrompt $true
				Stop-Transcript
				exit
			}
		} else {
			Clear-Host
			Write-Host "Vous pouvez fermer cette fenêtre en appuyant sur Entrée." -ForegroundColor Yellow -NoNewLine
			EnterToContinue -DefaultPrompt $true
			Stop-Transcript
			exit
		}
	}

	Write-Host "Chargement.." -ForegroundColor Yellow
	$scriptPath = $MyInvocation.MyCommand.Path
	if ($scriptPath -match "AppData\\Local\\Temp") {
		if (-Not (Test-Path $log_dir)) {
			New-Item -Path $log_dir -ItemType Directory -Force
		}
		$newScriptPath = Join-Path $log_dir (Split-Path -Leaf $scriptPath)
		Write-Host "Déplacement du script a cette adresse : $newScriptPath" -ForegroundColor Yellow
		Write-Host "Lancement du script.." -ForegroundColor Yellow
		Copy-Item -Path $scriptPath -Destination $newScriptPath -Force
		$scriptPath = $newScriptPath
	}

	Start-Process $powershellPath -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" -FromLauncher"
	exit
}

# Verification admin ou pas
if ((-not $ByPassAdmin) -and ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Host "Pour pouvoir faire fonctionner correctement le script, celui-ci ne dois pas être lancé en administrateur." -ForegroundColor Red
	Write-Host "Veuillez redémarrer le script normalement." -ForegroundColor Red
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
		[string[]]$validResponses
	)

	$responses = $null
	do {
		Write-Host " > " -NoNewLine
		$input = $Host.UI.ReadLine().Replace(" ", "")
		$responses = $input.Split(",") -ne ''
	} while ($responses -eq $null)

	return $responses
}

function Main {
	# Changement nom fenêtre
	SetTitle "Accueil"

	# Affichage du logo
	PrintLogo

	# Accueil du script
	Write-Host "Apps tierces utilisées: SpotX CLI, Spicetify, Soggfy"
	Write-Host ""
	Write-Host "PREVENTION: ce script utilise votre connexion internet pour fonctionner correctement." -ForegroundColor Yellow
	Write-Host "Ne désactivez pas votre connexion internet pendant l'exécution du script." -ForegroundColor Yellow
	Write-Host ""

	Write-Host ((
		"Que voulez-vous faire ?",
		"1. Installer $AppNameShort",
		"2. Activer/Désactiver la qualité très élevée",
		"3. Activer la fonctionnalité de téléchargement",
		"4. Désinstaller $AppNameShort",
		"5. Ouvrir la page GitHub",
		"6. Rejoindre notre serveur Discord",
		"7. Fermer le script"
	) -join "`n`t")

	$userChoices0 = GetUserChoices -validResponses @("1", "2", "3", "4", "5", "6", "7", "8")

	# Exécute les commandes en fonction des réponses
	foreach ($choice in $userChoices0) {
		switch ($choice.Trim()) {
			"1" {
				# Installation
				PrintLogo
				$confirmation1 = Read-Host -Prompt "Avez-vous Spotify actuellement installé sur votre ordinateur ? (Y/N)"
				if ($confirmation1 -eq "N") {
					Write-Host ((
						"Quelle version de Spotify souhaitez-vous ?",
						"1. Nouvelle interface - Version publique    - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement non compatible",
						"2. Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement compatible",
						"3. Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Plugin externe instable   - Mode téléchargement instable"
					) -join "`n`t")
					Write-Host "Pour en savoir plus sur les différences entre les versions, consultez la page tutoriel PC du site $AppNameShort (1/2/3)"
					$confirmation2 = GetUserChoices -validResponses @("1", "2", "3")
						foreach ($choice in $confirmation2) {
						switch ($choice.Trim()) {
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
					}
					
					# Installation de Spotify
					SetTitle "Installation"
					PrintLogo

					Write-Host "Téléchargement et installation de Spotify.."

					$webClient = New-Object System.Net.WebClient
					$webClient.DownloadFile($url, $spotifyInstaller)

					Start-Process $spotifyInstaller
					Write-Host "Une fois Spotify installé, veuillez presser la touche Entrée..."
					EnterToContinue

					# SpotX
					Write-Host "Téléchargement/Installation de SpotX CLI.."
					SetTitle "SpotX Configuration"
					Clear-Host
					[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/main/run.ps1').Content) }"
					Write-Host "Script 1/2 installés : SpotiX installé"

					# Fermeture de Spotify
					Write-Host "Fermeture de Spotify pour faciliter l'exécution des scripts"
					StopSpotify

					# Dossier Spicetify
					Write-Host "Création des dossiers nécessaires"
					if (-not (Test-Path -Path "$env:AppData\spicetify\")) {
						New-Item -Path "$env:AppData\spicetify\" -ItemType Directory
					}

					# Spicetify
					SetTitle "Spicetify Configuration"
					Clear-Host
					[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1').Content) }"
					Write-Host "Script 2/2 installés : Spicetify"
					StopSpotify

					# Modification interface
					Write-Host "Configuration de $AppNameShort"
					$url0 = "https://spotixplus.fr/files/windows/script/frdesactived.mo"
					$fichierLocal0 = "$env:AppData\Spotify\locales\frdesactived.mo"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url0)
					$fileStream = [System.IO.File]::Create($fichierLocal0)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()

					if (Test-Path $fichierLocal0) {
						$asupp = "$env:AppData\Spotify\locales\fr.mo"
						Remove-Item -Path $asupp
						$oldFile1 = "$env:AppData\Spotify\locales\frdesactived.mo"
						$newFile1 = "$env:AppData\Spotify\locales\fr.mo"
						Rename-Item -Path $oldFile1 -NewName $newFile1
					} else {
						SetTitle "Erreur"
						Write-Host "Une erreur s'est produite durant le téléchargement des fichiers nécessaires." -ForegroundColor Red
						Write-Host "Ne retentez pas de lancer le script, cela pourrait générer des conflits" -ForegroundColor Red
						Write-Host "Merci de contacter le support de $AppNameShort" -ForegroundColor Red
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
					Write-Host "Configuration de $AppNameShort"
					$pathconfig = "$env:AppData\Spotify\"
					New-Item -Path $pathconfig -Name "config.need" -ItemType "File" -Force

					# Plugins
					SetTitle "Spicetify plugins"
					PrintLogo

					Write-Host "Spicetify propose 3 plugins externes pouvant améliorer l'expérience utilisateur"
					Write-Host ((
						"Souhaitez vous installer des plugins externes ?",
						"1. Reddit: récupérez des messages de n'importe quel subreddit de partage de liens Spotify",
						"2. Lyrics-plus: accédez aux paroles du titre actuel grâce à divers fournisseurs,",
						"                tels que Musixmatch, Netease et Genius",
						"3. New-releases: regroupez toutes les nouvelles sorties de vos artistes et podcasts préférés"
					) -join "`n`t")
					Write-Host "Vous pouvez choisir plusieurs plugins externes en mettant une virgule entre chaque nombre (ex : 2,3)"
					Write-Host "Appuyez sur Entrer en laissant vide pour ne rien installer"
					$userChoices = GetUserChoices -validResponses @("1", "2", "3")

					# Installation des plugins en fonction des réponses
					foreach ($choice in $userChoices) {
						switch ($choice.Trim()) {
							"1" {
								Write-Output 'Installation du plugin externe "Reddit"..'
								spicetify config custom_apps reddit
								spicetify apply
								Write-Output 'Plugin externe "Reddit" installé avec succès !'
								StopSpotify
							}
							"2" {
								Write-Output 'Installation du plugin externe "Lyrics-plus"..'
								spicetify config custom_apps lyrics-plus
								spicetify apply
								Write-Output 'Plugin externe "Lyrics-plus" installé avec succès !'
								StopSpotify
							}
							"3" {
								Write-Output 'Installation du plugin externe "New-releases"..'
								spicetify config custom_apps new-releases
								spicetify apply
								Write-Output 'Plugin externe "New-releases" installé avec succès !'
								StopSpotify
							}
						}
					}
					StopSpotify
					cls
					#Mode téléchargement
					SetTitle "Fonctionnalitée de téléchargement"
					PrintLogo
					Write-Host "Voici les versions compatible avec la fonctionnalitée de téléchargement:"
					Write-Host "Nouvelle interface - Dernière version publique - Compatible avec Windows 11/10 - Mode téléchargement instable"
					Write-Host "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10 - Mode téléchargement compatible"
					Write-Host "Ancienne interface - Version 1.2.5.1006 - Compatible avec Windows 11/10/8.1 - Mode téléchargement instable"
					Write-Host ""
					Write-Host "Le fonctionnement du mode téléchargement n'est pas garanti sur les versions "instables"."
					EnterToContinue -DefaultPrompt $true
					Write-Host ""
					Write-Host "La fonctionnalité de téléchargement permet de télécharger vos musiques préférés juste en les écoutant !"
					Write-Host "Il suffit d'écouter la musique que vous souhaitez télécharger en entier, et celle-ci sera automatiquement enregistrée."
					Write-Host "Vos musiques téléchargées seront disponible dans votre dossier Musique dans votre Explorateur de fichiers, puis Soggfy."
					Write-Host "Pour en savoir plus, veuillez consulter le tutoriel ici : https://github.com/AgoyaSpotix/spotixplus-reborn/blob/main/dev/tuto-telechargement.md"
					Write-Host ""
					$confirmation0 = Read-Host -Prompt "Souhaitez-vous activer la fonctionnalité de téléchargement ? (Y/N)"
					if ($confirmation0 -eq "Y") {
					Write-Host "Installation des fichiers nécessaires"
					$url0 = "https://spotixplus.com/files/windows/script/dpapi.dll"
					$fichierLocal0 = "$env:AppData\Spotify\dpapi.dll"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url0)
					$fileStream = [System.IO.File]::Create($fichierLocal0)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()
					#2
					$url5 = "https://spotixplus.com/files/windows/script/SoggfyUIC.js"
					$fichierLocal5 = "$env:APPDATA\Spotify\SoggfyUIC.js"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url5)
					$fileStream = [System.IO.File]::Create($fichierLocal5)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()
					#FFMPEG
					Write-Host "Installation de FFMPEG"
					$soggfy1 = "$env:localappdata/Soggfy/"
					if (-not (Test-Path -Path $soggfy1)) {
						New-Item -Path $soggfy1 -ItemType Directory
					}
					$soggfy2 = "$env:localappdata/Soggfy/ffmpeg/"
					if (-not (Test-Path -Path $soggfy2)) {
						New-Item -Path $soggfy2 -ItemType Directory
					}
					$url4 = "https://spotixplus.com/files/windows/script/ffmpeg.exe"
					$fichierLocal4 = "$env:localappdata/Soggfy/ffmpeg/ffmpeg.exe"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url4)

					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					#Renommer les raccoursis
										# Renommer le raccourci Spotify du bureau
										$oldFile = "$env:UserProfile\Desktop\Spotify.lnk"
										$newFile = "$env:UserProfile\Desktop\$AppNameShort.lnk"
										Rename-Item -Path $oldFile -NewName $newFile
					
										# Renommer le raccourci Spotify du menu démarrer
										$oldFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
										$newFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"
										Rename-Item -Path $oldFile -NewName $newFile

					SetTitle "Installation terminée"
					PrintLogo
					Write-Host "Fin de la configuration de $AppNameShort.."
					StopSpotify
					Write-Host "$AppNameShort installé avec succès !"
					EnterToContinue -DefaultPrompt $true
					Main
					#fin 1
					} else {
					#fin 2
					SetTitle "Installation terminée"
					PrintLogo
					Write-Host "Fin de la configuration de $AppNameShort.."
					StopSpotify
					Write-Host "$AppNameShort installé avec succès !"
					EnterToContinue -DefaultPrompt $true
					Main
					 }
				} else {
					# Erreur Spotify déjà installé, désinstallation de Spotify
					
					Write-Host "Avant d'installer $AppNameShort, vous devez d'abord désinatller Spotify."
					$confirmation1 = Read-Host -Prompt "Voulez-vous désinstaller Spotify ? (Y/N)"
					if ($confirmation1 -eq "Y") {
						# Lancement de la désinstallation
						Write-Host "Lancement de la désinstallation de Spotify..."
						Write-Host "Après avoir appyué sur OK, pressez Entrée..."
						Start-Process -FilePath "$env:UserProfile\AppData\Roaming\Spotify\Spotify.exe" -ArgumentList "/uninstall" -NoNewWindow -Wait
						if (Test-Path "$env:UserProfile\AppData\Roaming\Spotify\Spotify.exe") {
							Write-Host "La désinstallation de Spotify a échoué. Veuillez recommencer." -ForegroundColor Red
							Read-Host "Appuyez sur Entrée pour continuer..."							
						} else {
							Write-Host "Spotify a correctement été désinstallé ! " -ForegroundColor Green
							Read-Host "Vous n'avez plus qu'à relancer l'installation de $AppNameShort. Veuillez presser Entrée..."
						}
						
					}

					else {
						Write-Host "Retour au menu principal dans 3 secondes..."
						Start-Sleep -Seconds 3
					}

					Main
				} else {
					#---------sortie du mode dev
					Main
				}

			}
			"2" {
				# Qualité audio
				SetTitle "Configuration Audio"
				PrintLogo

				if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
					SetTitle "Erreur"
					Write-Host "$AppNameShort n'est pas installé sur votre PC, merci de l'installer d'abord."
					EnterToContinue -DefaultPrompt $true
					Main
				}

				# Fichier trouvé
				Write-Host "ATTENTION: ne démarrez pas $AppNameShort pendant ce processus, cela pourrait engendrer des conflits" -ForegroundColor Red
				Write-Host ((
					"Quelle qualité audio souhaitez-vous ?",
					"1. Qualité très élevée",
					"2. Qualité basique (réglable depuis $AppNameShort)",
					"3. Retour au menu principale"
				) -join "`n`t")
				$userChoices = GetUserChoices -validResponses @("1", "2", "3")
				PrintLogo
				SetTitle "Configuration Audio"

				foreach ($choice in $userChoices) {
						switch ($choice.Trim()) {
							"1" {
								StopSpotify
								Write-Host "Configuration de la qualité très élevée"
								$audioveryhigh = (
								"audio.sync_bitrate=320000",
								"audio.play_bitrate=320000"
								)

								$prefs = "$env:userprofile\AppData\Roaming\Spotify\prefs"
								$tmp = "$env:userprofile\AppData\Roaming\Spotify\prefs.tmp"
								Add-Content -Path $prefs -Value $audioveryhigh
								Set-ItemProperty -Path $prefs -Name IsReadOnly -Value $true
       							Write-Host "."
								Add-Content -Path $tmp -Value $audioveryhigh
								Set-ItemProperty -Path $tmp -Name IsReadOnly -Value $true
      						    Write-Host ".."
								$url0 = "https://spotixplus.fr/files/windows/script/fractived.mo"
								$fichierLocal0 = "$env:userprofile\AppData\Roaming\Spotify\locales\fractived.mo"
								$webClient = New-Object System.Net.WebClient
								$bufferSize = 8192  # 8KB
								$startTime = Get-Date
								$totalBytesReceived = 0

								$responseStream = $webClient.OpenRead($url0)
								$fileStream = [System.IO.File]::Create($fichierLocal0)
								$buffer = New-Object byte[] $bufferSize
								$totalBytes = $webClient.ResponseHeaders["Content-Length"]
								$bytesReceived = 0

								while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
    							$fileStream.Write($buffer, 0, $readBytes)
    							$totalBytesReceived += $readBytes
   							    $timeElapsed = (Get-Date) - $startTime
   								$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
    							$percentComplete = ($totalBytesReceived / $totalBytes) * 100
								cls
    							Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
								}

								$responseStream.Close()
								$fileStream.Close()

								if (Test-Path $fichierLocal0) {
   									Write-Host "..."
									$asupp = "$env:userprofile\AppData\Roaming\Spotify\locales\fr.mo"
									Remove-Item -Path $asupp
									$oldFile1 = "$env:userprofile\AppData\Roaming\Spotify\locales\fractived.mo"
    								$newFile1 = "$env:userprofile\AppData\Roaming\Spotify\locales\fr.mo"
   									 Rename-Item -Path $oldFile1 -NewName $newFile1
								} else {
    								SetTitle "Erreur"
   									Write-Host "Une erreur s'est produite durant le téléchargement des fichiers nécessaires." -ForegroundColor Red
   									Write-Host "Ne retentez pas de lancer le script, cela pourrait générer des conflits" -ForegroundColor Red
   									Write-Host "Merci de contacter le support de SpotiX+ Reborn" -ForegroundColor Red
									pause
   									Write-Host "Fermeture de la fenêtre.."
    								Stop-Transcript
    								exit
								}	
								Write-Host "La qualité très élevée est appliquée !"
       							EnterToContinue -DefaultPrompt $true
								Main
							}
							"2" {
								StopSpotify
								Write-Host "Suppresion de la qualité très élévée"
								$audioveryhigh = (
								"audio.sync_bitrate=320000",
								"audio.play_bitrate=320000"
								)

           						$prefs = "$env:userprofile\AppData\Roaming\Spotify\prefs"
           						$tmp = "$env:userprofile\AppData\Roaming\Spotify\prefs.tmp"
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


								$url0 = "https://spotixplus.fr/files/windows/script/frdesactived.mo"
								$fichierLocal0 = "$env:userprofile\AppData\Roaming\Spotify\locales\frdesactived.mo"
								$webClient = New-Object System.Net.WebClient
								$bufferSize = 8192  # 8KB
								$startTime = Get-Date
								$totalBytesReceived = 0

								$responseStream = $webClient.OpenRead($url0)
								$fileStream = [System.IO.File]::Create($fichierLocal0)
								$buffer = New-Object byte[] $bufferSize
								$totalBytes = $webClient.ResponseHeaders["Content-Length"]
								$bytesReceived = 0

								while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
   								$fileStream.Write($buffer, 0, $readBytes)
    							$totalBytesReceived += $readBytes
    							$timeElapsed = (Get-Date) - $startTime
    							$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
    							$percentComplete = ($totalBytesReceived / $totalBytes) * 100
								cls
    							Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
								}

								$responseStream.Close()
								$fileStream.Close()

								if (Test-Path $fichierLocal0) {
    								Write-Host "..."
									$asupp = "$env:userprofile\AppData\Roaming\Spotify\locales\fr.mo"
									Remove-Item -Path $asupp
									$oldFile1 = "$env:userprofile\AppData\Roaming\Spotify\locales\frdesactived.mo"
   									$newFile1 = "$env:userprofile\AppData\Roaming\Spotify\locales\fr.mo"
    								Rename-Item -Path $oldFile1 -NewName $newFile1
								} else {
    								SetTitle "Erreur"
    								Write-Host "Une erreur s'est produite durant le téléchargement des fichiers nécessaires." -ForegroundColor Red
    								Write-Host "Ne retentez pas de lancer le script, cela pourrait faire des conflits" -ForegroundColor Red
    								Write-Host "Merci de contacter le support de SpotiX+" -ForegroundColor Red
									pause
									Write-Host "Fermeture de la fenêtre.."
    								Stop-Transcript
    								exit
								}	
								Write-Host "La qualité très élevée a été supprimée avec succès !"
       							EnterToContinue -DefaultPrompt $true
								Main
							}
							"3" {
								Main
							}
						}
					}
			} 
			"3" {	
					cls
					#Mode téléchargement
					SetTitle "Fonctionnalité de téléchargement"
					PrintLogo
					if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
					SetTitle "Erreur"
					Write-Host "$AppNameShort n'est pas installé sur votre PC, merci de l'installer d'abord."
					EnterToContinue -DefaultPrompt $true
					Main
					}
					if (Test-Path -Path "$env:APPDATA\Spotify\SoggfyUIC.js") {
					SetTitle "Erreur"
					Write-Host "Le mode téléchargement est déjà activé pour $AppNameShort"
					EnterToContinue -DefaultPrompt $true
					Main
				   }
					Write-Host "Voici les versions compatible avec la fonctionnalitée de téléchargement:"
					Write-Host "Nouvelle interface - Dernière version publique - Compatible avec Windows 11/10 - Mode téléchargement instable"
					Write-Host "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10 - Mode téléchargement compatible"
					Write-Host "Ancienne interface - Version 1.2.5.1006 - Compatible avec Windows 11/10/8.1 - Mode téléchargement instable"
					Write-Host ""
					Write-Host "Le fonctionnement du mode téléchargement n'est pas garanti sur les versions "instables"."
					EnterToContinue -DefaultPrompt $true
					Write-Host ""
					Write-Host "La fonctionnalité de téléchargement permet de télécharger vos musiques préférées juste en les écoutant !"
					Write-Host "Il suffit d'écouter la musique que vous souhaitez télécharger en entier, et celle-ci sera enregistrée."
					Write-Host "Vos musiques téléchargés sont disponible dans votre dossier Musique dans votre Explorateur de fichiers, puis Soggfy."
					Write-Host "Pour en savoir plus, veuillez regarder le tutoriel sur le site de $AppNameShort."
					Write-Host ""
					$confirmation0 = Read-Host -Prompt "Souhaitez-vous activer la fonctionnalité de téléchargement ? (Y/N)"
					if ($confirmation0 -eq "Y") {
					StopSpotify
					Write-Host "Installation des fichiers nécessaire"
					$url0 = "https://spotixplus.com/files/windows/script/dpapi.dll"
					$fichierLocal0 = "$env:AppData\Spotify\dpapi.dll"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url0)
					$fileStream = [System.IO.File]::Create($fichierLocal0)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()
					#2
					$url5 = "https://spotixplus.com/files/windows/script/SoggfyUIC.js"
					$fichierLocal5 = "$env:APPDATA\Spotify\SoggfyUIC.js"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url5)
					$fileStream = [System.IO.File]::Create($fichierLocal5)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()
					#FFMPEG
					Write-Host "Installation de FFMPEG"
					$soggfy1 = "$env:localappdata/Soggfy/"
					if (-not (Test-Path -Path $soggfy1)) {
						New-Item -Path $soggfy1 -ItemType Directory
					}
					$soggfy2 = "$env:localappdata/Soggfy/ffmpeg/"
					if (-not (Test-Path -Path $soggfy2)) {
						New-Item -Path $soggfy2 -ItemType Directory
					}
					$url4 = "https://spotixplus.com/files/windows/script/ffmpeg.exe"
					$fichierLocal4 = "$env:localappdata/Soggfy/ffmpeg/ffmpeg.exe"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url4)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					#Renommer les raccoursis
										# Renommer le raccourci Spotify du bureau
										$oldFile = "$env:UserProfile\Desktop\Spotify.lnk"
										$newFile = "$env:UserProfile\Desktop\$AppNameShort.lnk"
										Rename-Item -Path $oldFile -NewName $newFile
					
										# Renommer le raccourci Spotify du menu démarrer
										$oldFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
										$newFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"
										Rename-Item -Path $oldFile -NewName $newFile


					Write-Host "La fonctionnalité téléchargement est installée avec succès !"
					pause
					Main
				
			} else {
				Main
			}
			}
			"4" {
				PrintLogo
				# Désinstallation

				if (-not (Test-Path -Path "$env:AppData\Spotify\config.need")) {
					SetTitle "Erreur"
					Write-Host "Vous ne pouvez pas déinstaller $AppNameShort car celui-ci n'est pas installé."
					EnterToContinue -DefaultPrompt $true
					Main
				}

				$confirmation = Read-Host -Prompt "Êtes vous sûr de vouloir désinstaller $AppNameShort et tout ses composants ? (Y/N)"
				PrintLogo
				if ($confirmation -eq "Y") {
					SetTitle "Désinstallation"
					StopSpotify
					Write-Host "Désinstallation de $AppNameShort.."

					# Suppression des dossiers/fichiers
					Write-Host "Suppresion de Spicetify.."
					RemoveIfExists "$env:AppData\spicetify"

					Write-Host "Suppresion de Spotify.."

					$prefs = "$env:AppData\Spotify\prefs"
					if (Test-Path -Path $prefs) {
						Set-ItemProperty -Path $prefs -Name IsReadOnly -Value $false
					}
					$tmp = "$env:AppData\Spotify\prefs.tmp"
					if (Test-Path -Path $tmp) {
						Set-ItemProperty -Path $tmp -Name IsReadOnly -Value $false
					}

					RemoveIfExists "$env:AppData\Spotify"
					RemoveIfExists "$env:LocalAppData\Spotify"
					RemoveIfExists "$env:UserProfile\Desktop\$AppNameShort.lnk"
					RemoveIfExists "$env:localappdata/Soggfy/ffmpeg/ffmpeg.exe"

					Write-Host "$AppNameShort désinstallé avec succès !"
					EnterToContinue -DefaultPrompt $true
					Main
				} else {
					Write-Host "Annulation.."
					EnterToContinue -DefaultPrompt $true
					Main
				}
			}
			"5" {
				Write-Host "Ouverture de la page GitHub.."
				Start-Process "https://github.com/$GithubUser/$GithubRepo"
				Main
			}
			"6" {
				Write-Host "Ouverture de la page GitHub.."
				Start-Process $Discord
				Main
			}
			"7" {
				Stop-Transcript
				exit
			}
			"8" {
				#dev
				Write-Host "Vous rentrez en mode développeur, vous pouvez quitter ce mode maintenant si vous le souhaitez" -ForegroundColor Yellow
				Write-Host "Celui-ci pourrait endommager les fichiers de Spotify ou même de votre ordinateur" -ForegroundColor Yellow
				$confirmation1 = Read-Host -Prompt "Êtes-vous sûr de vouloir rentrer dans ce mode ? (Y/N)"
				PrintLogo
				#---------entrer en mode dev
				if ($confirmation1 -eq "Y") {
					# Installation
				if (Test-Path -Path "$env:APPDATA\Spotify") {
					SetTitle "Erreur"
					Write-Host "Le mode téléchargement est déjà activer pour $AppNameShort"
					EnterToContinue -DefaultPrompt $true
					Main
				   }	
				$confirmation1 = Read-Host -Prompt "Avez-vous Spotify actuellement installé sur votre ordinateur ? (Y/N)"
				PrintLogo
				if ($confirmation1 -eq "N") {
					Write-Host ((
						"Quelle version de Spotify souhaitez-vous ?",
						"1. Nouvelle interface - Version publique    - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement non compatible",
						"2. Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10     - Plugin externe compatible - Mode téléchargement compatible",
						"3. Ancienne interface - Version 1.2.5.1006  - Compatible avec Windows 11/10/8.1 - Plugin externe instable   - Mode téléchargement instable"
					) -join "`n`t")
					Write-Host "Pour en savoir plus sur les différences entre les versions, consultez la page tutoriel PC du site $AppNameShort (1/2/3)"
					$confirmation2 = GetUserChoices -validResponses @("1", "2", "3")
						foreach ($choice in $confirmation2) {
						switch ($choice.Trim()) {
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
					}
					
					# Installation de Spotify
					SetTitle "Installation"
					PrintLogo

					Write-Host "Téléchargement et installation de Spotify.."

					$webClient = New-Object System.Net.WebClient
					$webClient.DownloadFile($url, $spotifyInstaller)

					Start-Process $spotifyInstaller
					Write-Host "Une fois Spotify installé, vous pouvez appuyer sur la touche Entrée"
					EnterToContinue

					# SpotX
					Write-Host "Téléchargement/Installation de SpotX CLI.."
					SetTitle "SpotX Configuration"
					Clear-Host
					[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/SpotX/main/run.ps1').Content) }"
					Write-Host "Script 1/2 installés : SpotiX installé"

					# Fermeture de Spotify
					Write-Host "Fermeture de Spotify pour faciliter l'exécution des scripts"
					StopSpotify

					# Dossier Spicetify
					Write-Host "Création des dossiers nécessaires"
					if (-not (Test-Path -Path "$env:AppData\spicetify\")) {
						New-Item -Path "$env:AppData\spicetify\" -ItemType Directory
					}

					# Spicetify
					SetTitle "Spicetify Configuration"
					Clear-Host
					[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex "& { $((iwr -useb 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1').Content) }"
					Write-Host "Script 2/2 installés : Spicetify"
					StopSpotify
					
					# Renommer le raccourci Spotify du bureau
					$oldFile = "$env:UserProfile\Desktop\Spotify.lnk"
					$newFile = "$env:UserProfile\Desktop\$AppNameShort.lnk"
					Rename-Item -Path $oldFile -NewName $newFile

					# Renommer le raccourci Spotify du menu démarrer
					$oldFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\Spotify.lnk"
					$newFile = "$env:AppData\Microsoft\Windows\Start Menu\Programs\$AppNameShort.lnk"
					Rename-Item -Path $oldFile -NewName $newFile

					# Modification interface
					Write-Host "Configuration de $AppNameShort"
					$url0 = "https://spotixplus.fr/files/windows/script/frdesactived.mo"
					$fichierLocal0 = "$env:AppData\Spotify\locales\frdesactived.mo"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url0)
					$fileStream = [System.IO.File]::Create($fichierLocal0)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()

					if (Test-Path $fichierLocal0) {
						$asupp = "$env:AppData\Spotify\locales\fr.mo"
						Remove-Item -Path $asupp
						$oldFile1 = "$env:AppData\Spotify\locales\frdesactived.mo"
						$newFile1 = "$env:AppData\Spotify\locales\fr.mo"
						Rename-Item -Path $oldFile1 -NewName $newFile1
					} else {
						SetTitle "Erreur"
						Write-Host "Une erreur s'est produite durant le téléchargement des fichiers nécessaires." -ForegroundColor Red
						Write-Host "Ne retentez pas de lancer le script, cela pourrait générer des conflits" -ForegroundColor Red
						Write-Host "Merci de contacter le support de $AppNameShort" -ForegroundColor Red
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
					Write-Host "Configuration de $AppNameShort"
					$pathconfig = "$env:AppData\Spotify\"
					New-Item -Path $pathconfig -Name "config.need" -ItemType "File" -Force

					# Plugins
					SetTitle "Spicetify plugins"
					PrintLogo

					Write-Host "Spicetify propose 3 plugins externes pouvant améliorer l'expérience utilisateur"
					Write-Host ((
						"Souhaitez vous installer des plugins externes ?",
						"1. Reddit: récupérez des messages de n'importe quel subreddit de partage de liens Spotify",
						"2. Lyrics-plus: accédez aux paroles du titre actuel grâce à divers fournisseurs,",
						"                tels que Musixmatch, Netease et Genius",
						"3. New-releases: regroupez toutes les nouvelles sorties de vos artistes et podcasts préférés"
					) -join "`n`t")
					Write-Host "Vous pouvez choisir plusieurs plugins externes en mettant une virgule entre chaque nombre (ex : 2,3)"
					Write-Host "Appuyez sur Entrer en laissant vide pour ne rien installer"
					$userChoices = GetUserChoices -validResponses @("1", "2", "3")

					# Installation des plugins en fonction des réponses
					foreach ($choice in $userChoices) {
						switch ($choice.Trim()) {
							"1" {
								Write-Output 'Installation du plugin externe "Reddit"..'
								spicetify config custom_apps reddit
								spicetify apply
								Write-Output 'Plugin externe "Reddit" installé avec succès !'
								StopSpotify
							}
							"2" {
								Write-Output 'Installation du plugin externe "Lyrics-plus"..'
								spicetify config custom_apps lyrics-plus
								spicetify apply
								Write-Output 'Plugin externe "Lyrics-plus" installé avec succès !'
								StopSpotify
							}
							"3" {
								Write-Output 'Installation du plugin externe "New-releases"..'
								spicetify config custom_apps new-releases
								spicetify apply
								Write-Output 'Plugin externe "New-releases" installé avec succès !'
								StopSpotify
							}
						}
					}
					StopSpotify
					cls
					#Mode téléchargement
					SetTitle "Fonctionnalitée de téléchargement"
					PrintLogo
					Write-Host "Voici les versions compatible avec la fonctionnalitée de téléchargement:"
					Write-Host "Nouvelle interface - Dernière version publique - Compatible avec Windows 11/10 - Mode téléchargement instable"
					Write-Host "Nouvelle interface - Version 1.2.31.1205 - Compatible avec Windows 11/10 - Mode téléchargement compatible"
					Write-Host "Ancienne interface - Version 1.2.5.1006 - Compatible avec Windows 11/10/8.1 - Mode téléchargement instable"
					Write-Host ""
					Write-Host "Si vous avez une version instable, vous pouvez essayer, ça ce trouve cela va fonctionner !"
					EnterToContinue -DefaultPrompt $true
					Write-Host ""
					Write-Host "La fonctionnalitée de téléchargement permet de télécharger vos musiques préférés juste en les écoutants !"
					Write-Host "Il suffit d'écouter la musique que vous-voulez télécharger en entière, et celle-ci sera télécharger."
					Write-Host "Vos musiques téléchargés sont disponible dans votre dossier Musique dans votre Explorateur de fichiers, puis Soggfy."
					Write-Host "Pour en savoir plus, veuillez regarder le tutoriel sur le site de $AppNameShort."
					Write-Host ""
					$confirmation0 = Read-Host -Prompt "Souhaitez-vous activer la fonctionnalitée de téléchargement ? (Y/N)"
					if ($confirmation0 -eq "Y") {
					Write-Host "Installation des fichiers nécessaire"
					$url0 = "https://spotixplus.com/files/windows/script/dpapi.dll"
					$fichierLocal0 = "$env:AppData\Spotify\dpapi.dll"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url0)
					$fileStream = [System.IO.File]::Create($fichierLocal0)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()
					#2
					$url5 = "https://spotixplus.com/files/windows/script/SoggfyUIC.js"
					$fichierLocal5 = "$env:APPDATA\Spotify\SoggfyUIC.js"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url5)
					$fileStream = [System.IO.File]::Create($fichierLocal5)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}

					$responseStream.Close()
					$fileStream.Close()

					#FFMPEG
					Write-Host "Installation de FFMPEG"
					$soggfy1 = "$env:localappdata/Soggfy/"
					if (-not (Test-Path -Path $soggfy1)) {
						New-Item -Path $soggfy1 -ItemType Directory
					}
					$soggfy2 = "$env:localappdata/Soggfy/ffmpeg/"
					if (-not (Test-Path -Path $soggfy2)) {
						New-Item -Path $soggfy2 -ItemType Directory
					}
					$url4 = "https://spotixplus.com/files/windows/script/ffmpeg.exe"
					$fichierLocal4 = "$env:localappdata/Soggfy/ffmpeg/ffmpeg.exe"
					$webClient = New-Object System.Net.WebClient
					$bufferSize = 8192  # 8KB
					$startTime = Get-Date
					$totalBytesReceived = 0

					$responseStream = $webClient.OpenRead($url4)
					$buffer = New-Object byte[] $bufferSize
					$totalBytes = $webClient.ResponseHeaders["Content-Length"]
					$bytesReceived = 0

					while (($readBytes = $responseStream.Read($buffer, 0, $bufferSize)) -gt 0) {
						$fileStream.Write($buffer, 0, $readBytes)
						$totalBytesReceived += $readBytes
						$timeElapsed = (Get-Date) - $startTime
						$speed = $totalBytesReceived / $timeElapsed.TotalSeconds / 1MB
						$percentComplete = ($totalBytesReceived / $totalBytes) * 100
						Write-Progress -Activity "Téléchargement en cours" -Status "$([math]::Round($percentComplete, 2))% complet" -PercentComplete $percentComplete
					}
					SetTitle "Installation terminée"
					PrintLogo
					Write-Host "Fin de la configuration de $AppNameShort.."
					StopSpotify
					Write-Host "$AppNameShort installé avec succès !"
					EnterToContinue -DefaultPrompt $true
					Main
					#fin 1
					} else {
					#fin 2
					SetTitle "Installation terminée"
					PrintLogo
					Write-Host "Fin de la configuration de $AppNameShort.."
					StopSpotify
					Write-Host "$AppNameShort installé avec succès !"
					EnterToContinue -DefaultPrompt $true
					Main
					 }
				} else {
					# Erreur Spotify déjà installé
					Write-Host "Avant d'installer $AppNameShort, veuillez tout d'abord désinstaller Spotify (ou Spotify Windows Store)"
					EnterToContinue -DefaultPrompt $true
					Main
				} else {
					#---------sortie du mode dev
					Main
				}
			}
		  }
		}
	}
}

function CheckUpdate {
	$response = Invoke-WebRequest "https://api.github.com/repos/$GithubUser/$GithubRepo/releases/latest" | ConvertFrom-Json
	$latestVersion = $response.tag_name
	if ($latestVersion -eq "v$Version") { return }

	PrintLogo
	Write-Host "Une mise à jour du script à été trouvée"
	Write-Host "v$Version -> $latestVersion"
	$confirmation = Read-Host -Prompt "Voulez-vous la télécharger ? (Y/N)"
	if ($confirmation -eq "N") { return }

	Invoke-WebRequest "https://github.com/AgoyaSpotix/spotixplus-reborn-windows/releases/download/$latestVersion/script.ps1" -OutFile $PSCommandPath
	Write-Host "Mise à jour téléchargée"
	Write-Host "Appuyez sur Entrée pour relancer la version mise à jour..."
	EnterToContinue
	Start-Process "$PSHOME\pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -FromLauncher"
	exit
}

CheckUpdate
Main