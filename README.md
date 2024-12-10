# B525-SMSManager
Fonctionne sur Huawei B525s-65a (fonctionne peut-être sur d'autres modèles si API similaires).

**Pour Windows : Notification dès qu'un SMS arrive et UI gestionnaire de SMS (suppression, envoi...) + Interrupteur WIFI direct** \
**Pour Linux** : voir [Bash Version branch](https://github.com/jibap/B525-SMSManager/tree/Bash-version)

## Projet
J'ai cherché en vain une petite appli facile à mettre en oeuvre qui permettrait sous Windows d'être notifié dès qu'un SMS arrive sur la box 4G... \
Je l'ai donc crée avec AutoHotKey et Bash en partant du travail de **oga83** du forum https://routeur4g.fr/, puis comme le bash ne peut s'éxécuter sur Windows de façon silencieuse, j'ai finalement réécrit le script en Powershell, qui cette fois ne s'accapare pas le focus.

## Pré-requis
### AutoHotkey
Il est possible d'éxécuter mon appli **sans AutoHotKey** en utilisant la version compilée (.exe), sinon vous pouvez installer le logiciel : https://www.autohotkey.com/download/ahk-install.exe (NB: script écrit en V1 donc ne fonctionne pas en V2)

### Configuration
Il est nécessaire de renseigner le fichier config.ini, tout au moins l'entrée **ROUTER_PASSWORD**, les autres entrées étant optionnelles ou générées par défaut.

## Mise en oeuvre
L'application fonctionne comme un logiciel portable, une fois les fichiers récupérés, il faut donc les placer à un endroit de votre arborescence où il pourront rester sans déranger (pas dans le dossier des téléchargements quoi !!!) 

Si vous n'avez pas le logiciel AHK installé, il suffit de télécharger et exécuter le B525-SMSmanager.exe qui fera une extraction des fichiers annexes (script powershell, icones, config) \
Si vous utilisez déjà AHK (ou que vous préférez ne pas utiliser un .exe provenant d'internet...), téléchargez tous les fichiers sauf le .exe, placez les 4 fichiers .ico dans un dossier "medias" au même niveau que le .ahk et éxécuter le B525-SMSManager.ahk pour le lancer. 

> Pour que l'application se lance au démarrage de l'ordi, pensez à la rajouter en tâche planifiée. 

**Une fois que le config.ini est accessible, il y a 3 paramètres de configuration :**

**ROUTER_USERNAME** : username de connexion au retour (**admin** par défaut)\
**DELAY** : période de vérification de nouveaux SMS (**5 minutes** par défaut)\
**ROUTER_IP** : adresse IP du routeur (**192.168.8.1** par défaut)\

Une section "[contacts]" est proposée en dessous, cela permets de convertir automatiquement à l'affichage des numéros de téléphone en un label de contact, la syntaxe est simple :

**06XXXXXXXX**=NOM PRENOM ou autre info

<img src="https://routeur4g.fr/discussions/uploads/5NXK814BXFXM/image.png"/>

Ce "répertoire" sera également proposé dans l'interface d'envoi de SMS et le premier numéro de la liste sera préselectionné par défaut (pratique dans mon cas car je communique par SMS via ma box 4G, toujours vers le même numéro)


Une fois le logiciel en cours d'exécution, une icône s'affiche au niveau de la zone de notification de Windows (à côté de l'horloge). 

## Usage
* **Un survol de l'icone** affiche un infobulle récapitulatif (nb de messages non lus, reçus et envoyés)\
<img src="https://routeur4g.fr/discussions/uploads/editor/pl/cvhervm1yshb.png"/> <img src="https://routeur4g.fr/discussions/uploads/editor/hx/grt69n654unr.png" width="200px"/>

* **Un clic-droit** sur l'icone affiche un menu contextuel permettant de quitter l'appli, actualiser le statut, ou encore afficher l'interface d'envoi de SMS\
<img src="https://routeur4g.fr/discussions/uploads/editor/fl/9vyzxgu0kjx6.png"/>

* **Une nouvelle fonctionnalité (02/2024)** permets désormais d'activer ou désactiver le wifi, directement depuis le menu de la zone de notification ou sur un bouton dans l'interface du gestionnaire.
  
* * **Une nouvelle fonctionnalité (05/2024)** permets désormais d'ouvrir directement le fichier "config.ini"depuis le menu de la zone de notification ou sur un bouton dans l'interface du gestionnaire.
![menu barre des taches](https://github.com/jibap/B525-SMSManager/assets/3915029/da5b7ce3-4195-4044-b4ff-62b113e1df41)

* **Un double clic** sur l'icone affiche l'interface de gestion des SMS : une liste de tous les SMS présents sur la box\
![interface](https://github.com/jibap/B525-SMSManager/assets/3915029/61011e5d-140b-4fa4-808e-799fc1770b12)



### Comportement
* L'icone de la marque Huawei est blanche si aucun nouveau message. <img src="noSMS.ico" width="20px"/>
* L'icone passe au rouge quand une interrogation de la box est en cours. <img src="load.ico" width="20px" />
* L'icone change pour une bulle de citation avec "..." pour indiquer qu'un nouveau message est présent. <img src="more.ico" width="20px"/>

A chaque actualisation (5 minutes par défaut), le logiciel vérifie si de nouveaux SMS sont arrivés, si c'est le cas, une notification Windows apparaîtra pour chaque nouveau message (très utile pour les code de double authentification e-commerce !)

<img src="https://routeur4g.fr/discussions/uploads/editor/dz/vqvcgxw4wgac.png" />
