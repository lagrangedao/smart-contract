from flask import Flask, jsonify, request
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
import subprocess
import mysql.connector
import requests
import os
import time
from dotenv import load_dotenv
import threading
from nftScanner import main
import logging

# load environment variables from .env file
load_dotenv()

db_host = os.environ.get('DB_HOST')
db_user = os.environ.get('DB_USER')
db_password = os.environ.get('DB_PASSWORD')
db_name = os.environ.get('DB_NAME')

# Query database for NFT ownership record

app = Flask(__name__)

def execute_scanning_script():
    logging.info(f"Scanning task executed at {datetime.now()}")
    while True:
        subprocess.Popen(['python', 'nftScanner.py']).wait()
        time.sleep(3)  # Delay for 3 seconds

def query_database(nft_address, nft_id):
    # Query database for NFT ownership record
    mydb = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )
    mycursor = mydb.cursor()
    query = 'SELECT * FROM nft_ownership WHERE nft_address = %s AND nft_ID = %s'
    params = (nft_address, nft_id)
    mycursor.execute(query, params)
    result = mycursor.fetchone()
    # mydb.close()
    return result

# Define endpoint to query NFT ownership record
@app.route('/get_nft_details', methods=['GET'])
def get_nft_details():
    # Get parameters from request query string
    nft_address = request.args.get('nft_address')
    nft_id = request.args.get('nft_id')

    result = query_database(nft_address,nft_id)

    # Return result as JSON
    if result:
        return {'transfer_event_block': result[1], 'nft_address': result[2], 'nft_id': result[3], 'owner_address': result[4]}
    else:
        return 'NFT ownership record not found'

if __name__ == '__main__':
    t = threading.Thread(target=execute_scanning_script)
    t.start()
    app.run(host='0.0.0.0', port=5000)