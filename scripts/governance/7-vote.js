const PROPOSAL_ID =
  '37576772663572847412545200320644913417257113620070897783141073953320328857486'
const GOVERNOR_ADDRESS = '0x67FaAaf08De1cB6de51fCb936893c542692b9115'

async function main() {
  // 0 = Against, 1 = For, 2 = Abstain for this example
  const voteWay = 1
  const reason = 'I lika do da cha cha'
  await vote(PROPOSAL_ID, voteWay, reason)
}

// 0 = Against, 1 = For, 2 = Abstain for this example
async function vote(proposalId, voteWay, reason) {
  console.log('Voting...')
  const Governor = await ethers.getContractFactory('GovernorContract')
  const governor = Governor.attach(GOVERNOR_ADDRESS)
  const voteTx = await governor.castVoteWithReason(proposalId, voteWay, reason)
  const voteTxReceipt = await voteTx.wait(1)
  console.log(voteTxReceipt.events[0].args.reason)
  const proposalState = await governor.state(proposalId)
  console.log(`Current Proposal State: ${proposalState}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
