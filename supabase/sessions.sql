-- Cartographie des risques Procivis : un outil par SACICAP (29 octobre 2026).
-- À exécuter une fois dans l'éditeur SQL du projet Supabase « carto-risques » (le même que celui du séminaire).
-- Ce fichier, dans le dépôt public, ne contient aucune clé : la version remplie (clé d'administration et
-- sessions des SACICAP) se garde hors du dépôt.
--
-- Principe : un seul formulaire, une session par SACICAP. Chaque SACICAP a son adresse (?s=sacicap-...) et sa
-- clé d'accès aux résultats ; elle ne lit que ses propres réponses. Une clé d'administration ouvre toutes les
-- sessions SACICAP (dépannage, sauvegarde automatique sur Leviia) ; aucun écran ne compile plusieurs SACICAP.
--
-- Les sessions dont le nom commence par « sacicap- » suivent ces règles. Les autres (séminaire du 20 octobre,
-- son archive, test-connexion) gardent leur fonctionnement : la clé cle_resultats de la table parametres.

-- 1. Une ligne par SACICAP. Sans règle d'accès, la clé publique du navigateur ne peut ni la lire ni l'écrire.
create table if not exists public.sessions (
  code text primary key,                      -- dans l'adresse : ?s=sacicap-...
  libelle text not null,                      -- nom affiché sur la page
  cle text not null,                          -- clé d'accès aux résultats de cette SACICAP
  ouverte boolean not null default true,      -- false : le formulaire n'accepte plus de réponses
  created_at timestamptz not null default now(),
  constraint sessions_code_format check (code ~ '^sacicap-[a-z0-9-]{6,80}$' and code not like '%-archive-%'),
  constraint sessions_cle_longueur check (char_length(cle) >= 10)
);
alter table public.sessions enable row level security;
revoke all on public.sessions from anon, authenticated;

-- 2. Session d'origine d'une archive : « sacicap-x-archive-2026-11-02-10h15 » -> « sacicap-x »
create or replace function public.session_base(p_session text)
returns text
language sql
immutable
as $$ select split_part(coalesce(p_session, ''), '-archive-', 1) $$;

-- 3. Vérification d'une clé pour une session (archives comprises). Réservée aux fonctions ci-dessous :
--    la clé publique ne peut pas l'appeler directement (sinon elle testerait des clés sans le délai de 0,5 s).
--    Supabase donne d'office à anon le droit d'exécuter chaque nouvelle fonction : il faut le lui retirer nommément.
create or replace function public.cle_valide(p_session text, p_cle text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_base text := public.session_base(p_session);
begin
  if p_cle is null or p_cle = '' then
    return false;
  end if;
  if v_base like 'sacicap-%' then
    return exists (select 1 from public.sessions where code = v_base and cle = p_cle)
        or exists (select 1 from public.parametres where nom = 'cle_admin' and valeur = p_cle);
  end if;
  return exists (select 1 from public.parametres where nom = 'cle_resultats' and valeur = p_cle);
end;
$$;
revoke all on function public.cle_valide(text, text) from public, anon, authenticated;

-- 4. Le formulaire n'écrit que dans une session SACICAP inscrite et ouverte (les autres sessions : inchangé)
create or replace function public.session_ouverte(p_session text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case when coalesce(p_session, '') like 'sacicap-%'
    then exists (select 1 from public.sessions where code = p_session and ouverte)
    else true end;
$$;
revoke all on function public.session_ouverte(text) from public;
grant execute on function public.session_ouverte(text) to anon;

drop policy if exists "insertion publique" on public.reponses;
create policy "insertion publique" on public.reponses
  for insert to anon with check (public.session_ouverte(session));

-- 5. Ce que la page peut savoir d'une session sans clé : son nom, si elle accepte des réponses, si c'est une archive.
--    Aucune ligne : adresse inconnue.
create or replace function public.infos_session(p_session text)
returns table (libelle text, ouverte boolean, archive boolean)
language sql
stable
security definer
set search_path = public
as $$
  select s.libelle, s.ouverte and s.code = p_session, s.code <> p_session
  from public.sessions s
  where s.code = public.session_base(p_session);
$$;
revoke all on function public.infos_session(text) from public;
grant execute on function public.infos_session(text) to anon;

-- 6. Lecture des résultats : même fonction qu'avant (dernière ligne par participant et univers),
--    la clé est vérifiée par cle_valide
create or replace function public.lire_reponses(p_session text, p_cle text)
returns setof public.reponses
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.cle_valide(p_session, p_cle) then
    perform pg_sleep(0.5);
    raise exception 'cle_invalide' using errcode = 'P0001';
  end if;
  return query
    select distinct on (participant_id, univers) *
    from public.reponses
    where session = p_session
    order by participant_id, univers, created_at desc;
end;
$$;
revoke all on function public.lire_reponses(text, text) from public;
grant execute on function public.lire_reponses(text, text) to anon;

-- 7. Remise à zéro : même fonction qu'avant (remise-distance.sql), la clé est vérifiée par cle_valide
create or replace function public.reinitialiser_session(p_session text, p_cle text)
returns table (archive text, lignes integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_archive text;
  v_n integer;
begin
  if not public.cle_valide(p_session, p_cle) then
    perform pg_sleep(0.5);
    raise exception 'cle_invalide' using errcode = 'P0001';
  end if;
  if p_session is null or p_session = '' or p_session like '%-archive-%' then
    raise exception 'session_invalide' using errcode = 'P0001';
  end if;
  v_archive := p_session || '-archive-' || to_char(now() at time zone 'Europe/Paris', 'YYYY-MM-DD-HH24"h"MI');
  update public.reponses set session = v_archive where session = p_session;
  get diagnostics v_n = row_count;
  insert into public.parametres (nom, valeur)
    values ('remise:' || p_session, to_char(clock_timestamp() at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'))
    on conflict (nom) do update set valeur = excluded.valeur;
  return query select v_archive, v_n;
end;
$$;
revoke all on function public.reinitialiser_session(text, text) from public;
grant execute on function public.reinitialiser_session(text, text) to anon;

-- 8. Export complet (sauvegarde automatique) : la clé d'administration lit tout ; la clé du séminaire
--    (cle_resultats) ne lit plus que les sessions hors SACICAP
create or replace function public.lire_toutes_reponses(p_cle text)
returns setof public.reponses
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_cle is not null and p_cle <> ''
     and exists (select 1 from public.parametres where nom = 'cle_admin' and valeur = p_cle) then
    return query select * from public.reponses order by session, created_at asc;
  elsif p_cle is not null and p_cle <> ''
     and exists (select 1 from public.parametres where nom = 'cle_resultats' and valeur = p_cle) then
    return query select * from public.reponses
      where public.session_base(session) not like 'sacicap-%'
      order by session, created_at asc;
  else
    perform pg_sleep(0.5);
    raise exception 'cle_invalide' using errcode = 'P0001';
  end if;
end;
$$;
revoke all on function public.lire_toutes_reponses(text) from public;
grant execute on function public.lire_toutes_reponses(text) to anon;

-- 9. Clé d'administration (à remplacer, 20 caractères ou plus) et inscription des SACICAP.
--    Le code et la clé d'une SACICAP se tirent au hasard : un code devinable permettrait de remplir son formulaire.
-- insert into public.parametres (nom, valeur) values ('cle_admin', 'REMPLACER-PAR-LA-CLE-ADMIN')
--   on conflict (nom) do update set valeur = excluded.valeur;
-- insert into public.sessions (code, libelle, cle) values ('sacicap-exemple-a1b2c3', 'Nom de la SACICAP', 'REMPLACER-PAR-SA-CLE')
--   on conflict (code) do update set libelle = excluded.libelle, cle = excluded.cle;
--
-- Fermer le formulaire d'une SACICAP (ses résultats restent lisibles) :
-- update public.sessions set ouverte = false where code = 'sacicap-...';
-- Changer la clé d'une SACICAP :
-- update public.sessions set cle = 'NOUVELLE-CLE' where code = 'sacicap-...';
