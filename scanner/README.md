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
