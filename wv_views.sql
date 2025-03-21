-- wv_views.sql
-- Implémentation des vues pour le jeu "Les Loups"

-- 1. Vue ALL_PLAYERS
-- Affiche l'ensemble des joueurs ayant participé à au moins une partie
CREATE VIEW ALL_PLAYERS AS
SELECT
    p.pseudo AS 'nom du joueur',
    COUNT(DISTINCT pip.id_party) AS 'nombre de parties jouées',
    COUNT(DISTINCT pp.id_turn) AS 'nombre de tours joués',
    MIN(t.start_time) AS 'date et heure de la première participation',
    MAX(pp.end_time) AS 'date et heure de la dernière action'
FROM
    players p
JOIN
    players_in_parties pip ON p.id_player = pip.id_player
JOIN
    players_play pp ON p.id_player = pp.id_player
JOIN
    turns t ON pp.id_turn = t.id_turn
GROUP BY
    p.pseudo
ORDER BY
    'nombre de parties jouées' DESC,
    'date et heure de la première participation' ASC,
    'date et heure de la dernière action' ASC,
    'nom du joueur' ASC;

-- 2. Vue ALL_PLAYERS_ELAPSED_GAME
-- Donne le nombre de secondes écoulées pour chaque partie jouée
CREATE VIEW ALL_PLAYERS_ELAPSED_GAME AS
SELECT
    p.pseudo AS 'nom du joueur',
    pa.title_party AS 'nom de la partie',
    COUNT(DISTINCT pip.id_player) AS 'nombre de participants',
    MIN(pp.start_time) AS 'date et heure de la première action du joueur dans la partie',
    MAX(pp.end_time) AS 'date et heure de la dernière action du joueur dans la partie',
    DATEDIFF(SECOND, MIN(pp.start_time), MAX(pp.end_time)) AS 'nb de secondes passées dans la partie pour le joueur'
FROM
    players p
JOIN
    players_in_parties pip ON p.id_player = pip.id_player
JOIN
    players_play pp ON p.id_player = pp.id_player
JOIN
    turns t ON pp.id_turn = t.id_turn AND t.id_party = pip.id_party
JOIN
    parties pa ON pip.id_party = pa.id_party
GROUP BY
    p.pseudo, pa.title_party, pip.id_party;

-- 3. Vue ALL_PLAYERS_ELAPSED_TOUR
-- Affiche le temps moyen de chaque prise de décision
CREATE VIEW ALL_PLAYERS_ELAPSED_TOUR AS
SELECT
    p.pseudo AS 'nom du joueur',
    pa.title_party AS 'nom de la partie',
    t.id_turn AS 'n° du tour',
    t.start_time AS 'date et heure du début du tour',
    pp.end_time AS 'date et heure de la prise de décision du joueur dans le tour',
    DATEDIFF(SECOND, t.start_time, pp.end_time) AS 'nb de secondes passées dans le tour pour le joueur'
FROM
    players p
JOIN
    players_play pp ON p.id_player = pp.id_player
JOIN
    turns t ON pp.id_turn = t.id_turn
JOIN
    parties pa ON t.id_party = pa.id_party
ORDER BY
    'nom du joueur', 'nom de la partie', 'n° du tour';

-- 4. Vue ALL_PLAYERS_STATS
-- Affiche le temps moyen de prise de décision à chaque tour
CREATE VIEW ALL_PLAYERS_STATS AS
SELECT
    p.pseudo AS 'nom du joueur',
    r.description_role AS 'role parmi loup et villageois',
    pa.title_party AS 'nom de la partie',
    COUNT(DISTINCT pp.id_turn) AS 'nb de tours joués par le joueur',
    (SELECT COUNT(*) FROM turns WHERE id_party = pa.id_party) AS 'nb total de tours de la partie',
    CASE
        WHEN r.description_role = 'loup' AND NOT EXISTS (
            SELECT 1 FROM players_in_parties
            WHERE id_party = pa.id_party AND id_role = (SELECT id_role FROM roles WHERE description_role = 'villageois') AND is_alive = 1
        ) THEN 'Victoire'
        WHEN r.description_role = 'villageois' AND EXISTS (
            SELECT 1 FROM players_in_parties
            WHERE id_party = pa.id_party AND id_role = (SELECT id_role FROM roles WHERE description_role = 'villageois') AND is_alive = 1
        ) THEN 'Victoire'
        ELSE 'Défaite'
    END AS 'vainqueur dépendant du rôle du joueur',
    AVG(DATEDIFF(SECOND, t.start_time, pp.end_time)) AS 'temps moyen de prise de décision du joueur'
FROM
    players p
JOIN
    players_in_parties pip ON p.id_player = pip.id_player
JOIN
    roles r ON pip.id_role = r.id_role
JOIN
    players_play pp ON p.id_player = pp.id_player
JOIN
    turns t ON pp.id_turn = t.id_turn AND t.id_party = pip.id_party
JOIN
    parties pa ON t.id_party = pa.id_party
GROUP BY
    p.pseudo, r.description_role, pa.title_party, pa.id_party;