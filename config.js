/* Configuration de la cartographie des risques Procivis, version « un outil par SACICAP » (29 octobre 2026).
   Chaque SACICAP a son adresse : https://reseauprocivis.github.io/cartographie-risques/?s=<code de la SACICAP>.
   Le code, le nom affiché et la clé des résultats de chaque SACICAP sont dans la table « sessions » de Supabase
   (supabase/sessions.sql), pas dans ce fichier : une adresse sans code ou avec un code inconnu affiche « lien non valide ».
   Laisser supabaseUrl vide => mode local (les réponses restent sur l'appareil, pour les essais). */
window.CARTO_CONFIG = {
  // Supabase : même projet que le séminaire du 20 octobre (carto-risques). Clé publique (« publishable »),
  // conçue pour être exposée : elle n'écrit que dans une session inscrite et ne lit rien sans clé d'accès.
  supabaseUrl: "https://ucfnfvpojvcjucspkrct.supabase.co",
  supabaseAnonKey: "sb_publishable_iuwGATVzwLIrf0WgihMZmA_z1jzmkXj",
  // Seuil d'appétence par défaut sur la page de résultats (4, 6 ou 9)
  seuilDefaut: 6,
  // Rafraîchissement automatique des résultats, en secondes. 30 plutôt que 15 au séminaire : avec plusieurs
  // dizaines de SACICAP, les lectures comptent dans le quota de données sortantes de Supabase (5 Go par mois en gratuit).
  rafraichissement: 30
};
