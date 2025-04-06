# SpotiX+ Reborn Windows

![logo_horizontal](https://raw.githubusercontent.com/AgoyaSpotix/spotixplus-reborn-windows/refs/heads/main/logo/logo_horizontal.png)

## Qu'est-ce que SpotiX+ Reborn ?
Il s'agit d'une version modifiée de Spotify, vous permettant de ne plus avoir de pub, passer les titres à l'infini, et bien plus encore !

Originalement créé par Voltan, SpotiX+ n'est malheureusement plus en développement.\
Nous avons donc décidé de prendre le relais, ainsi fut né SpotiX+ Reborn.

## Téléchargements et installation
Rendez-vous sur la section [Releases](https://github.com/DelofJ/spotixplus-windows/releases) pour pouvoir télécharger la dernière version du programme.\
Téléchargez et lancez le fichier `script.ps1`.\
Il vous faudra PowerShell 7 pour lancer ce script.\
Si il n'est pas présent sur votre machine, vous pourrez le lancer avec PowerShell 5 (installé de base sur Windows) et le script vous installera automatiquement PowerShell 7.

## Bugs connus
Si vous un des messages suivants qui apparaissent :
```
The file <chemin>\script.ps1 cannot be loaded because running scripts is disabled on this system
```
```
The file <chemin>\script.ps1 is not digitally signed.
```
Ouvrez PowerShell, entrez la commande suivante :
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```
Vous devriez maintenant être capable de lancer le script !

## J'ai d'autres bugs !
Regardez si quelqu'un n'a pas déjà reporté le bug dans l'onglet [Issues](https://github.com/AgoyaSpotix/spotixplus-reborn/issues).\
Si c'est le cas, envoyez une réponse en disant que cela vous arrive aussi.\
Sinon, signalez-le de vous même.

## [Rejoignez le Discord](https://discord.gg/p3AAf7TUPv)
