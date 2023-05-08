-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema nft_data
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema nft_data
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `nft_data` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `nft_data` ;

-- -----------------------------------------------------
-- Table `nft_data`.`nft_ownership`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `nft_data`.`nft_ownership` (
  `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `last_scan_block` INT NOT NULL,
  `transfer_event_block` INT(50) NOT NULL,
  `nft_address` VARCHAR(200) NOT NULL,
  `nft_ID` INT(50) NULL DEFAULT NULL,
  `owner_address` VARCHAR(200) NOT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;