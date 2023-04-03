task('mint', 'Mints DataNFT')
  .addParam('contract', 'Address of the dataNFT contract to call')
  .addParam('uri', 'dataNFT metadata url')
  .addParam('minter', 'minter address')
  .addOptionalParam(
    'gaslimit',
    'Maximum amount of gas that can be used to call fulfillRequest in the client contract',
    100000,
    types.int,
  )
  .addOptionalParam(
    'requestgas',
    'Gas limit for calling the mint function',
    1500000,
    types.int,
  )
  .setAction(async (taskArgs, hre) => {
    // A manual gas limit is required as the gas limit estimated by Ethers is not always accurate
    const overrides = {
      gasLimit: taskArgs.requestgas,
    }

    if (network.name === 'hardhat') {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".',
      )
    }

    // Get the required parameters
    const contractAddr = taskArgs.contract
    const nftURI = taskArgs.uri
    const gasLimit = taskArgs.gaslimit
    if (gasLimit > 300000) {
      throw Error('Gas limit must be less than or equal to 300,000')
    }

    const minter = taskArgs.minter

    // Attach to the required contracts
    const dataNFTFactory = await ethers.getContractFactory(
      'LagrangeChainlinkData',
    )
    const dataNFTContract = dataNFTFactory.attach(contractAddr)

    const gasEstimate = await dataNFTContract.estimateGas.mint(
      [minter, nftURI],
      gasLimit,
      overrides,
    )

    console.log('minting... (estimated gas: ' + gasEstimate + ')')
    // Initiate the on-chain request after all listeners are initialized
    const requestTx = await dataNFTContract.mint(
      [minter, nftURI],
      gasLimit,
      overrides,
    )

    console.log(requestTx)
  })
