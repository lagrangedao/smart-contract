-- MySQL Workbench Synchronization
-- Generated: 2023-02-10 15:07
-- Model: New Model
-- Version: 1.0
-- Project: Name of the project
-- Author: Charles Cao

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `lad_block` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;

CREATE TABLE IF NOT EXISTS `lad_block`.`network` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `last_scan_block_number_payment` BIGINT(20) NULL DEFAULT NULL,
  `last_scan_block_number_dao` BIGINT(20) NULL DEFAULT NULL,
  `description` TEXT NULL DEFAULT NULL,
  `created_at` VARCHAR(32) NOT NULL,
  `updated_at` VARCHAR(32) NOT NULL,
  `chain_id` INT(11) NULL DEFAULT NULL,
  `currency` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `un_network_name` (`name` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `lad_block`.`transaction` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `block_number` INT(11) NOT NULL,
  `event` VARCHAR(10) NOT NULL,
  `account_address` VARCHAR(100) NOT NULL,
  `recipient_address` VARCHAR(100) NOT NULL,
  `amount` BIGINT(20) NULL DEFAULT NULL,
  `tx_hash` VARCHAR(1000) NULL DEFAULT NULL,
  `created_at` VARCHAR(32) NULL DEFAULT NULL,
  `updated_at` VARCHAR(32) NULL DEFAULT NULL,
  `contract_id` INT(11) NOT NULL,
  `coin_id` INT(11) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_transactions_contract_idx` (`contract_id` ASC) VISIBLE,
  INDEX `fk_transaction_coin1_idx` (`coin_id` ASC) VISIBLE,
  CONSTRAINT `fk_transactions_contract`
    FOREIGN KEY (`contract_id`)
    REFERENCES `lad_block`.`contract` (`id`),
  CONSTRAINT `fk_transaction_coin1`
    FOREIGN KEY (`coin_id`)
    REFERENCES `lad_block`.`coin` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `lad_block`.`coin` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `parent_id` INT(11) NULL DEFAULT NULL COMMENT '父币id',
  `type` INT(11) NULL DEFAULT NULL COMMENT '币种类型：1 ETH 2 BTC 3 EHT_TOKEN',
  `image` VARCHAR(255) NULL DEFAULT NULL COMMENT '图标',
  `short_name` VARCHAR(255) NOT NULL COMMENT '英文简称',
  `full_name` VARCHAR(255) NOT NULL COMMENT '英文全称',
  `cn_name` VARCHAR(255) NOT NULL COMMENT '中文名',
  `decimals` SMALLINT(6) NULL DEFAULT NULL COMMENT '小数位',
  `contract_address` VARCHAR(255) NULL DEFAULT NULL COMMENT '合约地址',
  `method_id` VARCHAR(255) NULL DEFAULT NULL COMMENT '合约转账方法id',
  `server_ip` VARCHAR(255) NULL DEFAULT NULL COMMENT '服务器ip',
  `server_port` INT(11) NULL DEFAULT NULL COMMENT '服务器rpc端口',
  `main_address` VARCHAR(255) NULL DEFAULT NULL COMMENT '平台主地址',
  `main_address_password` VARCHAR(255) NULL DEFAULT NULL COMMENT '平台主地址密码',
  `gas_price` INT(11) NULL DEFAULT '0' COMMENT '单位Gwei',
  `gas_limit` INT(11) NULL DEFAULT '0' COMMENT '最大确认数',
  `cold_address` VARCHAR(255) NULL DEFAULT NULL COMMENT '冷钱包地址',
  `out_qty_to_cold_address` DECIMAL(50,18) NULL DEFAULT NULL COMMENT '超过多少数量转入冷钱包',
  `allow_recharge` INT(11) NULL DEFAULT '0' COMMENT '允许充值 0：否 1：是',
  `allow_withdraw` INT(11) NULL DEFAULT '0' COMMENT '允许提币 0：否 1：是',
  `withdraw_fee` DECIMAL(50,18) NOT NULL COMMENT '转出手续费',
  `max_out_qty` DECIMAL(50,18) NOT NULL COMMENT '提币最大限制',
  `min_out_qty` DECIMAL(50,18) NOT NULL COMMENT '提币最小限制',
  `warning_qty` DECIMAL(50,18) NULL DEFAULT NULL COMMENT '预警值（低于这个值，短信通知）',
  `out_qty_to_main_address` DECIMAL(50,18) NULL DEFAULT NULL COMMENT '超过多少传入平台主地址',
  `cn_description` LONGTEXT NULL DEFAULT NULL COMMENT '中文描述',
  `en_description` LONGTEXT NULL DEFAULT NULL COMMENT '英文描述',
  `server_username` VARCHAR(255) NULL DEFAULT NULL COMMENT 'btc-帐户名',
  `server_password` VARCHAR(255) NULL DEFAULT NULL COMMENT 'btc-帐户密码',
  `propertyid` INT(11) NULL DEFAULT NULL COMMENT 'Omni-token唯一标识',
  `allow_otc` INT(11) NOT NULL DEFAULT '0',
  `create_time_str` VARCHAR(32) NULL DEFAULT NULL,
  `update_time_str` VARCHAR(32) NULL DEFAULT NULL,
  `currency_id` INT(11) NULL DEFAULT NULL,
  `fix_rate` DECIMAL(50,18) NULL DEFAULT NULL COMMENT '固定汇率换算',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci
COMMENT = '数字货币表';

CREATE TABLE IF NOT EXISTS `lad_block`.`contract` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NULL DEFAULT NULL,
  `contract_address` VARCHAR(45) NOT NULL,
  `network_id` BIGINT(20) NOT NULL,
  `created_at` VARCHAR(32) NOT NULL,
  `updated_at` VARCHAR(32) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_contract_network1_idx` (`network_id` ASC) VISIBLE,
  CONSTRAINT `fk_contract_network1`
    FOREIGN KEY (`network_id`)
    REFERENCES `lad_block`.`network` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
