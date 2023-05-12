from sqlalchemy import Column, Integer, String
from model import db

class NFTData(db.Model):
    __tablename__ = 'nft_ownership'

    id = Column(Integer, primary_key=True)
    transfer_event_block = Column(Integer)
    nft_address = Column(String)
    nft_ID = Column(Integer)
    owner_address = Column(String)

class NFTContractDetails(db.Model):
    __tablename__='nft_contract_details'
    id = Column(Integer, primary_key=True)
    last_scan_block = Column(Integer)
    NFT_contract_address = Column(String)
    owner_address = Column(String)
