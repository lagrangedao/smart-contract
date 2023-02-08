create database HYPERSPACE;

create table HYPERSPACE.depositTransactions( blocknumber INT, event VARCHAR(10) NOT NULL, accountAddress VARCHAR(100) NOT NULL, amount BIGINT, TxHash VARCHAR(1000));

INSERT INTO depositTransactions(blocknumber,event,accountAddress,amount,TxHash) VALUES (53314,"Deposit","0xA878795d2C93985444f1e2A077FA324d59C759b0",5000000000000000000,"0x1a2a4b9999b0093d60936522b223d95dd235c5f49731f4b5f1cad9e3ce80d8c8");
