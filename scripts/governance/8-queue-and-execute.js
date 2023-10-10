async function main() {
  const GOVERNOR_ADDRESS = '0x67FaAaf08De1cB6de51fCb936893c542692b9115'
  const BOX_ADDRESS = '0x09a296726A203600f0d9AFa9D38c4fCdaad94B9A'

  const Governor = await ethers.getContractFactory('GovernorContract')
  const Box = await ethers.getContractFactory('Box')
  const governor = Governor.attach(GOVERNOR_ADDRESS)
  const box = Box.attach(BOX_ADDRESS)

  const args = [1234]
  const functionToCall = 'store'
  const encodedFunctionCall = box.interface.encodeFunctionData(
    functionToCall,
    args,
  )
  const descriptionHash = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes('Proposal #4: Store 1234 in Box'),
  )
  // could also use ethers.utils.id(PROPOSAL_DESCRIPTION)

  console.log('Queueing...')
  const queueTx = await governor.queue(
    [box.address],
    [0],
    [encodedFunctionCall],
    descriptionHash,
  )
  await queueTx.wait(1)

  console.log('Executing...')
  // this will fail on a testnet because you need to wait for the MIN_DELAY!
  const executeTx = await governor.execute(
    [box.address],
    [0],
    [encodedFunctionCall],
    descriptionHash,
  )
  await executeTx.wait(1)
  console.log(`Box value: ${await box.retrieve()}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
