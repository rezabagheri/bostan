-- pdev — initial database setup
-- This file is executed once during the initial MySQL startup

CREATE DATABASE IF NOT EXISTS `pdev`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `pdev_%`.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;