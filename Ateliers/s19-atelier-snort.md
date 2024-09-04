# Introduction

La détection d’intrusion consiste en un ensemble de techniques et méthodes utilisées pour détecter des activités suspectes au niveau d’un réseau et/ou d’un équipement.
Il existe plusieurs catégories de systèmes de détection d’intrusion :  les systèmes basant leur analyse sur des signatures, ceux qui détectent les anomalies, ceux qui utilise la réputation IP.
Les systèmes qui se basent sur la signature (ports particuliers, mots clés dans les données utiles,...) fonctionnent de la même façon que les antivirus. Ils tentent de  trouver des traces particulières dans  les  paquets  examinés.
Les  systèmes  de  la  seconde  catégorie détectent les  anomalies dans  les entêtes des paquets par rapport aux protocoles standards.
Enfin, ceux qui se basent sur la réputation reconnaissent les menaces en fonction de leur niveau de réputation. Ils collectent et suivent différents attributs de fichier tels que la source, la signature, l'âge et les statistiques d'utilisation des utilisateurs utilisant le fichier. Un moteur de réputation peut également être utilisé.
**Snort**  est  un  système  de  détection  d’intrusion  réseau, (***Network Intrusion Detection System***) open source couramment  utilisé. Il  permet  d’analyser  les  flux  de  données  par  rapport  à  une  base  de données de signature, mais aussi de détecter les anomalies.
Dans cet atelier, tu vas te servir de 2 VM, l'une étant configurée en IDS avec Snort, et l'autre servant de machine **attaquante**.

```spacer-small
```


![image](https://chanjinhao.files.wordpress.com/2018/11/snort.jpg)

```spacer-small
```

# 🎯 Objectifs :

✅ Installer Snort de différentes manière
✅ Configurer Snort avec des règles pré-établie
✅ Mettre en place des règles de surveillance ciblées


# Sommaire
- - -

# ✔️ Étape 1 - Prérequis


Pour pouvoir faire cette quête tu as besoin de 3 VM Ubuntu sous Virtualbox paramétrées comme ceci :

- Une VM **Snort** :
	- Son rôle est d'analyser le flux réseau et de filtrer les attaques
	- Une carte réseau :
		- Avec le mode promiscuité activé sur VirtualBox
		- La configuration IP `10.10.1.10/24`
	- Une seconde carte réseau avec un accès internet
- Une VM **BadGuy** :
	- Son rôle est d'attaquer la machine **GoodGuy**
	- Configuration IP `10.10.1.20/24`
- Une VM **GoodGuy** :
	- Son rôle est de "recevoir" les attaques de la VM **BadGuy**
	- Configuration IP `10.10.1.65/24`
	- Openssh-serveur est installé


```alert-info
Si la configuration matérielle de ton hôte ne te permet pas d'éxecuter en même temps 3 VM, fais cet atelier avec 2 VM :
- Une VM **Snort** :
	- Son rôle est d'analyser les attaques qu'elle reçoit de la VM **BadGuy**
	- Openssh-serveur est installé
- Une VM **BadGuy** :
	- Son rôle est d'attaquer la machine **Snort**
```

# 🔧 Étape 2 - Installation de Snort

Sur la machine **Snort**, on va installer le logiciel Snort.

## Méthode 1 - Avec apt

Sur la machine Snort, exécute la ligne de commande `sudo apt install snort`.
Mets l'adresse réseau `10.10.1.0/24` qui est demandée pendant l'installation.

```alert-warning
En faisant l'installation de Snort par le système **apt**, tu installe une version disponible dans les dépôts Ubuntu, mais ce n'est probablement pas la dernière version à jour.
La commande `apt-cache policy snort` indique que la version `2.9.15.1` est disponible dans les paquets, or sur le site officiel (info [ici](https://www.snort.org/)) la version 3 est disponible.
Avec les autres méthodes ci-dessous, tu peux installer la dernière version.
```

```alert-info
La suite de cet atelier, à partir de l'Étape 3, est basée sur l'installation de snort avec les sources contenues dans les dépots apt.
Si tu utilise une autre méthode d'installation tu devas peut-être faire des modifications.
```

## Méthode 2 - À partir du site officiel de Snort

```resource
https://www.snort.org/
# Installation à partir du site officiel snort.org
Selon ta version, suis le tuto d'installation disponible sur la page d'accueil
```


```hidden
Clic ici|||shel|||Si tu as des messages d'erreurs à l'installation et que tu n'arrive pas à déboguer|||0|||Cacher l'aide
# Installation bibliothèques supplémentaires
apt-get install build-essential
apt-get install flex bison
apt-get install git libpcap-dev
```

```youtube
https://www.youtube.com/watch?v=NcNQZm-q29M
```

## Méthode 3 - En compilant le code source

```resource
https://kifarunix.com/install-and-configure-snort-3-on-ubuntu/
# Installation à partir du code source
Dans cette installation détaillée, tu installe **snort** à partir du code source.
Ne fait que la partie **installation**.
```

Une fois l'installation terminée, vérifie avec la commande `systemctl status snort` que Snort est en cours d’exécution.
Dans le résultat de cette commande, tu vois des lignes avec `Preprocessor Object`. Ce sont les **préprocesseurs**. Ce sont des modules d’extension pour arranger ou modifier les paquets de données avant que le moteur de détection n’intervienne. Certains préprocesseurs détectent aussi des anomalies dans les entêtes des paquets et génèrent alors des alertes.

```resource
https://www.oreilly.com/library/view/snort-cookbook/0596007914/ch04.html
# Les preprocesseurs dans Snort
Tu as ici tout le détails sur ces préprocesseurs.
```

# 🔧 Étape 3 - Modification de l'interface réseau en mode promiscuité

Configuration de la carte réseau en mode promiscuité :

```bash
# Avec enp0s8 la carte réseau du réseau interne
ip link set dev enp0s3 promisc on
```

Vérifier avec `ip a` qu'il y a bien `PROMISC` dans la configuration de la carte.
Désactivation du déchargement d'interface (_Interface Offloading_) pour empêcher Snort de tronquer les gros paquets de plus de 1518 octets :

```bash
# Avec enp0s8 la carte réseau du réseau interne
sudo ethtool -K enp0s3 gro off lro off
```

Vérification (tout doit être à `off`) avec la commande `ethtool -k enp0s8 | grep receive-offload`.

```alert-warning
Ces changements sont temporaires et ne sont valable que pendant cette session. Après un reboot, ils reviendront à leur état d'origine.
Il faut exécuter la commande suivante (en root) :

`cat > /etc/systemd/system/snort3-nic.service << 'EOL'`
Et copier ceci dans le prompt (attention à bien changer le nom de l'interface réseau si ce n'est pas `enp0s3`) :


`[Unit]`
`Description=Set Snort 3 NIC in promiscuous mode and Disable GRO, LRO on boot`
`After=network.target`

`[Service]`
`Type=oneshot`
`ExecStart=/usr/sbin/ip link set dev enp0s3 promisc on`
`ExecStart=/usr/sbin/ethtool -K enp0s3 gro off lro off`
`TimeoutStartSec=0`
`RemainAfterExit=yes`

`[Install]`
`WantedBy=default.target`
`EOL`

```

Rechargement des paramètres de configuration de **systemd** avec `sudo systemctl daemon-reload`.
Démarrage et activation du service au boot avec `sudo systemctl enable --now snort3-nic.service`.

# 🔧 Étape 4 - Gestion de snort suivant le nombre de VM

Toute la configuration de Snort est sous `/etc/snort` et en particulier dans le fichier `/etc/snort/snort.conf`.

Si tu n'utilise que 2 VM :
- Édite le fichier de configuration, et  modifie la variable `HOME_NET` avec l'adresse IP (et le CIDR) de la machine Snort (au lieu de `any`)
- Modifie la variable `EXTERNAL_NET` avec la valeur `'!$HOME_NET'` (au lieu de `any`)
```alert-info
Cette configuration de variables sert à protéger le réseau contre les attaques.
Ici on met une adresse IP pour `HOME_NET`, mais cela peu être un sous-réseau.
`EXTERNAL_NET` ici prend toutes les valeurs autres que celles de `HOME_NET`.
```

Si tu utilise 3 VM, ne change rien.


# 🔧 Étape 5 - Mise en place de règles

Il existe 3 types de règles :

- Les règles de la communauté
- Les règles enregistrées
- Les règles réservées aux abonnés

Les fichiers de configuration des règles sont dans `/etc/snort/rules`.

## Utilisation des règles de la communauté

Télécharge les règles de la communauté avec la commande `wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz`.
Décompresse le fichier et colle le fichier `snort3-community.rules` à la racine du dossier des règles.
Dans le fichier de configuration, dans la partie `Step #7`, ajoute ce fichier à prendre en compte avec la commande `include $RULE_PATH/snort3-community.rules`.

## Utilisation de règles personnalisées

Tu va utiliser le fichier de règles personnalisées `etc/snort/rules/local.rules`.
Dans ce fichier, ajouter des règles de gestion pour l'ICMP et SSH :

```bash
alert icmp any any -> $HOME_NET any (msg:"PERSO - ICMP Ping detected"; sid:1000001; rev:1;)
alert tcp any any -> $HOME_NET 22 (msg:"PERSO - SSH connection attempt"; sid:1000002; rev:1;)
```

Sauvegarde et ferme le fichier.
Dans le fichier de configuration, dans la partie `Step #7`, vérifie que la ligne de prise en compte de ce fichier existe, sinon ajoute-là.
Commente **toutes** les autres lignes de règles et ne garde que la règle locale.
Redémarre Snort pour appliquer les nouvelles règles avec `sudo systemctl restart snort3-nic.service`.

## Modification des fichiers de sortie

Vas dans `/var/log/snort`.
Tu as 3 fichiers. Renomme les avec le suffixe `.bak`.
Dans le fichier de configuration de Snort, vas au `Step #6`.
Commente la ligne `output alert_fast [...]` et remplace-là par `output alert_fast: /var/log/snort/snort.alert.fast.txt`.


# 🔧 Étape 6 - Utilisation de la VM attaquante

Regarde l'activité de snort avec la commande `tail -f` sur le fichier `/var/log/snort/snort.alert.fast.txt`.

## Simulation d'attaques

Depuis la VM **BadGuy** fais des ping vers la VM **GoodGuy** (ou **Snort** si tu utilise 2 VM).
Tu dois avoir des notifications dans le fichier de log.

Fais la même chose avec une connexion SSH depuis la VM **BadGuy** vers la VM **GoodGuy**.
Tu dois avoir des notifications.

Essaye d'activer d’autres règles comme `icmp.rules` ou les règles communautaires.
Vois-tu une différence ? Comment faire en sorte que cela fonctionne ?


Cet atelier est considéré comme réussi si tu as bien la détection des attaques sur la machine snort avec les règles personnalisées.