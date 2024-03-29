from flask import Flask, jsonify, request
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
from model import db
from model.nft_data import NFTData

import subprocess
import mysql.connector
import requests
import os
import time

import threading
from nftScanner import main
import logging
import toml

# load environment variables from .env file
config=toml.load('config.toml')

db_host = config['DB_HOST']
db_user = config['DB_USER']
db_password = config['DB_PASSWORD']
db_name = config['DB_NAME']

app = Flask(__name__)

# setup SQL Alchemy
app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql://{db_user}:{db_password}@{db_host}/{db_name}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize the SQLAlchemy extension
db.init_app(app)

def execute_scanning_script():
    logging.info(f"Scanning task executed at {datetime.now()}")
    while True:
        try:
            main()
        except Exception as e:
            logging.error(e)
        
        # Delay for 3 seconds
        time.sleep(3)

t = threading.Thread(target=execute_scanning_script)
t.start()

def query_database(nft_address, nft_id):
    # Query database for NFT ownership record
    try:
        result = NFTData.query.filter_by(nft_address=nft_address, nft_id=nft_id).first()
    except Exception as e:
        logging.error("Error fetching NFT details: ",e)

    return result

@app.route('/get_nft_details', methods=['GET'])
def get_nft_details():
    # Get parameters from request query string
    nft_address = request.args.get('nft_address')
    nft_id = request.args.get('nft_id')

    result = query_database(nft_address,nft_id)

    # Return result as JSON
    if result:
        return {'transfer_event_block': result.transfer_event_block, 'nft_address': result.nft_address, 'nft_id': result.nft_id, 'owner_address': result.owner_address}
    else:
        return 'NFT record not found'
   

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)