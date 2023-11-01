const fs = require('fs')
const parse = require('csv-parser')
const fastcsv = require('fast-csv')
const { ethers } = require('hardhat')

async function main() {
  // Replace with your contract's address and ABI
  const contractAddress = '0xa8D57878C83FB88106E63B890e5f69b3D11174ca'
  const contractABI = [
    {
      inputs: [
        {
          internalType: 'address',
          name: '',
          type: 'address',
        },
      ],
      name: 'isAdmin',
      outputs: [
        {
          internalType: 'bool',
          name: '',
          type: 'bool',
        },
      ],
      stateMutability: 'view',
      type: 'function',
    },
    {
      inputs: [
        {
          internalType: 'address',
          name: 'claimer',
          type: 'address',
        },
        {
          internalType: 'uint256',
          name: 'tokenId',
          type: 'uint256',
        },
      ],
      name: 'setClaim',
      outputs: [],
      stateMutability: 'nonpayable',
      type: 'function',
    },
  ]

  const signer = (await ethers.getSigners())[0]

  const csvFileName = 'spooky-nft-winners.csv' // Replace with your CSV file name
  const outputCsvFileName = 'spooky-nft-winners-output.csv' // Name of the output CSV file

  const csvData = []
  fs.createReadStream(csvFileName)
    .pipe(parse({ headers: true }))
    .on('data', (row) => {
      csvData.push(row)
    })
    .on('end', async () => {
      const contract = new ethers.Contract(contractAddress, contractABI, signer)
      const updatedCsvData = []

      for (const row of csvData) {
        const walletAddress = row.wallet_address
        const tokenId = row.token_id

        try {
          const tx = await contract.setClaim(walletAddress, tokenId)

          console.log(
            `Claim transaction sent for address ${walletAddress} and tokenId ${tokenId}`,
          )
          console.log(`Transaction Hash: ${tx.hash}`)

          // Wait for the transaction to be mined
          await tx.wait()
          console.log(
            `Transaction confirmed for address ${walletAddress} and tokenId ${tokenId}`,
          )

          // Append the transaction hash to the row
          row.tx_hash = tx.hash
        } catch (error) {
          console.error(
            `Error for address ${walletAddress} and tokenId ${tokenId}: ${error.message}`,
          )
          // Set the tx_hash to an empty string in case of an error
          row.tx_hash = ''
        }

        updatedCsvData.push(row)
      }

      // Write the updated CSV data with transaction hashes to the output CSV file
      fastcsv
        .writeToPath(outputCsvFileName, updatedCsvData, { headers: true })
        .on('error', (err) =>
          console.error('Error writing to output CSV:', err),
        )
        .on('finish', () =>
          console.log(`Transaction hashes written to ${outputCsvFileName}`),
        )
    })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
