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
    transfer_event_block = Column(Integer)
    owner_address = Column(String)
    nft_address = Column(String)
    nft_ID = Column(Integer)

class NFTContractDetails(Base):
    __tablename__='nft_contract_details'
    id = Column(Integer, primary_key=True)
    last_scan_block = Column(Integer)
    NFT_contract_address = Column(String)
    owner_address = Column(String)

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
        self.engine = create_engine('mysql+mysqlconnector://' + config('DB_USER') + ':' + config('DB_PASSWORD') + '@localhost/nft_data')
        Session = sessionmaker(bind=self.engine)
        self.session = Session()

        self.w3 = Web3(Web3.HTTPProvider(polygon_url))
        self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        self.cf_abi = json.load(open(self.cf_abi_file_path))
        self.so_abi = json.load(open(self.so_abi_file_path))
        
        try:
            lastScannedBlock = self.session.query(NFTContractDetails.last_scan_block).first()
        except Exception as e:
            logging.error("Error fetching the last_scan_block: ",e)
        finally:
            self.session.close()
        # print("lastScannedBlock: ",lastScannedBlock[0])

        if lastScannedBlock:
            self.from_block = lastScannedBlock[0] + 1
        else:
            # Block at which the contracts were deployed
            self.from_block = 34333512

        self.batch_size = 1000

    # Function to update the ownership of the NFT or insert a newly minted NFT
    def update_or_insert_nft(self, blockNumber, to, contract_address, token_id):
        try:
            Session = sessionmaker(bind=self.engine)
            self.session = Session()
        except Exception as e:
            logging.error("Error creating a new session: ",e)

        try:
            nft_ownership = self.session.query(NFTData).filter_by(nft_address=contract_address, nft_ID=token_id).first()

            if nft_ownership:
                # Update the NFT details
                nft_ownership.transfer_event_block = blockNumber
                nft_ownership.owner_address = to
            else:
                # Insert new NFT details
                nft_ownership = NFTData(
                    transfer_event_block=blockNumber,
                    owner_address=to,
                    nft_address=contract_address,
                    nft_ID=token_id
                )

            self.session.add(nft_ownership)
            self.session.commit()
            return True
        except Exception as e:
            logging.error("Error updating NFT ownership: ", e)
            return False
        finally:
            self.session.close()

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
                        # When a `transfer` event occurs
                        token_id = cf_transfer_events[i].args.tokenId
                        
                        try:
                            self.update_or_insert_nft(cf_transfer_events[i].blockNumber,
                            cf_transfer_events[i].args.to,
                            self.cf_contract_address,
                            token_id)
                        except Exception as e:
                            logging.error("Error updating the NFT details: ",e)

                    elif cf_transfer_events[i].args["from"] == '0x0000000000000000000000000000000000000000':
                        # When a new NFT is minted
                        try:
                            self.update_or_insert_nft(cf_transfer_events[i].blockNumber,
                            cf_transfer_events[i].args.to,
                            self.cf_contract_address,
                            token_id)
                        except Exception as e:
                            logging.error("Error inserting the NFT details: ",e)

                    i=i+1

            # Scan for contract with single oracle events
            if so_transfer_events:
                so_event_size = len(so_transfer_events)
                i = 0

                while i < so_event_size:
                    token_id = so_transfer_events[i].args.tokenId

                    if so_transfer_events[i].args["from"] != '0x0000000000000000000000000000000000000000':
                        # When a `transfer` event occurs
                        try:
                            self.update_or_insert_nft(so_transfer_events[i].blockNumber,
                            so_transfer_events[i].args.to,
                            self.so_contract_address,
                            token_id)
                        except Exception as e:
                            logging.error("Error updating the NFT details: ",e)

                    elif so_transfer_events[i].args["from"] == '0x0000000000000000000000000000000000000000':
                        # When a new NFT is minted
                        try:
                            self.update_or_insert_nft(so_transfer_events[i].blockNumber,
                            so_transfer_events[i].args.to,
                            self.so_contract_address,
                            token_id)
                        except Exception as e:
                            logging.error("Error inserting the NFT details: ",e)                

                    i=i+1

            self.from_block = self.from_block + self.batch_size + 1
            blockDiff = target_block - self.from_block

            if(blockDiff < self.batch_size):
                batchSize = blockDiff

        # Update last scanned block
        try:
            Session = sessionmaker(bind=self.engine)
            self.session = Session()
            self.session.query(NFTContractDetails).update({'last_scan_block': target_block})
            self.session.commit()
        except Exception as e:
            logging.error("Error updating the last_scan_block: ",e)
        finally:
            self.session.close()

def main():
    # Configurable parameters:
    try:
        cf_contract_addr=config('CF_CONTRACT_ADDRESS')
        so_contract_addr=config('SO_CONTRACT_ADDRESS')
    except Exception as e:
        logging.error("Please check address configuration: ",e)

    # Start scanner:
    try:
        scanner_0bj = NFTScanner(cf_contract_addr,so_contract_addr)
        target_block = scanner_0bj.w3.eth.get_block('latest')
        scanner_0bj.start_NFT_scan(target_block.number)
    except Exception as e:
        logging.error("Error while starting the scan script: ", e)

if __name__ == '__main__':
    main()