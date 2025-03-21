<<<<<<< HEAD
-- wv_funcs.sql
-- Implémentation des fonctions pour le jeu "Les Loups"

-- 1. Fonction random_position()
-- Renvoie un couple aléatoire qui n'a jamais été choisi pour une partie donnée
CREATE FUNCTION random_position(@nb_rows INT, @nb_cols INT, @id_party INT)
=======
CREATE FUNCTION random_position(
    @id_party INT
    -- @nb_lignes INT,
    -- @nb_colonnes INT,
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
)
>>>>>>> 473b32d (Remove unused parameters from random_position and random_role functions in wv_funcs.sql)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        col, row
    FROM
    (
        -- Génère toutes les combinaisons possibles de colonnes et lignes
        SELECT 
<<<<<<< HEAD
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
=======
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
>>>>>>> b925579fdb8adc5bccaca877b3da8821f3791e13
    )
    ORDER BY NEWID() -- Ordre aléatoire
);

-- 2. Fonction random_role()
-- Renvoie le prochain rôle à affecter au joueur en cours d'inscription
CREATE FUNCTION random_role(@id_party INT)
RETURNS INT
AS
BEGIN
    DECLARE @id_role_loup INT;
    DECLARE @id_role_villageois INT;
    DECLARE @count_loup INT;
    DECLARE @count_villageois INT;
    DECLARE @max_players INT;
    DECLARE @total_players INT;
    DECLARE @result INT;

    -- Récupère les IDs des rôles
    SELECT @id_role_loup = id_role FROM roles WHERE description_role = 'loup';
    SELECT @id_role_villageois = id_role FROM roles WHERE description_role = 'villageois';

    -- Récupère le nombre maximum de joueurs pour cette partie
    SELECT @max_players = max_players FROM party_settings WHERE id_party = @id_party;

    -- Compte le nombre de loups et de villageois déjà dans la partie
    SELECT @count_loup = COUNT(*) 
    FROM players_in_parties 
    WHERE id_party = @id_party AND id_role = @id_role_loup;

    SELECT @count_villageois = COUNT(*) 
    FROM players_in_parties 
    WHERE id_party = @id_party AND id_role = @id_role_villageois;

    -- Nombre total de joueurs inscrits
    SET @total_players = @count_loup + @count_villageois;

    -- Si le nombre maximum de joueurs est atteint, retourne NULL (erreur)
    IF @total_players >= @max_players
        RETURN NULL;

    -- Définit un ratio: environ 1 loup pour 4 joueurs
    IF @count_loup * 4 <= @total_players
        SET @result = @id_role_loup;
    ELSE
        SET @result = @id_role_villageois;

    RETURN @result;
END;

-- 3. Fonction get_the_winner()
-- Renvoie les informations sur le vainqueur de la partie
CREATE FUNCTION get_the_winner(@partyid INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        p.pseudo AS 'nom du joueur',
        r.description_role AS 'role parmi loup et villageois',
        pa.title_party AS 'nom de la partie',
        COUNT(DISTINCT pp.id_turn) AS 'nb de tours joués par le joueur',
        (SELECT COUNT(*) FROM turns WHERE id_party = @partyid) AS 'nb total de tours de la partie',
        AVG(DATEDIFF(SECOND, t.start_time, pp.end_time)) AS 'temps moyen de prise de décision du joueur'
    FROM 
        players p
    JOIN 
        players_in_parties pip ON p.id_player = pip.id_player
    JOIN 
        roles r ON pip.id_role = r.id_role
    JOIN 
        players_play pp ON p.id_player = pp.id_player
    JOIN 
        turns t ON pp.id_turn = t.id_turn AND t.id_party = pip.id_party
    JOIN 
        parties pa ON pip.id_party = pa.id_party
    WHERE 
        pip.id_party = @partyid
        AND 
        (
            (r.description_role = 'loup' AND NOT EXISTS (
                SELECT 1 FROM players_in_parties 
                WHERE id_party = @partyid AND id_role = (SELECT id_role FROM roles WHERE description_role = 'villageois') AND is_alive = 1
            ))
            OR
            (r.description_role = 'villageois' AND pip.is_alive = 1 AND 
                (SELECT COUNT(*) FROM turns WHERE id_party = @partyid) = (SELECT nb_turns FROM party_settings WHERE id_party = @partyid)
            )
        )
    GROUP BY 
        p.pseudo, r.description_role, pa.title_party
    ORDER BY 
        -- Prioriser les loups s'ils ont gagné, sinon le villageois qui a survécu
        CASE WHEN r.description_role = 'loup' THEN 0 ELSE 1 END,
        -- Si plusieurs gagnants du même rôle, prendre celui qui a joué le plus de tours
        'nb de tours joués par le joueur' DESC
);