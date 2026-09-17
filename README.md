# ⚔️ AzerothCore Repack — Windows x64 (WotLK 3.3.5a)

[![Build Status](https://img.shields.io/badge/Build-Automated%20CI-blue?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com)
[![WoW Version](https://img.shields.io/badge/WoW-3.3.5a%20(12340)-gold?style=for-the-badge&logo=battlenet&logoColor=white)](https://github.com/azerothcore/azerothcore-wotlk)
[![Platform](https://img.shields.io/badge/Platform-Windows%20x64-informational?style=for-the-badge&logo=windows&logoColor=white)](https://microsoft.com)
[![MySQL](https://img.shields.io/badge/Database-MySQL%208.4%20Portable-orange?style=for-the-badge&logo=mysql&logoColor=white)](https://dev.mysql.com)

Bienvenue sur le **Repack AzerothCore 100% portable** pour Windows !  
Ce projet vous permet de lancer votre propre serveur privé **World of Warcraft : Wrath of the Lich King (3.3.5a)** en quelques clics, **sans aucune connaissance technique requise**.

Tout est automatisé : la base de données est autonome (aucun WAMP / XAMPP à installer), et un menu simple vous guide du début à la fin.

---

## 🎯 Choisissez votre version

Deux déclinaisons compilées et mises à jour automatiquement sont disponibles :

| Version | Description | Idéal pour... |
| :--- | :--- | :--- |
| **🛡️ AzerothCore Standard** | Le cœur AzerothCore officiel + moteur de script **Eluna (mod-ale)**. Expérience fidèle et authentique. | Ceux qui veulent jouer normalement, tester des quêtes ou coder des scripts Lua. |
| **🤖 AzerothCore PlayerBots** | Intègre AzerothCore + **mod-ale** + **mod-playerbots**. Des bots autonomes parcourent le monde, groupent avec vous, font des donjons et du PvP ! | **Le jeu 100% solo** ou en petit comité d'amis avec un monde plein de vie. |

---

## 🚀 Guide pas-à-pas pour les débutants

Suivez ces 5 étapes simples pour jouer en moins de 10 minutes !

### Étape 1 : Télécharger le Repack
1. Rendez-vous sur la page GitHub du projet.
2. Dans la colonne de droite, cliquez sur **Releases** (ou [cliquez ici pour y accéder directement](../../releases)).
3. Sous la dernière version publiée (Latest), téléchargez le fichier **ZIP** de votre choix :
   * `AzerothCore-Repack-Windows-x64.zip` (version classique)
   * `AzerothCore-PlayerBots-Repack-Windows-x64.zip` (version avec PlayerBots)

---

### Étape 2 : Extraire l'archive
1. Faites un clic droit sur le fichier ZIP téléchargé > **Extraire tout...**
2. Choisissez un dossier simple sur votre disque dur.
   > 💡 **Conseil :** Évitez les dossiers avec des espaces bizarres ou des caractères accentués.  
   > *Exemple recommandé :* `C:\Jeux\WoW-Repack` ou `D:\AzerothCore`

---

### Étape 3 : Lancer le panneau de contrôle
Dans le dossier extrait, double-cliquez sur :
```text
AzerothCore Repack.bat
```
Une fenêtre s'ouvre avec un menu interactif :

```text
 ╔══════════════════════════════════════════════════════════════╗
 ║                 A Z E R O T H C O R E                        ║
 ║                         R E P A C K                          ║
 ╚══════════════════════════════════════════════════════════════╝

      1.  Installations
      2.  Démarrer le serveur AzerothCore
      3.  Quitter
```

---

### Étape 4 : Première installation (À faire une seule fois !)
Tapez `1` puis validez avec la touche **Entrée** pour accéder au sous-menu **Installations** :

1. **Installer MySQL :**  
   Tapez `1` : un script installe automatiquement un serveur de base de données MySQL 8.4 portable et indépendant. Patientez jusqu'au message de confirmation.
2. **Télécharger les Data (Maps, DBC, etc.) :**  
   Tapez `3` : le script va télécharger les données nécessaires (fichiers DBC, Maps, VMaps et MMaps).  
   *(Ce téléchargement fait environ 1 Go, laissez-le se terminer tranquillement).*
3. Tapez `4` pour revenir au menu principal.

---

### Étape 5 : Lancer le serveur et jouer !

1. Depuis le menu principal, tapez **`2`** (**Démarrer le serveur AzerothCore**).
2. Trois fenêtres vont s'ouvrir automatiquement :
   * 🟢 **MySQL Server** (la base de données)
   * 🔵 **AuthServer** (le serveur d'authentification et de connexion des comptes)
   * 🟣 **WorldServer** (le monde de jeu AzerothCore)
3. Attendez environ 30 secondes que la fenêtre **WorldServer** affiche :
   ```text
   AzerothCore rev. [...] ready...
   ```
4. **Créer votre compte de jeu :**  
   Dans la fenêtre de **WorldServer**, tapez directement :
   ```text
   account create VOTRE_NOM VOTRE_MOT_DE_PASSE
   ```
   *(Pour vous donner les pleins pouvoirs Maître de Jeu / GM, tapez ensuite :)*
   ```text
   account set gmlevel VOTRE_NOM 3 -1
   ```

---

## 🎮 Configurer votre jeu World of Warcraft (Client 3.3.5a)

Pour vous connecter au serveur depuis votre client World of Warcraft :

1. Ouvrez votre dossier de jeu World of Warcraft 3.3.5a.
2. Allez dans le dossier `Data` puis `frFR` (ou `enUS` / `enGB` selon la langue de votre jeu).
3. Ouvrez le fichier **`realmlist.wtf`** avec le Bloc-notes.
4. Supprimez tout son contenu et écrivez uniquement :
   ```text
   set realmlist 127.0.0.1
   ```
5. Enregistrez et fermez le fichier.
6. Lancez le jeu avec `Wow.exe` et connectez-vous avec vos identifiants !

---

## ❓ FAQ & Dépannage rapide

<details>
<summary><b>🔴 Le WorldServer se ferme immédiatement au lancement ?</b></summary>

* Vérifiez que vous avez bien téléchargé les **Data** (option `1` puis `3` du menu).
* Assurez-vous que MySQL est bien démarré (fenêtre verte).
* Vérifiez que vous n'avez pas déjà un autre serveur MySQL ou un logiciel comme WampServer / XAMPP qui tourne sur le port `3306`.
</details>

<details>
<summary><b>🔴 Bloqué à « Connexion en cours » lors de la saisie du compte ?</b></summary>

* Vérifiez que la fenêtre **AuthServer** est bien ouverte.
* Assurez-vous que votre fichier `realmlist.wtf` contient bien `set realmlist 127.0.0.1` sans fautes.
* Vérifiez que le pare-feu Windows ne bloque pas `authserver.exe` ou `worldserver.exe`.
</details>

<details>
<summary><b>🔴 Comment arrêter proprement le serveur ?</b></summary>

Dans la fenêtre **WorldServer**, tapez simplement `server shutdown 5` (il s'éteindra proprement en 5 secondes en sauvegardant les personnages), puis fermez les autres fenêtres.
</details>

---

## 📁 Structure du Repack

```text
AzerothCore-Repack/
│
├── AzerothCore Repack.bat    # Lanceur principal interactif
│
├── _mysql/                   # Base de données MySQL 8.4 portable
│   └── data/                 # Vos données et sauvegardes de jeu
│
├── _tools/                   # Utilitaires portables (curl, etc.)
│
└── azerothcore/              # Binaires et configuration du serveur
    ├── authserver.exe        # Serveur de connexion
    ├── worldserver.exe       # Cœur du monde de jeu
    ├── configs/              # Configurations du serveur (.conf)
    │   └── modules/          # Configurations des modules (mod-ale, playerbots)
    ├── lua_scripts/          # Vos scripts Eluna Lua
    └── data/                 # Données de cartes (DBC, maps, vmaps, mmaps)
```

---

## 💖 Remerciements

* [AzerothCore](https://www.azerothcore.org/) — Pour cet incroyable émulateur open-source et son travail colossal.
* [Mod-Playerbots](https://github.com/mod-playerbots/mod-playerbots) — Pour l'intelligence artificielle des bots.
