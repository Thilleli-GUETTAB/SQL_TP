-- wv_triggers.sql
-- Implémentation des triggers pour le jeu "Les Loups"

-- 1. Trigger pour déclencher COMPLETE_TOUR quand un tour est marqué terminé
CREATE TRIGGER trg_tour_completed
ON turns
AFTER UPDATE
AS
BEGIN
    -- Vérifie si le end_time a été mis à jour
    IF UPDATE(end_time)
    BEGIN
        DECLARE @tour_id INT;
        DECLARE @party_id INT;

        -- Récupère les tours qui viennent d'être terminés
        SELECT @tour_id = i.id_turn, @party_id = i.id_party
        FROM inserted i
        JOIN deleted d ON i.id_turn = d.id_turn AND i.id_party = d.id_party
        WHERE i.end_time IS NOT NULL AND (d.end_time IS NULL OR i.end_time <> d.end_time);

        -- Exécute la procédure pour chaque tour terminé
        IF @tour_id IS NOT NULL
        BEGIN
            EXEC COMPLETE_TOUR @tour_id, @party_id;
        END;
    END;
END;

-- 2. Trigger pour déclencher USERNAME_TO_LOWER quand un joueur s'inscrit
CREATE TRIGGER trg_player_registered
ON players
AFTER INSERT
AS
BEGIN
    EXEC USERNAME_TO_LOWER;
END;