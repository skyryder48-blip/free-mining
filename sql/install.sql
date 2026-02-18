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

-- Phase 7: Contracts & Rare Finds

CREATE TABLE IF NOT EXISTS `mining_contracts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `contract_type` VARCHAR(64) NOT NULL,
    `tier` VARCHAR(16) NOT NULL DEFAULT 'easy',
    `label` VARCHAR(255) NOT NULL,
    `target` INT NOT NULL DEFAULT 1,
    `progress` INT NOT NULL DEFAULT 0,
    `extra_data` VARCHAR(128) NULL DEFAULT NULL,
    `status` ENUM('active', 'completed', 'expired') NOT NULL DEFAULT 'active',
    `accepted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    `expires_at` TIMESTAMP NOT NULL,
    INDEX `idx_contracts_player` (`player_id`),
    INDEX `idx_contracts_status` (`player_id`, `status`),
    INDEX `idx_contracts_expires` (`expires_at`)
);

CREATE TABLE IF NOT EXISTS `mining_discoveries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `zone` VARCHAR(64) NULL DEFAULT NULL,
    `sell_bonus_until` TIMESTAMP NULL DEFAULT NULL,
    `discovered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_discoveries_player` (`player_id`),
    INDEX `idx_discoveries_recent` (`discovered_at`)
);

-- Phase 9: Progression & Specialization

ALTER TABLE `mining_stats` ADD COLUMN `specialization` VARCHAR(32) NULL DEFAULT NULL;
ALTER TABLE `mining_stats` ADD COLUMN `prestige` INT NOT NULL DEFAULT 0;
ALTER TABLE `mining_stats` ADD COLUMN `skill_points_spent` INT NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `mining_skills` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `skill_key` VARCHAR(64) NOT NULL,
    `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_player_skill` (`player_id`, `skill_key`),
    INDEX `idx_skills_player` (`player_id`)
);

CREATE TABLE IF NOT EXISTS `mining_achievements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `achievement_key` VARCHAR(64) NOT NULL,
    `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_player_achievement` (`player_id`, `achievement_key`),
    INDEX `idx_achievements_player` (`player_id`)
);

CREATE TABLE IF NOT EXISTS `mining_counters` (
    `player_id` VARCHAR(50) NOT NULL,
    `counter_key` VARCHAR(64) NOT NULL,
    `value` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`player_id`, `counter_key`)
);
