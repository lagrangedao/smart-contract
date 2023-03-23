import base64
from web3 import Web3


def f4_to_eth_address(f4_address):
    assert f4_address.startswith('f410f'), "not a valid f4 address"

    # Trim off leading 'f4'
    trimmed = f4_address[5:]
    
    # Base32 decode
    decoded = base64.b32decode(trimmed.upper() + '=')
    
    # Discard last 4 bytes
    decoded = decoded[:-4]
    
    # Convert to hex string
    hex_str = decoded.hex()
    
    # Prepend with '0x'
    eth_address = '0x' + hex_str

    # Convert to checksum address
    w3 = Web3()
    checksum_address = w3.toChecksumAddress(eth_address)
    
    return checksum_address

f4_address = input('enter f4 address: ')
eth_address = f4_to_eth_address(f4_address)

print('ETH address: ' + eth_address)