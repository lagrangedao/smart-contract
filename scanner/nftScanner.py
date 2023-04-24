from web3 import Web3
from decouple import config
from web3.middleware import geth_poa_middleware
from web3.contract import ContractEvent
import time
import mysql.connector
import json
from hexbytes import HexBytes
import warnings

polygon_url = "https://polygon-mumbai.g.alchemy.com/v2/JpRokS66sMaDD680W2NWwqhLuqDC1f7l"

class NFTScanner:
    def __init__(self, cf_contract_address, so_contract_address, from_block):
        self.cf_contract_address = cf_contract_address
        self.so_contract_address = so_contract_address
        self.cf_abi_file_path = '../contracts/abi/LagrangeChainlinkData.json'
        self.so_abi_file_path = '../contracts/abi/LagrangeChainlinkDataConsumer.json'
        self.from_block = from_block
        self.batch_size = 1000
        self.mydb = mysql.connector.connect(
            host="localhost",
            user=config('DB_USER'),
            password=config('DB_PASSWORD'),
            database='nft_data'
        )
        self.w3 = Web3(Web3.HTTPProvider(polygon_url))
        self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        self.cf_abi = json.load(open(self.cf_abi_file_path))
        self.so_abi = json.load(open(self.so_abi_file_path))
        self.mycursor = self.mydb.cursor()
        self.update_owner_command = 'UPDATE nft_ownership SET transfer_event_block = (%s), owner_address = (%s) WHERE nft_address = (%s) AND nft_ID=(%s)'
        self.is_nft_exists_command = 'SELECT * from nft_ownership WHERE nft_address = (%s) AND nft_ID=(%s)'

    def start_NFT_scan(self, target_block):
        while self.from_block < target_block:
            warnings.filterwarnings("ignore")

            to_block = self.from_block + self.batch_size
            print(self.from_block,to_block)

            cf_contract = self.w3.eth.contract(address=Web3.toChecksumAddress(self.cf_contract_address), abi=self.cf_abi)
            so_contract = self.w3.eth.contract(address=Web3.toChecksumAddress(self.so_contract_address), abi=self.so_abi)

            cf_transfer_events = cf_contract.events.Transfer.getLogs(fromBlock=self.from_block, toBlock=to_block)
            so_transfer_events = so_contract.events.Transfer.getLogs(fromBlock=self.from_block, toBlock=to_block)

            if cf_transfer_events:
                cf_event_size = len(cf_transfer_events)
                i = 0

                while i < cf_event_size:
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
                                print(f"Updated owner for NFT Address: {self.cf_contract_address}")
                            except e:
                                print(f"An error occurred while updating owner for NFT Address {CF_CONTRACT_ADDRESS}: {e}")
                        else:
                            print(f"Following NFT address does not exist in the DB: {CF_CONTRACT_ADDRESS}")

                    i=i+1

            if so_transfer_events:
                so_event_size = len(so_transfer_events)
                i = 0

                while i < so_event_size:
                    if so_transfer_events[i].args["from"] != '0x0000000000000000000000000000000000000000':

                        token_id = so_transfer_events[i].args.tokenId

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
                                print(f"Updated owner for NFT Address: {self.so_contract_address}")
                            except e:
                                print(f"An error occurred while updating owner for NFT Address {SO_CONTRACT_ADDRESS}: {e}")
                        else:
                            print(f"Following NFT address does not exist in the DB: {SO_CONTRACT_ADDRESS}")

                    i=i+1

            self.from_block = self.from_block + self.batch_size + 1
            blockDiff = target_block - self.from_block

            # print("target_block: ",target_block.number)
            # print("batchSize: ",batchSize)
            # print("from_block ",from_block)
            # print("blockDiff: ",blockDiff)

            if(blockDiff < self.batch_size):
                batchSize = blockDiff


scanner_0bj = NFTScanner('0xD81288579c13e26F621840B66aE16af1460ebB5a','0x923AfAdE5d2c600b8650334af60D6403642c1bce',34492518)
target_block = scanner_0bj.w3.eth.get_block('latest')
scanner_0bj.start_NFT_scan(target_block.number)