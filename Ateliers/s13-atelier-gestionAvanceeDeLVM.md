# Introduction

Cet atelier va t'initier à la gestion avancée des partitions sous Linux en utilisant LVM (_Logical Volume Manager_). En suivant les différentes étapes, tu vas pouvoir créer, gérer, et manipuler les différents éléments de LVM. 

```spacer-small
```

![image avec plusieurs disques à gauche une flche de la gauche vers la droite et un gros disque à droite](https://storage.googleapis.com/quest_editor_uploads/YD8e5f75ddR5nZqkl0231muhqQjoZHm6.png)


```spacer-small
```

# 🤓 Objectifs :

✅ Manipuler des PV, VG, et LV
✅ Effectuer des actions avancées sur LVM


# sommaire


- - -

# ✔️ Étape 1 - Prérequis

Pour cet atelier, tu as besoin : 

- Un hyperviseur comme Virtualbox pour pouvoir créer des VM
- 1 VM avec debian 12 installé et mise-à-jour, avec en plus du disque système :
  - Un disque de 10 Go
  - Un disque de 20 Go
  - Un disque de 25 Go
- Faire la configuration système avec la partition **/Home** séparée


```alert-info
Les expérimentations pratiques ont été testées avec Debian 12. Cette VM fonctionne sur VirtualBox 7, lui-même fonctionnant sur un système hôte Ubuntu 22.04 LTS.
Elles peuvent être reproduites avec d'autres versions de systèmes, et sur d'autres environnement, mais des différences peuvent alors apparaître.
```

# 🔬 Étape 2 - Initialisation et création des LV

```alert-info
On estime que lvm est installé sur le système.
Donc à faire si ce n'est pas le cas.
```

Utilisation de 2 disques de 10 et 20 Go.
- Identifier les 2 disques non-système avec `fdisk -l`, normalement **/dev/sdb** et **/dev/sdc**.
- Initialiser les disques pour l'utilisation de LVM avec la commande `pvcreate` sur chacun des 2 disques.
- Créer un groupe de volume **vg_datas** avec la commande `vgcreate` avec les 2 disques
- Vérifier avec `vgdisplay` que la création s'est bien passée (tu dois avoir un **VG Size** de la taille totale des 2 disques)
- Créer un volume logique **lv_datas** de 25 Go avec la commande `lvcreate` :

```bash
lvcreate -L 25G -n lv_datas vg_datas
```
- Vérifier avec `lvdisplay` que tout est bien crée (tu dois avoir un **LV Size** de la taille que tu as choisi).

# 🔬 Étape 3 - Formatage et montage de FS

- Formatage du LV en ext4 :
```bash
mkfs.ext4 /dev/vg_datas/lv_datas
```
- Création d'un point de montage avec montage du LV :
```bash
mkdir /mnt/datas
mount /dev/vg_data/lv_data /mnt/datas
```
- Pour le montage automatique au démarrage, ajouter au fichier **/etc/fstab** la ligne `/dev/vg_datas/lv_datas /mnt/datas ext4 defaults 0 2`

# 🔬 Étape 4 - Étendre le LV

- Pour vérifier la place restante sur le VG, exécuter `vgs`
- Pour etendre le LV avec la place restante :
```bash
lvextend -l +100%FREE /dev/vg_datas/lv_datas
```
- Ensuite il faut étendre le FS :
```bash
resize2fs /dev/vg_datas/lv_datas
```
- Vérifier avec `lvs` que l'opération a réussi

# 🔬 Étape 5 - Ajout d'un disque au PV existant

Utilisation du disque de 25 Go.
- Initialiser le nouveau disque :
```bash
# On estime que le nouveau disque est /dev/sdd
pvcreate /dev/sdd
```
- Ajouter ce nouveau disque au PV existant :
```bash
vgextend vg_datas /dev/sdd
```
- Vérifier avec `vgs` que l'information de **VFree** correspond à la taille du disque ajouté
- Créer un nouveau LV **lv_datas2** de 15 Go :
```bash
lvcreate  -L 15G -n lv_datas2 vg_datas
```
- Formater ce LV :
```bash
mkfs.ext4 /dev/vg_datas/lv_datas2
```
- Effectuer le montage :
```bash
mkdir /mnt/datas2
mount /dev/vg_datas/lv_datas2 /mnt/datas2
```
- Ajouter dans le fichier **/etc/fstab** la ligne `/dev/vg_datas/lv_datas2 /mnt/datas2 ext4 defaults 0 2`

# 🔬 Étape 6 - Création d'un snapshot

- Exécute les commandes suivantes pour faire un snapshot :
```bash
lvcreate --size 5G --snapshot --name lv_datas_snap /dev/vg_datas/lv_datas2
mkdir /mnt/datas_snap
mount /dev/vg_datas/lv_datas_snap /mnt/datas_snap/
```
- Vérification du contenu du snapshot :
```bash
ls /mnt/datas2
ls /mnt/datas_snap
```
> Si c'est bien un snapshot, le contenu de **datas_snap** est identique à celui de **lv_datas2**

- Pour supprimer le snapshot :
```bash
umount /mnt/datas_snap
lvremove /dev/vg_datas/lv_datas_snap
```

# 🔬 Étape 7 - Redimensionnement d'un LV

- Tout d'abord, il faut le démonter avec `umount /mnt/datas`
- Pour le redimensionner à 15 Go :
```bash
lvresize -L 15G /dev/vg_datas/lv_datas
```
```alert-warnin
Un message d'alerte te prévient que tes données ainsi que ton FS peuvent être détruite !
C'est normal car tu vas réduire la taille.
LVM ne gère pas les données, donc même si le LV est vide, comme ici, tu as le message d'alerte.
```
- Ne pas oublier de redimensionner le FS :
```bash
resize2fs /dev/vg_datas/lv_datas
```

Pourquoi cela ne marche pas ?
Comme indiqué à l'écran, essaye d'exécuter la commande `e2fsck -f /dev/vg_datas/lv_datas`.
Est-ce que cela marche ?

Tu as ce message, et les aerreurs associées car la taille du FS dépasse actuellement la taille physique du LV.
Tu as ce dysfonctionnement car tu as réduit la taille du LV sans réduire d'abord la taille du FS ! Cette manipulation amène une corruption dans la structure du FS.

- Pour pouvoir faire cela correctement, il faut tout d'abord revenir à la taille initiale du LV :
```bash
lvresize -L 29.99G /dev/vg_datas/lv_datas
```
- Puis tu peux réparer le FS :
```bash
e2fsck -f /dev/vg_datas/lv_datas
```
- Cela va te permettre de réduire le FS :
```bash
resize2fs /dev/vg_datas/lv_datas 15G
```
- Uniquement là tu peux réduire la taille du LV :
```bash
lvresize -L 15G /dev/vg_datas/lv_datas
```
- Tu peux vérifier que l'opération a réussi avec la commande :
```bash
e2fsck -f /dev/vg_datas/lv_datas
```

Valide l'atelier si tu as réussi à gérer LVM comme demandé.