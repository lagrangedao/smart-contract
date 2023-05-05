const uri = args[0]

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

return Functions.encodeString(isOwner)
