from flask import Flask, jsonify, request
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
import subprocess
import mysql.connector
import requests
import os
from dotenv import load_dotenv
from threading import Thread

from nftScanner import main

# load environment variables from .env file
load_dotenv() 

app = Flask(__name__)

def scheduled_task():
    print(f"Scheduled task executed at {datetime.now()}")

scheduler = BackgroundScheduler()
scheduler.add_job(func=scheduled_task, trigger="interval", seconds=10)
scheduler.start()

@app.route('/')
def hello():
    return jsonify(message='Hello from Flask scheduler service!')
    
# Define endpoint to start scan process
@app.route('/start_scan', methods=['GET','POST'])
def start_scan():
    # Get parameters from request body
    # cf_contract_address = request.json['cf_contract_address']
    # so_contract_address = request.json['so_contract_address']
    # from_block = request.json['from_block']
    # target_block = request.json['target_block']

    # # Create NFTScanner instance
    # scanner = NFTScanner(cf_contract_address, so_contract_address, from_block)

    # # Start scan process in a new thread
    # thread = Thread(target=scanner.start_NFT_scan, args=[target_block])
    # thread.start()

    #subprocess.Popen(['python', 'nftScanner.py'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    thread = Thread(target=main)
    thread.start()

    return 'Scan process started'

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
    app.run(host='0.0.0.0', port=5000)