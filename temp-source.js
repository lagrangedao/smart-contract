const senderAddress = args[0]
const uri = args[1]

// make HTTP request to get IPFS metadata
const req = Functions.makeHttpRequest({
  url: uri,
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

const owner = data?.owner

if (!owner) {
  throw new Error(`Metadata does not contain owner property.`)
}

let isOwner = owner.toLowerCase() === senderAddress.toLowerCase() ? 1 : 0
return Functions.encodeUint256(isOwner)
