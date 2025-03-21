-- Pour chaque table, nous allons simplement modifier les colonnes pour être NOT NULL
ALTER TABLE parties
ALTER COLUMN title_party NVARCHAR(255) NOT NULL;

ALTER TABLE roles
ALTER COLUMN description_role NVARCHAR(255) NOT NULL;

ALTER TABLE players
ALTER COLUMN pseudo NVARCHAR(100) NOT NULL;

ALTER TABLE players_in_parties
ALTER COLUMN is_alive NVARCHAR(10) NOT NULL;

ALTER TABLE players_play
ALTER COLUMN action NVARCHAR(10) NOT NULL;