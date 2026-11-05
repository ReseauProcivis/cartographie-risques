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
| `referentiel.json` | univers, mesures, risques, échelles : commun à toutes les SACICAP (v7 du 5 novembre 2026, revue d'après séminaire) |
| `societes.json` | menu « Groupe » du formulaire |
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

## Une réponse par groupe

Le formulaire demande seulement le groupe du répondant (conseil d'administration, comité de direction, collaborateurs, ou « Autre » avec un nom à saisir), puis les métiers exercés par la SACICAP. Dans la base, la colonne `societe` porte le groupe ; `prenom` et `fonction` restent vides. Plusieurs personnes peuvent répondre pour le même groupe : les résultats donnent la moyenne, avec un filtre et une couleur de point par groupe.

## Deux parties par univers

À la demande de Guillaume Macher (5 novembre 2026), chaque univers se remplit en deux temps : la partie 1 cote les risques (probabilité, impact, accepter ou réduire), la partie 2 évalue la maîtrise, mesure par mesure (non, en partie, formalisé, formalisé et contrôlé, je ne sais pas, non concerné). Chaque partie permet d'ajouter un item, coté comme les autres. Un item ajouté prend le numéro qui suit le dernier du chapitre (`GOV-R8` après `GOV-R7`). Un risque ajouté crée son item miroir en partie 2 : une mesure du même libellé, liée au risque, pour évaluer sa maîtrise ; elle disparaît avec lui. Dans la base, `cotation` porte `{p, i, t}` par risque et les risques ajoutés sous `_ajouts` (`{id, texte, p, i, t, mesure}`) ; `maitrise` porte la réponse par mesure et les mesures ajoutées sous `_ajouts` (`{id, texte, v, risque}`).

## Supprimer un risque

En partie 1, « Supprimer un risque » ouvre la liste des risques du chapitre ; un clic sur un risque demande confirmation (oui / non). Le risque supprimé garde son identifiant (les autres ne sont pas renumérotés), n'est plus à coter, et une mesure qui ne couvre plus aucun risque restant sort de la partie 2. Il peut être rétabli depuis la partie 1. Dans la base, les risques supprimés sont listés sous `cotation._supprimes` ; les résultats les montrent dans « Risques supprimés par les répondants ».

## Sur un même ordinateur

Les rapports en cours sont rangés par SACICAP dans le navigateur (`carto.s.<code>.r.<id>`) : deux SACICAP testées sur le même ordinateur ne se mélangent pas, et rien ne se mêle aux rapports du séminaire.

## Test en local

```bash
python3 -m http.server 8767 --directory cartographie-risques
```

puis ouvrir `http://127.0.0.1:8767/?s=<code>`. Avec `supabaseUrl` vide dans `config.js`, l'application tourne en mode local : n'importe quel code est accepté, les réponses restent dans le navigateur.

## Publication

GitHub Pages, branche `main`, dossier racine. Pousser sur `main` publie. Changer le numéro de version des scripts dans `index.html` à chaque mise en ligne.
