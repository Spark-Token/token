import sha3 # pip3 install ethereum
import codecs
from random import getrandbits

# adapted from https://github.com/snissn/0xbitcoinminer-reference-implementation/blob/master/mine.py

MAX_TARGET = 2**234

def generate_nonce():
	myhex =  b'%064x' % getrandbits(32*8)
	return codecs.decode(myhex, 'hex_codec')

def mine(challenge, public_key, target_difficulty):
	target = MAX_TARGET / target_difficulty
	while True:
		nonce = generate_nonce()
		hash1 = int(sha3.keccak_256(challenge+public_key+nonce).hexdigest(), 16)
		if hash1 < target:
			return nonce, hash1

def main():
	# current challenge hex
	challenge_hex = '0000000000000000000000000000000000000000000000000000000000000000' 
	challenge = codecs.decode(challenge_hex,'hex_codec')

	# miner ethereum public key without leading 0x
	public_key_hex = 'CA35b7d915458EF540aDe6068dFe2F44E8fa733c' 
	public_key = codecs.decode(public_key_hex,'hex_codec')

	# miner sets the target difficulty to mine
	target_difficulty = 2

	target = MAX_TARGET / target_difficulty
	print("Target Difficulty:", target_difficulty )
	print("Target:", target )
	# mine solution based on challenge, pk, and target difficulty
	valid_nonce, resulting_hash = mine(challenge, public_key, target_difficulty)
	print("Resulting hash is: ", hex(resulting_hash))
	print("Soln difficulty (reward):", MAX_TARGET / resulting_hash )
	print("Valid soln nonce is: ", "0x" + valid_nonce.hex())

if __name__ == "__main__":
	main()
