# Cartographie des risques Procivis : un outil par SACICAP

Formulaire d'autodiagnostic des risques pour le conseil d'administration de chaque SACICAP du réseau Procivis, issu de la carto du séminaire des administrateurs du 20 octobre 2026 (dépôt `ReseauProcivis/seminaire_administrateurs`, qui reste en l'état).

Chaque SACICAP a son adresse et sa clé :

- **formulaire** : `https://reseauprocivis.github.io/cartographie-risques/?s=<code de la SACICAP>` ;
- **résultats** : même adresse, onglet Résultats, avec la clé de la SACICAP. Elle n'y voit que ses propres réponses. Aucun écran ne compile plusieurs SACICAP.

Une adresse sans code, ou avec un code inconnu, affiche « Ce lien n'est pas valide ». Les codes contiennent une partie tirée au hasard : on ne peut pas remplir le formulaire d'une autre SACICAP en devinant son code.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html`, `app.js`, `store.js`, `styles.css` | l'application (JavaScript sans dépendance) |
| `referentiel.json` | univers, mesures, risques, échelles : commun à toutes les SACICAP |
| `societes.json` | menu « Groupe » et « Fonction » du formulaire |
| `config.js` | adresse et clé publique Supabase, seuil par défaut, rafraîchissement |
| `qr.html` | QR code d'une SACICAP : `qr.html?s=<code>` |
| `supabase/sessions.sql` | table des sessions SACICAP et contrôle des clés, sans aucune clé |

## Base de données

Même projet Supabase que le séminaire (`carto-risques`), même table `reponses` : chaque réponse porte le code de sa SACICAP dans la colonne `session`. `supabase/sessions.sql` ajoute :

- la table `sessions` (code, nom affiché, clé des résultats, formulaire ouvert ou fermé), illisible depuis la page ;
- la règle d'écriture : une session dont le nom commence par `sacicap-` doit être inscrite et ouverte ;
- `infos_session` : le nom à afficher, sans clé ;
- `lire_reponses` et `reinitialiser_session` : clé de la SACICAP, ou clé d'administration ;
- `lire_toutes_reponses` (sauvegarde Leviia) : la clé d'administration lit tout, la clé du séminaire ne lit plus les SACICAP.

Les sessions du séminaire gardent leur fonctionnement. Le script a été éprouvé sur un Postgres local (30 contrôles) avant exécution. La version remplie (clé d'administration, codes et clés des SACICAP) se garde hors du dépôt, qui est public.

Inscrire une SACICAP : une ligne dans `sessions` (code `sacicap-<nom>-<6 caractères au hasard>`, clé de 10 caractères ou plus). Fermer son formulaire : `update public.sessions set ouverte = false where code = '...'`. Ses résultats restent lisibles.

## Sur un même ordinateur

Les rapports en cours sont rangés par SACICAP dans le navigateur (`carto.s.<code>.r.<id>`) : deux SACICAP testées sur le même ordinateur ne se mélangent pas, et rien ne se mêle aux rapports du séminaire.

## Test en local

```bash
python3 -m http.server 8767 --directory cartographie-risques
```

puis ouvrir `http://127.0.0.1:8767/?s=<code>`. Avec `supabaseUrl` vide dans `config.js`, l'application tourne en mode local : n'importe quel code est accepté, les réponses restent dans le navigateur.

## Publication

GitHub Pages, branche `main`, dossier racine. Pousser sur `main` publie. Changer le numéro de version des scripts dans `index.html` à chaque mise en ligne.
