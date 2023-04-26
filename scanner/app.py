from flask import Flask, jsonify
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime

app = Flask(__name__)

# Define endpoint to start scan process
@app.route('/start_scan', methods=['POST'])
def start_scan():
    # Get parameters from request body
    cf_contract_address = request.json['cf_contract_address']
    so_contract_address = request.json['so_contract_address']
    from_block = request.json['from_block']
    target_block = request.json['target_block']

    # Create NFTScanner instance
    scanner = NFTScanner(cf_contract_address, so_contract_address, from_block)

    # Start scan process in a new thread
    thread = Thread(target=scanner.start_NFT_scan, args=[target_block])
    thread.start()

    return 'Scan process started'

# Define endpoint to query NFT ownership record
@app.route('/get_nft_ownership', methods=['GET'])
def get_nft_ownership():
    # Get parameters from request query string
    nft_address = request.args.get('nft_address')
    nft_id = request.args.get('nft_id')

    # Query database for NFT ownership record
    mycursor = scanner.mydb.cursor()
    query = 'SELECT * FROM nft_ownership WHERE nft_address = %s AND nft_ID = %s'
    params = (nft_address, nft_id)
    mycursor.execute(query, params)
    result = mycursor.fetchone()

    # Return result as JSON
    if result:
        return {'nft_address': result[0], 'nft_id': result[1], 'owner_address': result[2], 'transfer_event_block': result[3]}
    else:
        return 'NFT ownership record not found'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)