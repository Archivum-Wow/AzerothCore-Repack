# ⚔️ AzerothCore Repack

<div align="center">

[![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-gold?style=for-the-badge&logo=battlenet&logoColor=white)](https://github.com/azerothcore/azerothcore-wotlk)
[![Platform](https://img.shields.io/badge/Windows-x64-informational?style=for-the-badge&logo=windows&logoColor=white)](https://microsoft.com)

**Votre serveur World of Warcraft privé, en 10 minutes.**

Pas d'installation compliquée. Pas de ligne de commande. Juste quelques clics.

</div>

---

## 👋 C'est quoi ce truc ?

Ce dossier contient **tout ce qu'il faut** pour faire tourner votre propre serveur **World of Warcraft : Wrath of the Lich King (3.3.5a)** sur votre PC.

Vous téléchargez, vous double-cliquez sur un fichier, vous suivez le menu. C'est tout.

> 💡 **Pas besoin d'être informaticien.** Si vous savez ouvrir un fichier ZIP et suivre un menu, vous savez faire.

---

## 🎁 Quelle version choisir ?

Il y a **deux versions**. Prenez celle qui vous correspond :

| Version | En résumé | Pour qui ? |
| :--- | :--- | :--- |
| 🛡️ **Standard** | Le serveur WoW classique. | Vous voulez jouer **normalement**, comme sur un vrai serveur. |
| 🤖 **PlayerBots** | Le serveur classique **+ des bots** qui peuplent le monde (ils font des quêtes, des donjons, du PvP). | Vous voulez jouer **seul ou à deux**, mais avec un monde qui vit autour de vous. |

> ❓ **Vous hésitez ?** Prenez la version **PlayerBots**. Elle contient tout ce que fait la Standard, plus les bots.

---

## 🚀 Les 5 étapes (pour débutants)

### 📥 Étape 1 — Télécharger

1. Allez sur la page **Releases** du projet (lien dans la colonne de droite sur GitHub).
2. Téléchargez le fichier **ZIP** correspondant à votre version :
   * `AzerothCore-Repack-Windows-x64.zip` (Standard)
   * `AzerothCore-PlayerBots-Repack-Windows-x64.zip` (PlayerBots)

> ⏳ Le fichier fait environ 500 Mo à 1 Go. Le téléchargement peut prendre quelques minutes.

---

### 📦 Étape 2 — Extraire le ZIP

1. **Clic droit** sur le fichier ZIP → **Extraire tout…**
2. Choisissez un dossier **simple**, par exemple :
   * `C:\AzerothCore`
   * `D:\WoW-Repack`

> ⚠️ **Évitez** les dossiers avec des accents, des espaces bizarres, ou qui sont dans `Téléchargements` / `Bureau`. Prenez un dossier à la racine du disque (C: ou D:).

---

### 🖱️ Étape 3 — Lancer le menu

Dans le dossier que vous venez d'extraire, **double-cliquez** sur :

```
AzerothCore Repack.bat
```

Une fenêtre noire s'ouvre avec un menu. **C'est normal, c'est le panneau de contrôle.**

Vous verrez ceci :

```
 ╔══════════════════════════════════════════════════════════════╗
 ║                 A Z E R O T H C O R E                        ║
 ║                         R E P A C K                          ║
 ╚══════════════════════════════════════════════════════════════╝

      1.  Installations
      2.  Démarrer le serveur AzerothCore
      3.  Quitter
```

> 💡 **Comment répondre ?** Tapez le chiffre voulu au clavier, puis appuyez sur **Entrée**.

---

### ⚙️ Étape 4 — Première installation (une seule fois !)

Tapez **`1`** puis **Entrée** pour ouvrir le menu **Installations**.

Vous arrivez ici :

```
      1.  Installation de MySQL
      2.  Téléchargement des sources AzerothCore
      3.  Téléchargement des Data AzerothCore
      4.  Retour
```

Faites ces **3 choses**, dans cet ordre :

**1️⃣ Tapez `1` — Installation de MySQL**

Une fenêtre s'ouvre, MySQL s'installe tout seul. Attendez le message de fin. Fermez la fenêtre quand c'est terminé.

**2️⃣ Tapez `3` — Téléchargement des Data AzerothCore**

Environ **1 Go** de fichiers. Laissez la fenêtre travailler, ça peut prendre **10 à 30 minutes** selon votre connexion. Ne fermez **pas** la fenêtre avant la fin.

**3️⃣ Tapez `4` — Retour**

Vous revenez au menu principal.

---

### 🎮 Étape 5 — Démarrer et jouer !

Depuis le menu principal, tapez **`2`** puis **Entrée**.

**Trois fenêtres** vont s'ouvrir :

| Fenêtre | Rôle | Couleur |
| :--- | :--- | :--- |
| MySQL | La base de données (mémoire du serveur) | 🟢 |
| AuthServer | Gère les connexions des joueurs | 🔵 |
| WorldServer | Le monde de jeu | 🟣 |

> ⏳ Attendez **environ 30 secondes** que tout démarre. La fenêtre **WorldServer** affichera `ready...` quand c'est bon.

**Créer votre compte de jeu :**

Dans la fenêtre **WorldServer**, tapez directement (sans menu, juste au clavier) :

```
account create VOTRE_NOM VOTRE_MOT_DE_PASSE
```

Exemple :
```
account create Jean monmotdepasse123
```

Pour vous donner les **droits de Maître du Jeu** (GM), tapez ensuite :
```
account set gmlevel Jean 3 -1
```

---

## 🕹️ Connecter votre jeu (client WoW 3.3.5a)

Vous avez besoin du **client WoW 3.3.5a** installé quelque part sur votre PC.

**Configurez-le pour qu'il se connecte à VOTRE serveur :**

1. Ouvrez le dossier de votre client WoW 3.3.5a.
2. Allez dans `Data` → `frFR` (ou `enUS` / `enGB` selon la langue).
3. Ouvrez `realmlist.wtf` avec le **Bloc-notes**.
4. Effacez tout et écrivez **une seule ligne** :
   ```
   set realmlist 127.0.0.1
   ```
5. **Enregistrez** et fermez.
6. Lancez `Wow.exe`, connectez-vous avec votre compte créé à l'étape 5.

> ✅ `127.0.0.1` = "mon propre PC". C'est l'adresse de votre serveur local.

---

## 🛟 Ça ne marche pas ?

### 🔴 Le WorldServer se ferme tout seul

* Avez-vous bien fait l'**étape 4** en entier (MySQL + Data) ?
* La fenêtre **MySQL** (verte) est-elle bien ouverte ?
* Avez-vous un autre logiciel qui utilise le port **3306** (WampServer, XAMPP…) ? Fermez-le.

### 🔴 Bloqué sur "Connexion en cours"

* La fenêtre **AuthServer** (bleue) est-elle ouverte ?
* Votre fichier `realmlist.wtf` contient-il exactement `set realmlist 127.0.0.1` ?
* Le pare-feu Windows demande une autorisation ? **Cliquez sur Autoriser**.

### 🔴 Je veux arrêter le serveur

Dans la fenêtre **WorldServer**, tapez :
```
server shutdown 5
```

Le serveur s'éteint proprement en 5 secondes. Fermez ensuite les autres fenêtres.

---

## 📁 À quoi ressemble le dossier ?

```
AzerothCore-Repack/
│
├── AzerothCore Repack.bat   ← Le menu (double-cliquez dessus)
│
├── _mysql/                  ← La base de données
│
├── _tools/                  ← Outils internes (ne pas toucher)
│
└── azerothcore/             ← Le serveur
    ├── authserver.exe       ← Connexion des joueurs
    ├── worldserver.exe      ← Le monde de jeu
    ├── configs/             ← Réglages du serveur
    ├── lua_scripts/         ← Vos scripts personnalisés
    └── data/                ← Cartes et données du jeu
```

---

<div align="center">

**Bon jeu en Azeroth !** ⚔️

*Remerciements :* [AzerothCore](https://www.azerothcore.org/) · [Mod-Playerbots](https://github.com/mod-playerbots/mod-playerbots)

</div>
