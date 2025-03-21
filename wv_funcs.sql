<<<<<<< HEAD
-- Supprimer les fonctions existantes si elles existent
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'FN' AND name = 'random_position')
    DROP FUNCTION random_position;
GO

-- Fonction random_position
CREATE FUNCTION random_position
(
    @nb_lignes INT,
    @nb_colonnes INT
=======
CREATE FUNCTION random_position(
    -- @nb_lignes INT,
    -- @nb_colonnes INT,
    @id_party INT

)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @row INT, @col INT, @position VARCHAR(50);
    DECLARE @existe BIT = 1;
    WHILE (@existe = 1)
    BEGIN
        SET @row = CAST((RAND(CHECKSUM(NEWID())) * @nb_lignes) + 1 AS INT);
        SET @col = CAST((RAND(CHECKSUM(NEWID())) * @nb_colonnes) + 1 AS INT);
        SET @position = CAST(@row AS VARCHAR(10)) + ',' + CAST(@col AS VARCHAR(10));
        IF NOT EXISTS (
            SELECT 1
            FROM players_play pp
            JOIN turns t ON pp.id_turn = t.id_turn
            WHERE t.id_party = @id_party
              AND pp.target_position_row = CAST(@row AS VARCHAR(10))
              AND pp.target_position_col = CAST(@col AS VARCHAR(10))
        )
            SET @existe = 0;
    END;
    RETURN @position;
END;
GO

CREATE FUNCTION random_role(
    @id_party INT
      -- @max_wolves INT
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @nb_wolves INT;
    SELECT @nb_wolves = COUNT(*)
    FROM players_in_parties
    WHERE id_party = @id_party
      AND id_role = (SELECT id_role FROM roles WHERE description_role = 'loup');
    IF (@nb_wolves < @max_wolves)
        RETURN (SELECT description_role FROM roles WHERE description_role = 'loup');
    ELSE
        RETURN (SELECT description_role FROM roles WHERE description_role = 'villageois');
    RETURN '';
END;
GO

CREATE FUNCTION get_the_winner(
    @partyid INT
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
)
RETURNS TABLE
AS
RETURN
(
    WITH PlayerStats AS (
        SELECT 
<<<<<<< HEAD
            col, row
        FROM 
            (SELECT TOP (@nb_cols) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS col FROM master.dbo.spt_values) AS Cols,
            (SELECT TOP (@nb_rows) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS row FROM master.dbo.spt_values) AS Rows
    ) AS AllPositions
    WHERE NOT EXISTS
    (
        -- Vérifie si cette position est déjà occupée par un obstacle, un joueur ou autre
        SELECT 1 
        FROM board_state
        WHERE 
            id_party = @id_party 
            AND position_col = AllPositions.col 
            AND position_row = AllPositions.row
=======
            p.pseudo,
            r.description_role,
            pt.title_party,
            COUNT(pp.id_turn) AS tours_joues,
            (SELECT COUNT(*) FROM turns WHERE id_party = @partyid) AS total_tours,
            AVG(DATEDIFF(SECOND, pp.start_time, pp.end_time)) AS avg_decision_time
        FROM players_in_parties pip
        JOIN players p ON pip.id_player = p.id_player
        JOIN roles r ON pip.id_role = r.id_role
        JOIN parties pt ON pip.id_party = pt.id_party
        LEFT JOIN players_play pp ON p.id_player = pp.id_player
        LEFT JOIN turns t ON pp.id_turn = t.id_turn AND t.id_party = @partyid
        WHERE pip.id_party = @partyid
          AND CAST(pip.is_alive AS VARCHAR(50)) = 'yes'
        GROUP BY p.pseudo, r.description_role, pt.title_party
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
    )
    SELECT TOP 1 *
    FROM PlayerStats
    ORDER BY avg_decision_time
);
<<<<<<< HEAD

-- 2. Fonction random_role()
-- Renvoie le prochain rôle à affecter au joueur en cours d'inscription
CREATE FUNCTION random_role(@id_party INT)
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
=======
GO
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
