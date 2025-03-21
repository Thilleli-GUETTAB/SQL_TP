<<<<<<< HEAD
=======
-- wv_procs.sql
-- Implémentation des procédures pour le jeu "Les Loups"

-- 1. Procédure SEED_DATA
-- Crée autant de tours de jeu que la partie peut en accepter
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
CREATE PROCEDURE SEED_DATA
    @NB_PLAYERS INT,
    @PARTY_ID INT
AS
BEGIN
<<<<<<< HEAD
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

=======
    DECLARE @nb_tours INT;
    DECLARE @i INT = 1;
    DECLARE @current_time DATETIME = GETDATE();
    DECLARE @tour_duration INT;

    -- Récupère le nombre de tours configuré pour cette partie
    SELECT @nb_tours = nb_turns, @tour_duration = max_wait_time
    FROM party_settings
    WHERE id_party = @PARTY_ID;

    -- Crée les tours
    WHILE @i <= @nb_tours
    BEGIN
        INSERT INTO turns (id_party, start_time, end_time)
        VALUES (@PARTY_ID, @current_time, DATEADD(SECOND, @tour_duration, @current_time));

        -- Met à jour le temps pour le prochain tour
        SET @current_time = DATEADD(SECOND, @tour_duration, @current_time);
        SET @i = @i + 1;
    END;
END;

-- 2. Procédure COMPLETE_TOUR
-- Applique toutes les demandes de déplacement
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
CREATE PROCEDURE COMPLETE_TOUR
    @TOUR_ID INT,
    @PARTY_ID INT
AS
BEGIN
<<<<<<< HEAD
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
        SELECT
            @PARTY_ID,
            @TOUR_ID,
            pp.target_position_col,
            pp.target_position_row,
            CASE
                WHEN r.description_role = 'loup' THEN 'loup'
                ELSE 'villageois'
            END,
            pp.id_player
        FROM
            players_play pp
        JOIN
            players_in_parties pip ON pp.id_player = pip.id_player AND pip.id_party = @PARTY_ID
        JOIN
            roles r ON pip.id_role = r.id_role
        WHERE
            pp.id_turn = @TOUR_ID
            AND pp.action = 'move'
            AND pp.target_position_col IS NOT NULL
            AND pp.target_position_row IS NOT NULL
            AND NOT EXISTS (
                -- Vérifie si la destination n'est pas un obstacle
                SELECT 1
                FROM board_state
                WHERE
                    id_party = @PARTY_ID
                    AND id_turn = @TOUR_ID
                    AND position_col = pp.target_position_col
                    AND position_row = pp.target_position_row
                    AND content_type = 'obstacle'
            );

        -- 3. Traitement des éliminations (villageois sur la même case qu'un loup)
        UPDATE pip
        SET
            pip.is_alive = 0 -- 0 = mort
        FROM
            players_in_parties pip
        JOIN
            roles r ON pip.id_role = r.id_role
        JOIN
            board_state bs ON bs.id_player = pip.id_player
        WHERE
            pip.id_party = @PARTY_ID
            AND bs.id_turn = @TOUR_ID
            AND bs.id_party = @PARTY_ID
            AND r.description_role = 'villageois'
            AND EXISTS (
                -- Vérifie s'il y a un loup sur la même case
                SELECT 1
                FROM board_state bs2
                JOIN players_in_parties pip2 ON bs2.id_player = pip2.id_player
                JOIN roles r2 ON pip2.id_role = r2.id_role
                WHERE
                    bs2.id_party = @PARTY_ID
                    AND bs2.id_turn = @TOUR_ID
                    AND bs2.position_col = bs.position_col
                    AND bs2.position_row = bs.position_row
                    AND r2.description_role = 'loup'
            );
    END;
END;

-- 3. Procédure USERNAME_TO_LOWER
-- Met les noms des joueurs en minuscule
CREATE PROCEDURE USERNAME_TO_LOWER
AS
BEGIN
    UPDATE players
    SET pseudo = LOWER(pseudo);
END;
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
