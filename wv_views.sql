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

