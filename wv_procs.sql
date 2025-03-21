CREATE PROCEDURE SEED_DATA
    @NB_PLAYERS INT,
    @PARTY_ID INT
AS
BEGIN
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
