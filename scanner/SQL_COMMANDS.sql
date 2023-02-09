create database HYPERSPACE;

create table HYPERSPACE.depositTransactions( blocknumber INT PRIMARY KEY, event VARCHAR(10) NOT NULL, accountAddress VARCHAR(100) NOT NULL, amount BIGINT, TxHash VARCHAR(1000));