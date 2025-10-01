CREATE TABLE IF NOT EXISTS `player_shops` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `shop_id` VARCHAR(50) NOT NULL,
    `owner_license` VARCHAR(50) NOT NULL,
    `money` INT DEFAULT 0,
    `items` JSON DEFAULT '[]',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner_license`),
    INDEX `idx_shop` (`shop_id`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create table for shop transactions
CREATE TABLE IF NOT EXISTS `shop_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `shop_id` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `amount` INT NOT NULL,
    `price` INT NOT NULL,
    `type` ENUM('buy', 'sell') NOT NULL,
    `buyer_license` VARCHAR(50) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_shop_trans` (`shop_id`),
    INDEX `idx_buyer` (`buyer_license`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 