# 🎹 PianoLib — Bibliothèque de partitions pour piano


## Présentation

PianoLib est une application web CRUD développée intégralement en Swift côté serveur. Elle permet de gérer une bibliothèque personnelle de partitions pour piano : ajouter, consulter, modifier, supprimer et rechercher des partitions.

---

## Fonctionnalités

- Lister toutes les partitions de la bibliothèque
- Ajouter une nouvelle partition via un formulaire
- Rechercher par titre ou compositeur
- Consulter la page de détails d'une partition
- Modifier une partition existante
- Supprimer une partition
- Validation des champs obligatoires côté serveur avec messages d'erreur

---

## Modèle de données

Chaque partition (`Score`) contient les champs suivants :

| Champ | Type | Description |
|-------|------|-------------|
| `id` | Int (auto) | Identifiant unique auto-incrémenté |
| `title` | String | Titre du morceau |
| `composer` | String | Nom du compositeur |
| `difficulty` | Enum | Débutant · Intermédiaire · Avancé · Virtuose |
| `genre` | Enum | Classique · Jazz · Pop · Romantique · Baroque · Moderne · Autre |
| `notes` | String | Remarques libres (doigtés, conseils, édition…) |

---

## Structure du projet

```
Sources/App/
├── main.swift       — Déclaration des routes et logique des handlers
├── Models.swift     — Struct Score, enums Difficulty et Genre
├── Database.swift   — Connexion SQLite et fonctions CRUD
└── Views.swift      — Génération HTML côté serveur
```

---

## Lancer l'application

```bash
# Dans le terminal GitHub Codespaces :
chmod +x build.sh run.sh   # uniquement au premier lancement
./build.sh                  # compile le projet
./run.sh                    # démarre le serveur sur le port 8080
```

Une fois lancé, ouvrez l'onglet **Ports** dans Codespaces et cliquez sur le lien du port **8080** pour accéder à l'application.

---

