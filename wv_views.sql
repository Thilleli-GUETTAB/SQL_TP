-- Première vue
CREATE VIEW ALL_PLAYERS AS
SELECT TOP 1000
    p.pseudo AS [nom du joueur],
    COUNT(DISTINCT pip.id_player) AS [nombre de parties jouées],
    COUNT(pp.id_turn) AS [nombre de tours joués],
    MIN(pp.start_time) AS [date et heure de la première participation],
    MAX(pp.end_time) AS [date et heure de la dernière action]
FROM
    players p
JOIN players_in_parties pip ON p.id_player = pip.id_player
LEFT JOIN players_play pp ON p.id_player = pp.id_player
GROUP BY
    p.pseudo
ORDER BY
    [nombre de parties jouées] DESC,
    [date et heure de la première participation],
    [date et heure de la dernière action],
    [nom du joueur];
GO


-- Deuxième vue
CREATE VIEW ALL_PLAYERS_ELAPSED_GAME AS
SELECT TOP 1000
    p.pseudo AS [nom du joueur],
    pt.title_party AS [nom de la partie],
    COUNT(DISTINCT pip.id_player) AS [nombre de participants],
    DATEDIFF(SECOND, MIN(t.start_time), MAX(t.end_time)) AS [nombre de secondes écoulées]
FROM
    turns t
JOIN parties pt ON 1=1
JOIN players_in_parties pip ON 1=1
JOIN players p ON pip.id_player = p.id_player
GROUP BY
    p.pseudo,
    pt.title_party;
GO


-- Troisième vue
CREATE VIEW ALL_PLAYERS_ELAPSED_TOUR AS
SELECT TOP 1000
    p.pseudo AS [nom du joueur],
    pt.title_party AS [nom de la partie],
    t.id_turn AS [n° du tour],
    MIN(t.start_time) AS [date et heure du début du tour],
    MAX(pp.end_time) AS [date et heure de la prise de décision du joueur dans le tour],
    DATEDIFF(SECOND, MIN(t.start_time), MAX(pp.end_time)) AS [nb de secondes passées dans le tour pour le joueur]
FROM
    turns t
JOIN parties pt ON 1=1
JOIN players_play pp ON t.id_turn = pp.id_turn
JOIN players p ON pp.id_player = p.id_player
GROUP BY
    p.pseudo,
    pt.title_party,
    t.id_turn;
GO


-- Quatrième vue
CREATE VIEW ALL_PLAYERS_STATS AS
SELECT TOP 1000
    p.pseudo AS [nom du joueur],
    CASE
        WHEN pip.id_role = (SELECT id_role FROM roles WHERE description_role LIKE '%loup%')
        THEN 'loup'
        ELSE 'villageois'
    END AS [role],
    pt.title_party AS [nom de la partie],
    COUNT(pp.id_turn) AS [nb de tours joués par le joueur],
    MAX(t.id_turn) AS [nb total de tours de la partie],
    CASE
        WHEN
            (pip.id_role = (SELECT id_role FROM roles WHERE description_role LIKE '%loup%') AND pt.title_party LIKE '%loup gagne%') OR
            (pip.id_role != (SELECT id_role FROM roles WHERE description_role LIKE '%loup%') AND pt.title_party LIKE '%villageois gagne%')
        THEN 'Gagné'
        ELSE 'Perdu'
    END AS [vainqueur dépendant du rôle du joueur],
    AVG(DATEDIFF(SECOND, pp.start_time, pp.end_time)) AS [temps moyen de prise de décision du joueur]
FROM
    players p
JOIN players_in_parties pip ON p.id_player = pip.id_player
JOIN parties pt ON 1=1
JOIN turns t ON 1=1
JOIN players_play pp ON p.id_player = pp.id_player AND t.id_turn = pp.id_turn
GROUP BY 
    p.pseudo, 
    pip.id_role,
    pt.title_party;
GO