-- Create the database if not exists
CREATE DATABASE IF NOT EXISTS appdb;

-- Create user if not exists
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'apppassword';

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';

-- Grant additional privileges if needed
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'appuser'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Use the database
USE appdb;

-- Tables could be created here if needed
-- CREATE TABLE IF NOT EXISTS users (...);