-- ALL_PLAYERS VIEW --
CREATE VIEW ALL_PLAYERS AS 
SELECT 
    p.pseudo AS nom_du_joueur ,
    COUNT (DISTINCT p_parties.id_party) AS nombre_de_parties,
    COUNT (p_play.id_turn) AS nombre_de_tours_jouées ,
    MIN (t.start_time) AS date_premiere_participation,
    MAX(p_play.end_time) AS date_derniere_action
FROM players p
JOIN players_in_parties p_parties ON p.id_player = p_parties.id_player
JOIN turns t ON p_parties.id_party = t.id_party
LEFT JOIN players_play p_play ON p.id_player = p_play.id_player
GROUP BY p.pseudo;
GO


-- Pour afficher le resultat trié suivant les colonnes nombre de parties, date de la première participation, date de la dernière action, nom du joueur --
SELECT * FROM ALL_PLAYERS 
ORDER BY nombre_de_parties DESC, date_premiere_participation, date_derniere_action, nom_du_joueur;
GO


-- ALL_PLAYERS_ELAPSED_GAME VIEW --
CREATE VIEW ALL_PLAYERS_ELAPSED_GAME AS
SELECT
    p.pseudo AS nom_du_joueur,
    pa.title_party AS nom_de_la_partie,
    (SELECT COUNT(DISTINCT p_in_parties.id_player) FROM players_in_parties p_in_parties WHERE p_in_parties.id_party = pa.id_party) AS nombre_de_participants,
    MIN(p_play.start_time) AS date_premiere_action,
    MAX(p_play.end_time) AS date_derniere_action,
    DATEDIFF(SECOND, MIN(p_play.start_time), MAX(p_play.end_time)) AS nb_secondes_dans_la_partie
FROM players p
JOIN players_in_parties p_parties ON p.id_player = p_parties.id_player  
JOIN parties pa ON p_parties.id_party = pa.id_party
JOIN players_play p_play ON p.id_player = p_play.id_player
GROUP BY p.pseudo, pa.title_party, pa.id_party;
GO
-- ALL_PLAYERS_ELAPSED_TOUR VIEW --
CREATE VIEW ALL_PLAYERS_ELAPSED_TOUR AS
SELECT
    p.pseudo AS nom_du_joueur,
    pa.title_party AS nom_de_la_partie,
    t.id_turn AS numero_du_tour,
    t.start_time AS debut_du_tour,
    p_play.start_time AS decision_du_joueur,
    DATEDIFF(SECOND, t.start_time, p_play.start_time) AS temps_ecoule_pour_joueur
FROM players p
JOIN players_play p_play ON p.id_player = p_play.id_player
JOIN turns t ON p_play.id_turn = t.id_turn
JOIN parties pa ON t.id_party = pa.id_party;
GO

-- ALL_PLAYERS_STATS VIEW --
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