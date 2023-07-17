const { ethers } = require('hardhat')

async function main(functionToCall, args = [], proposalDescription = '') {
  const GOVERNOR_ADDRESS = '0x67FaAaf08De1cB6de51fCb936893c542692b9115'
  const BOX_ADDRESS = '0x09a296726A203600f0d9AFa9D38c4fCdaad94B9A'

  const deployer = await ethers.getSigner()
  console.log('deployer: ', deployer.address)

  const Governor = await ethers.getContractFactory('GovernorContract')
  const Box = await ethers.getContractFactory('Box')

  const governor = Governor.attach(GOVERNOR_ADDRESS)
  const box = Box.attach(BOX_ADDRESS)

  const encodedFunctionCall = box.interface.encodeFunctionData(
    functionToCall,
    args,
  )

  console.log(encodedFunctionCall)
  console.log(`Proposing ${functionToCall} on ${box.address} with ${args}`)
  console.log(`Proposal Description:\n ${proposalDescription}`)

  const proposeTx = await governor.propose(
    [box.address],
    [0],
    [encodedFunctionCall],
    proposalDescription,
  )
  const proposalReceipt = await proposeTx.wait(1)
  const proposalId = proposalReceipt.events[0].args.proposalId
  console.log('Proposal ID: ', proposalId)

  const proposalState = await governor.state(proposalId)
  const proposalSnapShot = await governor.proposalSnapshot(proposalId)
  const proposalDeadline = await governor.proposalDeadline(proposalId)

  // the Proposal State is an enum data type, defined in the IGovernor contract.
  // 0:Pending, 1:Active, 2:Canceled, 3:Defeated, 4:Succeeded, 5:Queued, 6:Expired, 7:Executed
  console.log(`Current Proposal State: ${proposalState}`)
  // What block # the proposal was snapshot
  console.log(`Current Proposal Snapshot: ${proposalSnapShot}`)
  // The block number the proposal voting expires
  console.log(`Current Proposal Deadline: ${proposalDeadline}`)
}

main('store', [1234], 'Proposal #4: Store 1234 in Box')
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
