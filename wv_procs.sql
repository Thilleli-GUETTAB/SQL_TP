<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
-- wv_procs.sql
-- Implémentation des procédures pour le jeu "Les Loups"

-- 1. Procédure SEED_DATA
-- Crée autant de tours de jeu que la partie peut en accepter
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
=======
-- Procédure SEED_DATA
>>>>>>> eab7d2c841e8387861d4578f6faad93af09fdfaa
=======
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
CREATE PROCEDURE SEED_DATA
(
    @NB_PLAYERS INT,
    @PARTY_ID INT
)
AS
BEGIN
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
    SET NOCOUNT ON;
    DECLARE @i INT = 1;
    DECLARE @NB_TOURS INT = @NB_PLAYERS * 5; 
    WHILE @i <= @NB_TOURS
    BEGIN
        INSERT INTO turns (id_turn, id_party, start_time, end_time)
        VALUES (@i, @PARTY_ID, NULL, NULL);
        SET @i = @i + 1;
    END
END;
GO

<<<<<<< HEAD
=======
    DECLARE @nb_tours INT;
    DECLARE @i INT = 1;
    DECLARE @current_time DATETIME = GETDATE();
    DECLARE @tour_duration INT;
=======
    SET NOCOUNT ON;
>>>>>>> eab7d2c841e8387861d4578f6faad93af09fdfaa

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

<<<<<<< HEAD
        -- Met à jour le temps pour le prochain tour
        SET @current_time = DATEADD(SECOND, @tour_duration, @current_time);
        SET @i = @i + 1;
    END;
END;

-- 2. Procédure COMPLETE_TOUR
-- Applique toutes les demandes de déplacement
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
=======
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
CREATE PROCEDURE COMPLETE_TOUR
    @TOUR_ID INT,
    @PARTY_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            UPDATE pip
            SET is_alive = 'no'
            FROM players_in_parties pip
            JOIN players_play pp_vil ON pip.id_player = pp_vil.id_player
            JOIN roles r ON pip.id_role = r.id_role
            WHERE r.description_role = 'villageois'
              AND pp_vil.id_turn = @TOUR_ID
              AND pip.id_party = @PARTY_ID
              AND EXISTS (
                SELECT 1
                FROM players_play pp_loup
                JOIN players_in_parties pip2 ON pp_loup.id_player = pip2.id_player
                JOIN roles r2 ON pip2.id_role = r2.id_role
                WHERE pp_loup.id_turn = @TOUR_ID
                  AND pip2.id_party = @PARTY_ID
                  AND r2.description_role = 'loup'
                  AND pp_loup.target_position_row = pp_vil.target_position_row
                  AND pp_loup.target_position_col = pp_vil.target_position_col
              );
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE USERNAME_TO_LOWER
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE players
    SET pseudo = LOWER(pseudo);
END;
GO
<<<<<<< HEAD
=======
    DECLARE @turn_end_time DATETIME;

    -- Récupère l'heure de fin du tour
    SELECT @turn_end_time = end_time
    FROM turns
    WHERE id_turn = @TOUR_ID AND id_party = @PARTY_ID;

    -- Si aucun déplacement n'a été fait après l'heure de fin, on ne fait rien
    IF NOT EXISTS (
        SELECT 1
        FROM players_play
        WHERE id_turn = @TOUR_ID AND end_time > @turn_end_time
    )
    BEGIN
        -- Traitement des demandes de déplacement
        -- 1. Mise à jour des positions dans board_state
        UPDATE bs
        SET
            bs.content_type = 'rien',
            bs.id_player = NULL
        FROM
            board_state bs
        JOIN
            players_play pp ON bs.id_player = pp.id_player
        WHERE
            bs.id_turn = @TOUR_ID
            AND bs.id_party = @PARTY_ID
            AND pp.id_turn = @TOUR_ID
            AND bs.position_col = pp.origin_position_col
            AND bs.position_row = pp.origin_position_row;

        -- 2. Insertion des nouvelles positions
        INSERT INTO board_state (id_party, id_turn, position_col, position_row, content_type, id_player)
=======
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
>>>>>>> eab7d2c841e8387861d4578f6faad93af09fdfaa
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
<<<<<<< HEAD
END;
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
=======
END
GO
>>>>>>> eab7d2c841e8387861d4578f6faad93af09fdfaa
=======
>>>>>>> bf43fd0d893a19ee4a4c965328d1cf9ebb69e322
