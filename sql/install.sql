CREATE TABLE IF NOT EXISTS `mining_stats` (
    `player_id` VARCHAR(50) PRIMARY KEY,
    `level` INT NOT NULL DEFAULT 1,
    `experience` INT NOT NULL DEFAULT 0,
    `total_mined` INT NOT NULL DEFAULT 0,
    `total_earned` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `mining_veins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `sub_zone` VARCHAR(64) NOT NULL,
    `ore_type` VARCHAR(64) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `total_quantity` INT NOT NULL DEFAULT 10,
    `remaining` INT NOT NULL DEFAULT 10,
    `quality` INT NOT NULL DEFAULT 50,
    `depleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_veins_subzone` (`sub_zone`),
    INDEX `idx_veins_depleted` (`depleted_at`)
);
