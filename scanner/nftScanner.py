from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings
import logging

# set up logging to file
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M')
# define a Handler which writes INFO messages or higher to the sys.stderr
console = logging.StreamHandler()
console.setLevel(logging.INFO)
# add the handler to the root logger
logging.getLogger('').addHandler(console)

polygon_url = config('POLYGON_URL')

Base = declarative_base()

class NFTData(Base):
    __tablename__ = 'nft_ownership'
    id = Column(Integer, primary_key=True)
    last_scan_block = Column(Integer)
    transfer_event_block = Column(Integer)
    owner_address = Column(String)
    nft_address = Column(String)
    nft_ID = Column(Integer)

engine = create_engine('mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}')
Session = sessionmaker(bind=engine)

class NFTScanner:
    def __init__(self, cf_contract_address, so_contract_address):
        # Data NFT with Chainlink functions contract address
        self.cf_contract_address = cf_contract_address
        # Data NFT with single oracle contract address
        self.so_contract_address = so_contract_address
        # Data NFT with Chainlink functions contract ABI
        self.cf_abi_file_path = '../contracts/abi/LagrangeChainlinkData.json'
        # Data NFT with single oracle contract ABI
        self.so_abi_file_path = '../contracts/abi/LagrangeChainlinkDataConsumer.json'

        # DB connection
        # self.mydb = mysql.connector.connect(
        #     host="localhost",
        #     user=config('DB_USER'),
        #     password=config('DB_PASSWORD'),
        #     database='nft_data'
        # )

        # DB connection
        self.engine = create_engine('mysql+mysqlconnector://' + config('DB_USER') + ':' + config('DB_PASSWORD') + '@localhost/nft_data')
        Session = sessionmaker(bind=self.engine)
        self.session = Session()

        self.w3 = Web3(Web3.HTTPProvider(polygon_url))
        self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        self.cf_abi = json.load(open(self.cf_abi_file_path))
        self.so_abi = json.load(open(self.so_abi_file_path))
        # self.mycursor = self.mydb.cursor()

        # getLastScanBlockCommand= 'select last_scan_block from nft_ownership'
        # self.mycursor.execute(getLastScanBlockCommand)
        # lastScannedBlock = self.mycursor.fetchall()

        # if lastScannedBlock:
        #     self.from_block = lastScannedBlock[0][0] + 1
        # else:
        #     # Block at which the contracts were deployed
        #     self.from_block = 34333512
        lastScannedBlock = self.session.query(NFTData.last_scan_block).first()
        print("lastScannedBlock: ",lastScannedBlock[0])

        if lastScannedBlock:
            self.from_block = lastScannedBlock[0] + 1
        else:
            # Block at which the contracts were deployed
            self.from_block = 34333512

        self.batch_size = 1000

        self.session = Session()
        # print("lastScannedBlock: ",lastScannedBlock[0][0])

        # Update owner command
        self.update_owner_command = 'UPDATE nft_ownership SET transfer_event_block = (%s), owner_address = (%s) WHERE nft_address = (%s) AND nft_ID=(%s)'
        # self.update_owner_command = self.session.query(NFT).filter_by(nft_address=self.cf_contract_address, nft_ID=token_id).first()
        # Is NFT exists check
        self.is_nft_exists_command = 'SELECT * from nft_ownership WHERE nft_address = (%s) AND nft_ID=(%s)'
        # Insert new NFT command:
        self.insert_NFT_command = 'INSERT INTO nft_ownership (last_scan_block,transfer_event_block,owner_address,nft_address,nft_ID) VALUES (%s,%s,%s,%s,%s)'

    def update_ow ner_command(self, blockNumber, to, cf_contract_address, token_id):
        try:
            nft_ownership = self.session.query(NFTOwnership).filter_by(nft_address=cf_contract_address, nft_ID=token_id).first()
            if nft_ownership:
                nft_ownership.transfer_event_block = blockNumber
                nft_ownership.owner_address = to
            else:
                nft_ownership = NFTOwnership(
                    last_scan_block=self.from_block,
                    transfer_event_block=blockNumber,
                    owner_address=to,
                    nft_address=cf_contract_address,
                    nft_ID=token_id
                )
                self.session.add(nft_ownership)
            self.session.commit()
            return True
        except SQLAlchemyError as e:
            print("Error updating NFT ownership: ", e)
            self.session.rollback()
            return False

    def start_NFT_scan(self, target_block):
        while self.from_block < target_block:
            warnings.filterwarnings("ignore")

            to_block = self.from_block + self.batch_size
            # logging.info(f"scanning from {self.from_block} to {target_block}")

            cf_contract = self.w3.eth.contract(address=Web3.toChecksumAddress(self.cf_contract_address), abi=self.cf_abi)
            so_contract = self.w3.eth.contract(address=Web3.toChecksumAddress(self.so_contract_address), abi=self.so_abi)

            cf_transfer_events = cf_contract.events.Transfer.getLogs(fromBlock=self.from_block, toBlock=to_block)
            so_transfer_events = so_contract.events.Transfer.getLogs(fromBlock=self.from_block, toBlock=to_block)
            
            # Scan for contract with Chainlink functions events
            if cf_transfer_events:
                cf_event_size = len(cf_transfer_events)
                i = 0

                while i < cf_event_size:
                    token_id = cf_transfer_events[i].args.tokenId

                    if cf_transfer_events[i].args["from"] != '0x0000000000000000000000000000000000000000':

                        token_id = cf_transfer_events[i].args.tokenId

                        nft_check_params = (self.cf_contract_address, token_id)

                        self.mycursor.execute(self.is_nft_exists_command, nft_check_params)
                        nft_exists_check = self.mycursor.fetchall()

                        if nft_exists_check:
                            cf_update_params = [
                                cf_transfer_events[i].blockNumber,
                                cf_transfer_events[i].args.to,
                                self.cf_contract_address,
                                token_id
                            ]

                            try:
                                self.mycursor.execute(self.update_owner_command, cf_update_params)
                                self.mydb.commit()
                                # TODO: remove this afterwards
                                logging.info(f"Updated owner for NFT Address: {self.cf_contract_address} at {cf_transfer_events[i].blockNumber}")
                            except e:
                                logging.info(f"An error occurred while updating owner for NFT Address {CF_CONTRACT_ADDRESS}: {e}")
                        # else:
                        #     logging.info(f"Following NFT address does not exist in the DB: {CF_CONTRACT_ADDRESS}")

                    elif cf_transfer_events[i].args["from"] == '0x0000000000000000000000000000000000000000':
                        # if "from" address = address(0) => new NFT has been minted
                        # check if new minted NFT exists in the DB

                        new_minted_nft_check_params = (self.cf_contract_address, token_id)
                        self.mycursor.execute(self.is_nft_exists_command, new_minted_nft_check_params)
                        minted_nft_exists_check = self.mycursor.fetchall()

                        if not minted_nft_exists_check:
                            # Insert the newly minted NFT into DB:
                            cf_insert_params = [
                                target_block,
                                cf_transfer_events[i].blockNumber,
                                cf_transfer_events[i].args.to,
                                self.cf_contract_address,
                                token_id
                            ]
                            
                            try:
                                self.mycursor.execute(self.insert_NFT_command, cf_insert_params)
                                self.mydb.commit()
                                logging.info(f"Inserted NFT details for: {self.cf_contract_address} at {cf_transfer_events[i].blockNumber}")
                            except e:
                                logging.info(f"An error occurred while insering details for NFT Address {CF_CONTRACT_ADDRESS}: {e}")  

                    i=i+1

            # Scan for contract with single oracle events
            if so_transfer_events:
                so_event_size = len(so_transfer_events)
                i = 0

                while i < so_event_size:
                    token_id = so_transfer_events[i].args.tokenId

                    if so_transfer_events[i].args["from"] != '0x0000000000000000000000000000000000000000':

                        nft_check_params = (self.so_contract_address, token_id)

                        self.mycursor.execute(self.is_nft_exists_command, nft_check_params)
                        nft_exists_check = self.mycursor.fetchall()

                        if nft_exists_check:
                            so_update_params = [
                                so_transfer_events[i].blockNumber,
                                so_transfer_events[i].args.to,
                                self.so_contract_address,
                                token_id
                            ]

                            try:
                                self.mycursor.execute(self.update_owner_command, so_update_params)
                                self.mydb.commit()
                                logging.info(f"Updated NFT details for: {self.so_contract_address} at {so_transfer_events[i].blockNumber}")
                            except e:
                                logging.info(f"An error occurred while updating NFT details for address {SO_CONTRACT_ADDRESS}: {e}")
                        # else:
                        #     logging.info(f"Following NFT address does not exist in the DB: {SO_CONTRACT_ADDRESS}")

                    elif so_transfer_events[i].args["from"] == '0x0000000000000000000000000000000000000000':
                        # if "from" address = address(0) => new NFT has been minted
                        # check if new minted NFT exists in the DB

                        new_minted_nft_check_params = (self.so_contract_address, token_id)
                        self.mycursor.execute(self.is_nft_exists_command, new_minted_nft_check_params)
                        minted_nft_exists_check = self.mycursor.fetchall()

                        if not minted_nft_exists_check:
                            # Insert the newly minted NFT into DB:
                            so_insert_params = [
                                target_block,
                                so_transfer_events[i].blockNumber,
                                so_transfer_events[i].args.to,
                                self.so_contract_address,
                                token_id
                            ]
                            
                            try:
                                self.mycursor.execute(self.insert_NFT_command, so_insert_params)
                                self.mydb.commit()
                                logging.info(f"Inserted NFT details for: {self.so_contract_address} at {so_transfer_events[i].blockNumber}")
                            except e:
                                logging.info(f"An error occurred while inserting NFT details for address {SO_CONTRACT_ADDRESS}: {e}")                        

                    i=i+1

            self.from_block = self.from_block + self.batch_size + 1
            blockDiff = target_block - self.from_block

            if(blockDiff < self.batch_size):
                batchSize = blockDiff

        # Update last scanned block
        updateLastBlockCMD = 'UPDATE nft_ownership SET last_scan_block = (%s)'
        self.mycursor.execute(updateLastBlockCMD,[target_block])
        self.mydb.commit()

def main():
    # Configurable parameters:
    cf_contract_addr='0xD81288579c13e26F621840B66aE16af1460ebB5a'
    so_contract_addr='0x923AfAdE5d2c600b8650334af60D6403642c1bce'

    # Start scanner:
    scanner_0bj = NFTScanner(cf_contract_addr,so_contract_addr)
    target_block = scanner_0bj.w3.eth.get_block('latest')
    scanner_0bj.start_NFT_scan(target_block.number)

if __name__ == '__main__':
    main()