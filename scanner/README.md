# Steps to run Polygon scanning script:

1. Configure the `.env` file by renaming `sample.env` to `.env`
2. Add your Polygon testnet Alchemy link and the Polygon API key to `.env`
3. Run `polygon_API_scanner.py` (which queries all the success/failure transactions using Polygon's API) by using the following command:

```
python3 polygon_API_scanner.py
```

4. Alternatively, you can use the block scanner which iterates over each block by using the following command:

```
python3 scan_polygon_payment.py
```

# Steps to run BSC scanning script:

1. Add your BSC testnet API key to `.env`
2. Run `bsc_API_scanner.py` (which queries all the success/failure transactions using BSC's API) by using the following command:

```
python3 bsc_API_scanner.py
```

# Steps to run Hyperspace scanning script:

1. Configure the `.env` file by renaming `sample.env` to `.env`
2. Add the Hyperspace node URL to `HYPERSPACE_URL=` as shown below:

```
HYPERSPACE_URL=https://api.hyperspace.node.glif.io/rpc/v1
```

Or use this node if the glif node is down: `https://rpc.ankr.com/filecoin_testnet`  
3. Install MySQL connector by executing the following command:

```
pip install mysql-connector-python
```

4. Create a database on `localhost` and create tables by executing the `scanner/db/SQL_COMMANDS.sql` file.
5. Configure the `.env` file with the database user name and password.
6. The `contract` and `network` tables must have at least 1 valid entry before executing the script.
7. Configure the `contract_id_val` & `coin_id_val` variables in `hyperspacescan.py` according to the values found in the tables,
8. Run the script:

```
python3 hyperspacescan.py
```

# Steps to run the NFT scanning script:

1. Checkout to the `rishabh/nft-scanner` branch.
2. Configure the `.env` file by renaming `.env.template` to `.env`
3. Add the following parameters to it and configure them according to your DB parameters:

```
DB_HOST=
DB_USER=
DB_PASSWORD=
DB_NAME=
```

4. Create the `nft_ownership` table in your DB by running the script found in `scanner/db/NFT_SQL_COMMANDS.sql`
5. Now run the NFT scanning script by running the following command:

```
python3 nftScanner.py
```

Note: Some dependencies/pip packages were giving some errors and in case you face the same, I would recommend setting up a python virtual environment by following this article: https://programwithus.com/learn/python/pip-virtualenv-mac and running the steps described above.
