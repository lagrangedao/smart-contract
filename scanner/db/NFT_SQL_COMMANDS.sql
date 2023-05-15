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
  `transfer_event_block` INT NOT NULL,
  `nft_address` VARCHAR(100) NOT NULL,
  `nft_ID` INT NULL DEFAULT NULL,
  `owner_address` VARCHAR(100) NOT NULL)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

insert into nft_ownership(transfer_event_block,nft_address,nft_ID,owner_address) VALUES (34492518,'0xD81288579c13e26F621840B66aE16af1460ebB5a',2,'0xA878795d2C93985444f1e2A077FA324d59C759b0');
insert into nft_ownership(transfer_event_block,nft_address,nft_ID,owner_address) VALUES (34492518,'0x923AfAdE5d2c600b8650334af60D6403642c1bce',2,'0xc17ae0520803E715D020C03D29D452520D6aEbf9');