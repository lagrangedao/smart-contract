const contractAddress = args[0]
const checkingAddress = args[1]

// make HTTP request
const url = `https://api.etherscan.io/api`
const req = Functions.makeHttpRequest({
  url: url,
  params: {
    module: 'contract',
    action: 'getcontractcreation',
    contractaddresses: contractAddress,
    apikey: '3C8TH6TUPDT8M5EA2IJ9XR18WAUAG5TH2Q',
  },
})

// Execute the API request (Promise)
const res = await req
if (res.error) {
  console.error(res.error)
  throw Error('Request failed')
}

const data = res['data']
if (data.Response === 'Error') {
  console.error(data.Message)
  throw Error(`Functional error. Read message: ${data.Message}`)
}

const owner = data['result'][0]['contractCreator']
console.log(`${contractAddress} owner: ${owner}`)

let isOwner = owner == checkingAddress ? 1 : 0
return Functions.encodeUint256(isOwner)
