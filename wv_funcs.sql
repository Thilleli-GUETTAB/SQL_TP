-- Supprimer les fonctions existantes si elles existent
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'random_position')
    DROP FUNCTION random_position;
GO

-- Fonction random_position
CREATE FUNCTION random_position
(
    @nb_lignes INT,
    @nb_colonnes INT
)
RETURNS TABLE
AS
RETURN
(
    WITH
    PositionsUtilisees AS (
        SELECT DISTINCT
            CAST(origin_position_row AS VARCHAR(50)) AS ligne,
            CAST(origin_position_col AS VARCHAR(50)) AS colonne
        FROM players_play
    ),
    ToutesPositionsPossibles AS (
        SELECT
            CAST(ligne AS VARCHAR(10)) AS ligne,
            CAST(colonne AS VARCHAR(10)) AS colonne
        FROM
        (
            SELECT TOP (@nb_lignes * @nb_colonnes)
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS ligne,
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 % @nb_colonnes AS colonne
            FROM sys.objects o1
            CROSS JOIN sys.objects o2
        ) AS AllPositions
    )
    SELECT TOP 1
        ligne,
        colonne
    FROM ToutesPositionsPossibles
    WHERE
        NOT EXISTS (
            SELECT 1 FROM PositionsUtilisees
            WHERE PositionsUtilisees.ligne = ToutesPositionsPossibles.ligne
            AND PositionsUtilisees.colonne = ToutesPositionsPossibles.colonne
        )
);
GO

-- Fonction random_role identique à la version précédente
CREATE FUNCTION random_role()
RETURNS INT
AS
BEGIN
    DECLARE @total_players INT
    DECLARE @wolf_players INT
    DECLARE @villager_players INT
    DECLARE @wolf_role_id INT
    DECLARE @villager_role_id INT

    -- Récupérer les ID des rôles
    SELECT @wolf_role_id = id_role FROM roles WHERE description_role LIKE '%loup%'
    SELECT @villager_role_id = id_role FROM roles WHERE description_role LIKE '%villageois%'

    -- Compter le nombre total de joueurs et de loups
    SELECT @total_players = COUNT(*) FROM players_in_parties
    SELECT @wolf_players = COUNT(*) FROM players_in_parties WHERE id_role = @wolf_role_id

    -- Déterminer le quota de loups (supposons 1/3 des joueurs)
    DECLARE @max_wolf_players INT = FLOOR(@total_players / 3)

    -- Si le quota de loups n'est pas atteint, retourner le rôle de loup
    RETURN CASE
        WHEN @wolf_players < @max_wolf_players THEN @wolf_role_id
        ELSE @villager_role_id
    END
END
GO

-- Fonction get_the_winner identique
CREATE FUNCTION get_the_winner
(
    @partyid INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        p.pseudo AS [nom du joueur],
        CASE
            WHEN pip.id_role = (SELECT id_role FROM roles WHERE description_role LIKE '%loup%')
            THEN 'loup'
            ELSE 'villageois'
        END AS [role],
        pt.title_party AS [nom de la partie],
        COUNT(pp.id_turn) AS [nb de tours joués par le joueur],
        MAX(t.id_turn) AS [nb total de tours de la partie],
        AVG(DATEDIFF(SECOND, pp.start_time, pp.end_time)) AS [temps moyen de prise de décision du joueur]
    FROM
        players p
    JOIN players_in_parties pip ON p.id_player = pip.id_player
    JOIN parties pt ON pip.id_party = pt.id_party
    JOIN turns t ON pt.id_party = t.id_party
    JOIN players_play pp ON p.id_player = pp.id_player AND t.id_turn = pp.id_turn
    WHERE
        pt.title_party LIKE
        (
            CASE
                WHEN EXISTS (SELECT 1 FROM players_in_parties pip2
                             WHERE pip2.id_role = (SELECT id_role FROM roles WHERE description_role LIKE '%loup%')
                             AND pt.title_party LIKE '%loup gagne%')
                THEN '%loup gagne%'
                ELSE '%villageois gagne%'
            END
        )
    GROUP BY
        p.pseudo,
        pip.id_role,
        pt.title_party
);
GO