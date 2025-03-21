-- Supprimer les triggers existants s'ils existent
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_COMPLETE_TOUR_ON_TURN_END')
    DROP TRIGGER TR_COMPLETE_TOUR_ON_TURN_END;
GO

-- Trigger pour déclencher COMPLETE_TOUR quand un tour est marqué terminé
CREATE TRIGGER TR_COMPLETE_TOUR_ON_TURN_END
ON turns
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Vérifier si le tour est marqué comme terminé
    IF UPDATE(end_time)
    BEGIN
        DECLARE @TOUR_ID INT;

        -- Récupérer l'ID du tour qui vient d'être mis à jour
        SELECT @TOUR_ID = id_turn
        FROM inserted;

        -- Appeler la procédure COMPLETE_TOUR
        EXEC COMPLETE_TOUR @TOUR_ID;
    END
END
GO

-- Supprimer le trigger USERNAME_TO_LOWER si il existe
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'TR_USERNAME_TO_LOWER_ON_INSERT')
    DROP TRIGGER TR_USERNAME_TO_LOWER_ON_INSERT;
GO

-- Trigger pour déclencher USERNAME_TO_LOWER quand un joueur s'inscrit
CREATE TRIGGER TR_USERNAME_TO_LOWER_ON_INSERT
ON players
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Exécuter la procédure USERNAME_TO_LOWER
    EXEC USERNAME_TO_LOWER;
END
GO