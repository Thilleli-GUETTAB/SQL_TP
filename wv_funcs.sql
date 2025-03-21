CREATE FUNCTION random_position(
    @nb_lignes INT,
    @nb_colonnes INT,
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
    @id_party INT,
    @max_wolves INT
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
)
RETURNS TABLE
AS
RETURN
(
    WITH PlayerStats AS (
        SELECT 
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
    )
    SELECT TOP 1 *
    FROM PlayerStats
    ORDER BY avg_decision_time
);
GO
