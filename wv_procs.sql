-- Procédure SEED_DATA
CREATE PROCEDURE SEED_DATA
(
    @NB_PLAYERS INT,
    @PARTY_ID INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Créer autant de tours de jeu que la partie peut en accepter
    DECLARE @TOTAL_TURNS INT = 10; -- Nombre de tours prédéfini, à ajuster si nécessaire
    DECLARE @CURRENT_TURN INT = 1;

    WHILE @CURRENT_TURN <= @TOTAL_TURNS
    BEGIN
        -- Insérer un nouveau tour
        INSERT INTO turns (id_turn, start_time, end_time)
        VALUES
        (
            @CURRENT_TURN,
            GETDATE(),
            DATEADD(MINUTE, 5, GETDATE()) -- Fin du tour dans 5 minutes
        );

        -- Pour chaque joueur, insérer une action de déplacement
        INSERT INTO players_play
        (
            id_player,
            id_turn,
            start_time,
            end_time,
            action,
            origin_position_row,
            origin_position_col,
            target_position_row,
            target_position_col
        )
        SELECT
            pip.id_player,
            @CURRENT_TURN,
            GETDATE(),
            DATEADD(SECOND, 30, GETDATE()), -- Action dure 30 secondes
            'move',
            CAST('0' AS VARCHAR(50)), -- Position de départ
            CAST('0' AS VARCHAR(50)),
            CAST('1' AS VARCHAR(50)), -- Position cible
            CAST('1' AS VARCHAR(50))
        FROM
            players_in_parties pip;

        SET @CURRENT_TURN = @CURRENT_TURN + 1;
    END
END
GO

-- Procédure COMPLETE_TOUR
CREATE PROCEDURE COMPLETE_TOUR
(
    @TOUR_ID INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Résoudre les demandes de déplacement
    -- Vérifier les conflits de position
    WITH DeplacementsPossibles AS (
        SELECT
            id_player,
            CAST(target_position_row AS VARCHAR(50)) AS target_position_row,
            CAST(target_position_col AS VARCHAR(50)) AS target_position_col,
            COUNT(*) OVER (PARTITION BY CAST(target_position_row AS VARCHAR(50)), CAST(target_position_col AS VARCHAR(50))) AS NombreJoueursPosition
        FROM
            players_play
        WHERE
            id_turn = @TOUR_ID
    ),
    JoueursEnElimination AS (
        SELECT
            dp.id_player
        FROM
            DeplacementsPossibles dp
        WHERE
            dp.NombreJoueursPosition > 1
            AND EXISTS (
                SELECT 1
                FROM players_in_parties pip1
                JOIN players_in_parties pip2 ON pip1.id_player != pip2.id_player
                WHERE
                    pip1.id_player = dp.id_player
                    AND pip1.id_role != pip2.id_role
            )
    )
    -- Mettre à jour le statut des joueurs éliminés
    UPDATE pip
    SET is_alive = 'dead'
    FROM
        players_in_parties pip
    JOIN JoueursEnElimination je ON pip.id_player = je.id_player;

    -- Marquer le tour comme terminé
    UPDATE turns
    SET end_time = GETDATE()
    WHERE
        id_turn = @TOUR_ID;
END
GO

-- Supprimer la procédure USERNAME_TO_LOWER si elle existe
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'USERNAME_TO_LOWER')
    DROP PROCEDURE USERNAME_TO_LOWER;
GO

-- Procédure USERNAME_TO_LOWER
CREATE PROCEDURE USERNAME_TO_LOWER
AS
BEGIN
    SET NOCOUNT ON;

    -- Convertir tous les pseudos en minuscules
    UPDATE players
    SET pseudo = LOWER(pseudo);
END
GO