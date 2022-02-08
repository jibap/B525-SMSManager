# B525-SMSManager
Fonctionne sur Huawei B525s-65a (fonctionne peut-être sur d'autres modèles si API similaires).

**Pour Windows : Notification dès qu'un SMS arrive et UI gestionnaire de SMS (suppression, envoi...)** \
**Pour Linux** : le fichier manage_sms.sh est utilisable en terminal (help inclus)

## Projet
J'ai cherché en vain une petite appli facile à mettre en oeuvre qui permettrait sous Windows d'être notifié dès qu'un SMS arrive sur la box 4G... \
Je l'ai donc crée avec AutoHotKey et Bash en partant du travail de **oga83** du forum https://routeur4g.fr/ . 

## Pré-requis
### Pour avoir BASH sous Windows 
* Installer la fonctionnalité "Sous-sytème Windows pour Linux" via la commande (Win+R) : optionalfeatures
* Installer une distri Linux via le Microsoft Store ( [Ubuntu](https://www.microsoft.com/store/productId/9NBLGGH4MSV6) ou [Debian](https://www.microsoft.com/store/productId/9MSVKQC78PK6) )
* Vérifier que les paquets suivants sont bien installés : curl et wget (ce n'est pas le cas sur Debian)

```
sudo apt update
sudo apt install curl
sudo apt install wget
```
### AutoHotkey
Il est possible d'éxécuter mon appli **sans AutoHotKey** en utilisant la version compilée (.exe), sinon vous pouvez installer le logiciel : https://www.autohotkey.com/download/ahk-install.exe

### Configuration
Il est nécessaire de renseigner le fichier config.ini, tout au moins l'entrée **ROUTER_PASSWORD**, les autres entrées étant optionnelles ou générées par défaut.

## Mise en oeuvre
L'application fonctionne comme un logiciel portable, une fois les fichiers récupérés, il faut donc les placer à un endroit de votre arborescence où il pourront rester sans déranger (pas dans le dossier des téléchargements quoi !!!) 

Si vous n'avez pas le logiciel AHK installé, il suffit de télécharger et exécuter le B525-SMSmanager.exe qui fera une extraction des fichiers annexes (bash, icones, config) \
Si vous utilisez déjà AHK (ou que vous préférez ne pas utiliser un .exe provenant d'internet...), télécharger tous les fichiers sauf le .exe, et éxécuter le B525-SMSManager.ahk pour le lancer. 

> Pour que l'application se lance au démarrage de l'ordi, pensez à la rajouter en tâche planifiée. 

**Une fois que le config.ini est accessible, il reste 4 entrées de configuration :**

**ROUTER_USERNAME** : username de connexion au retour (**admin** par défaut)\
**DELAY** : période de vérification de nouveaux SMS (**5 minutes** par défaut)\
**ROUTER_IP** : adresse IP du routeur (**192.168.8.1** par défaut)\
**DEFAULTSMS** : permet de spécifier un numéro de téléphone à utiliser par défaut dans l'interface d'envoi de SMS (option mise en oeuvre puisque dans mon cas, je communique par SMS via ma box 4G, toujours vers le même numéro)

Une fois le logiciel en cours d'exécution, une icône s'affiche au niveau de la zone de notification de Windows (à côté de l'horloge). 

## Usage
* **Un survol de l'icone** affiche un infobulle récapitulatif (nb de messages non lus, reçus et envoyés)
* **Un double clic** sur l'icone affiche l'interface de gestion des SMS : une liste de tous les SMS présents sur la box
* **Un clic-droit** sur l'icone affiche un menu contextuel permettant de quitter l'appli, actualiser le statut, ou encore afficher l'interface d'envoi de SMS

### Comportement
* L'icone de la marque Huawei est blanche si aucun nouveau message. <img src="noSMS.ico" width="20px"/>
* L'icone passe au rouge quand une interrogation de la box est en cours. <img src="load.ico" width="20px"/>
* L'icone change pour une bulle de citation avec "..." pour indiquer qu'un nouveau message est présent. <img src="more.ico" width="20px"/>

A chaque actualisation (5 minutes par défaut), le logiciel vérifie si de nouveaux SMS sont arrivés, si c'est le cas, une notification Windows apparaîtra avec le contenu des nouveaux messages (très utile pour les code de double authentification e-commerce !)
