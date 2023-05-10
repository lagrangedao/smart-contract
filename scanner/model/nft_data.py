from app import db

# Define the NFTData model
class NFTData(db.Model):
    __tablename__ = 'nft_ownership'
    
    id = db.Column(db.Integer, primary_key=True)
    last_scan_block = db.Column(db.Integer)
    transfer_event_block = db.Column(db.Integer)
    nft_address = db.Column(db.String(255))
    nft_id = db.Column(db.Integer)
    owner_address = db.Column(db.String(255))