-- 1. D'abord, rendons les colonnes NOT NULL une par une
-- Pour la table parties
ALTER TABLE parties ALTER COLUMN id_party INT NOT NULL;

-- Pour la table roles
ALTER TABLE roles ALTER COLUMN id_role INT NOT NULL;

-- Pour la table players
ALTER TABLE players ALTER COLUMN id_player INT NOT NULL;

-- Pour la table players_in_parties
ALTER TABLE players_in_parties ALTER COLUMN id_party INT NOT NULL;
ALTER TABLE players_in_parties ALTER COLUMN id_player INT NOT NULL;
ALTER TABLE players_in_parties ALTER COLUMN id_role INT NOT NULL;

-- Pour la table turns
ALTER TABLE turns ALTER COLUMN id_turn INT NOT NULL;
ALTER TABLE turns ALTER COLUMN id_party INT NOT NULL;

-- Pour la table players_play
ALTER TABLE players_play ALTER COLUMN id_player INT NOT NULL;
ALTER TABLE players_play ALTER COLUMN id_turn INT NOT NULL;

-- 2. Maintenant, ajoutons les clés primaires
ALTER TABLE parties ADD CONSTRAINT PK_parties PRIMARY KEY (id_party);
ALTER TABLE roles ADD CONSTRAINT PK_roles PRIMARY KEY (id_role);
ALTER TABLE players ADD CONSTRAINT PK_players PRIMARY KEY (id_player);
ALTER TABLE players_in_parties ADD CONSTRAINT PK_players_in_parties PRIMARY KEY (id_party, id_player);
ALTER TABLE turns ADD CONSTRAINT PK_turns PRIMARY KEY (id_turn, id_party);
ALTER TABLE players_play ADD CONSTRAINT PK_players_play PRIMARY KEY (id_player, id_turn);

-- 3. Ajout des clés étrangères
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_parties
    FOREIGN KEY (id_party) REFERENCES parties(id_party);
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_players
    FOREIGN KEY (id_player) REFERENCES players(id_player);
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_roles
    FOREIGN KEY (id_role) REFERENCES roles(id_role);

ALTER TABLE turns ADD CONSTRAINT FK_turns_parties
    FOREIGN KEY (id_party) REFERENCES parties(id_party);

ALTER TABLE players_play ADD CONSTRAINT FK_players_play_players
    FOREIGN KEY (id_player) REFERENCES players(id_player);
ALTER TABLE players_play ADD CONSTRAINT FK_players_play_turns
    FOREIGN KEY (id_turn) REFERENCES turns(id_turn);

-- 4. Améliorations des types de données
-- Pour la table parties
ALTER TABLE parties ALTER COLUMN title_party VARCHAR(255) NOT NULL;

-- Pour la table roles
ALTER TABLE roles ALTER COLUMN description_role VARCHAR(50) NOT NULL;

-- Pour la table players
ALTER TABLE players ALTER COLUMN pseudo VARCHAR(100) NOT NULL;

-- Pour la table players_in_parties
ALTER TABLE players_in_parties ALTER COLUMN is_alive VARCHAR(1) NOT NULL;

-- Pour la table players_play
-- Conversion de text à INT nécessite une étape intermédiaire
ALTER TABLE players_play ALTER COLUMN origin_position_col VARCHAR(20);
ALTER TABLE players_play ALTER COLUMN origin_position_col INT;

ALTER TABLE players_play ALTER COLUMN origin_position_row VARCHAR(20);
ALTER TABLE players_play ALTER COLUMN origin_position_row INT;

ALTER TABLE players_play ALTER COLUMN target_position_col VARCHAR(20);
ALTER TABLE players_play ALTER COLUMN target_position_col INT;

ALTER TABLE players_play ALTER COLUMN target_position_row VARCHAR(20);
ALTER TABLE players_play ALTER COLUMN target_position_row INT;

-- 5. Contraintes métier
ALTER TABLE roles ADD CONSTRAINT CHK_roles_description
    CHECK (description_role IN ('loup', 'villageois'));

-- 6. Index pour optimiser les requêtes
CREATE INDEX IDX_players_in_parties_role ON players_in_parties(id_role);
CREATE INDEX IDX_turns_party ON turns(id_party);
CREATE INDEX IDX_players_play_turn ON players_play(id_turn);

-- 7. Tables supplémentaires nécessaires pour le jeu
-- Table pour les paramètres de jeu
CREATE TABLE party_settings (
    id_party INT NOT NULL,
    nb_rows INT NOT NULL,
    nb_cols INT NOT NULL,
    max_wait_time INT NOT NULL, -- en secondes
    nb_turns INT NOT NULL,
    nb_obstacles INT NOT NULL,
    max_players INT NOT NULL,
    CONSTRAINT PK_party_settings PRIMARY KEY (id_party),
    CONSTRAINT FK_party_settings_parties FOREIGN KEY (id_party) REFERENCES parties(id_party)
);

-- Table pour les obstacles
CREATE TABLE obstacles (
    id_obstacle INT NOT NULL,
    id_party INT NOT NULL,
    position_col INT NOT NULL,
    position_row INT NOT NULL,
    CONSTRAINT PK_obstacles PRIMARY KEY (id_obstacle),
    CONSTRAINT FK_obstacles_parties FOREIGN KEY (id_party) REFERENCES parties(id_party),
    CONSTRAINT UQ_obstacle_position UNIQUE (id_party, position_col, position_row)
);

-- Table pour l'état du plateau
CREATE TABLE board_state (
    id_party INT NOT NULL,
    id_turn INT NOT NULL,
    position_col INT NOT NULL,
    position_row INT NOT NULL,
    content_type VARCHAR(10) NOT NULL, -- 'rien', 'villageois', 'loup', 'obstacle'
    id_player INT NULL,
    CONSTRAINT PK_board_state PRIMARY KEY (id_party, id_turn, position_col, position_row),
    CONSTRAINT FK_board_state_parties FOREIGN KEY (id_party) REFERENCES parties(id_party),
    CONSTRAINT FK_board_state_turns FOREIGN KEY (id_turn, id_party) REFERENCES turns(id_turn, id_party),
    CONSTRAINT FK_board_state_players FOREIGN KEY (id_player) REFERENCES players(id_player)
);

-- 8. Contraintes d'unicité
ALTER TABLE players ADD CONSTRAINT UQ_players_pseudo UNIQUE (pseudo);
ALTER TABLE parties ADD CONSTRAINT UQ_parties_title UNIQUE (title_party);