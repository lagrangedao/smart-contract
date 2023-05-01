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

# load environment variables from .env file
load_dotenv() 

app = Flask(__name__)

def execute_scanning_script():
    print(f"Scanning task executed at {datetime.now()}")
    while True:
        subprocess.Popen(['python', 'nftScanner.py']).wait()
        time.sleep(5)  # Delay for 10 seconds

@app.route('/')
def hello():
    return jsonify(message='Hello from Flask scheduler service!')

# Define endpoint to query NFT ownership record
@app.route('/get_nft_ownership', methods=['GET','POST'])
def get_nft_ownership():
    # Get parameters from request query string
    nft_address = request.args.get('nft_address')
    nft_id = request.args.get('nft_id')

    # load environment variables
    db_host = os.environ.get('DB_HOST')
    db_user = os.environ.get('DB_USER')
    db_password = os.environ.get('DB_PASSWORD')
    db_name = os.environ.get('DB_NAME')

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

    # Return result as JSON
    if result:
        return {'transfer_event_block': result[0], 'nft_address': result[1], 'nft_id': result[2], 'owner_address': result[3]}
    else:
        return 'NFT ownership record not found'

if __name__ == '__main__':
    t = threading.Thread(target=execute_scanning_script)
    t.start()
    app.run(host='0.0.0.0', port=5000)