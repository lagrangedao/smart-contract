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
3. Install MySQL connector by executing the following command:
```
pip install mysql-connector-python
```
4. Create a database on `localhost` with the following credentials and DB name:
```
user="root",
password="Sql@12345",
database='HYPERSPACE'
```
5. Run the script:

```
python3 hyperspacescan.py
```
