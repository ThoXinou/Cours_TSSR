| **Commande**                                  | **Description**                                             | **Exemple**                             |
|-----------------------------------------------|-------------------------------------------------------------|-----------------------------------------|
| `groupadd [name]`                             | Créer un groupe                                             | `groupadd devops`                       |
| `groupdel [name]`                             | Supprimer un groupe                                         | `groupdel devops`                       |
| `groupmod -n [newGroupname] [oldGroupname]`   | Renommer un groupe                                          | `groupmod -n admins devops`             |
| `useradd [name]`                              | Créer un utilisateur                                        | `useradd john`                          |
| `userdel [name]`                              | Supprimer un utilisateur                                    | `userdel john`                          |
| `usermod -l [newUsername] [oldUsername]`      | Renommer un utilisateur                                     | `usermod -l johnsmith john`             |
| `passwd [name]`                               | Définir le mot de passe d'un utilisateur                    | `passwd john`                           |
| `usermod -a -G sudo [user]`                   | Accorder les privilèges sudo à un utilisateur               | `usermod -a -G sudo john`               |
| `finger [user]`                               | Voir les informations d'un utilisateur                      | `finger john`                           |
| `usermod -aG [groupName] [userName]`          | Ajouter un utilisateur existant à un groupe                 | `usermod -aG devops john`               |
| `adduser [userName] [groupName]`              | Ajouter un utilisateur existant à un groupe                 | `adduser john devops`                   |
| `gpasswd -a [userName] [groupName]`           | Ajouter un utilisateur existant à un groupe                 | `gpasswd -a john devops`                |
| `useradd -G [group] [user]`                   | Ajouter un nouvel utilisateur à un groupe                   | `useradd -G devops john`                |
| `gpasswd -d [user] [group]`                   | Retirer un utilisateur d'un groupe                          | `gpasswd -d john devops`                |
| `deluser [user] [group]`                      | Retirer un utilisateur d'un groupe                          | `deluser john devops`                   |
| `getent group`                                | Lister tous les groupes                                     | `getent group`                          |
| `cat /etc/group`                              | Lister tous les groupes (alternative)                       | `cat /etc/group`                        |
| `getent passwd`                               | Lister tous les utilisateurs                                | `getent passwd`                         |
| `cat /etc/passwd`                             | Lister tous les utilisateurs (alternative)                  | `cat /etc/passwd`                       |
