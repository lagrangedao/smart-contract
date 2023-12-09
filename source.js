const name = args[0]
const description = args[1]
const image = args[2]

let headers = {
  Authorization: `Bearer aPiToKENForHacKatHon`,
  'Content-Type': 'application/json',
}

// Execute the API request (Promise)
const apiResponse = await Functions.makeHttpRequest({
  url: `https://test-api.lagrangedao.org/upload_one_file`,
  headers,
  method: 'POST',
  data: { name: args[0], description, image },
})

if (apiResponse.error) {
  console.log(apiResponse)
  throw Error('Request failed')
}

const { data } = apiResponse
console.log(data)

// Return Character Name
return Functions.encodeString(data.data.ipfs_url)
