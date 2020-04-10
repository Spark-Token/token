import sha3 # pip3 install ethereum
import codecs
from random import getrandbits

# adapted from https://github.com/snissn/0xbitcoinminer-reference-implementation/blob/master/mine.py

MAX_TARGET = 2**234

def generate_nonce():
	myhex =  b'%064x' % getrandbits(32*8)
	return codecs.decode(myhex, 'hex_codec')

def xor_strings(xs, ys):
	print(xs, ys)
	return "{0:0{1}x}".format(int(xs, 16) ^ int(ys, 16), 64)
	#return format(int(xs, 16) ^ int(ys, 16), 'x')

def xor_strings(xs, ys, zs):
	print(xs, ys, zs)
	return "{0:0{1}x}".format(int(xs, 16) ^ int(ys, 16) ^ int(zs, 16), 64)

# mine against a variable difficulty
def mine(challenge, xored, target_difficulty):
	target = MAX_TARGET / target_difficulty
	target_difficulty_hex = "{0:0{1}x}".format(target_difficulty, 64)
	td = codecs.decode(target_difficulty_hex,'hex_codec')

	while True:
		nonce = generate_nonce()
		hash1 = int(sha3.keccak_256(challenge+xored+nonce).hexdigest(), 16)
		if hash1 < target:
			return nonce, hash1

def main():
	# contract address hex
	contract_hex = '9cc236461174E3Ac1b263F1F4E7C9e939B84481F'
	contract_hex = "{0:0{1}x}".format(int(contract_hex,16), 64)

	# current challenge hex
	# challenge_hex = '000000000000000000000000FFE59C55C6A7466B6338007CB541A6FFA96DAFBF'
	challenge_hex = '0000000000000000000000000000000000000000000000000000000000000001' 
	# challenge_hex = "{0:0{1}x}".format(1460913135915204819274690657848886480519004270527, 64)  
	challenge = codecs.decode(challenge_hex,'hex_codec')

	# miner ethereum public key without leading 0x
	public_key_hex = '7E6a477B833829463E5420F39eA5d9AEfef42086'
	# public_key = codecs.decode(public_key_hex,'hex_codec')	

	# miner sets the target difficulty to mine
	target_difficulty = 3
	target_difficulty_hex = "{0:0{1}x}".format(target_difficulty, 64)
	public_key_hex = "{0:0{1}x}".format(int(public_key_hex,16), 64)

	# xor public key and vardiff
	xored_hex = xor_strings(public_key_hex, target_difficulty_hex, contract_hex)
	print(xored_hex)
	xored = codecs.decode(xored_hex,'hex_codec')

	target = MAX_TARGET / target_difficulty
	print("Target Difficulty:", target_difficulty )
	print("Target:", target )
	# mine solution based on challenge, pk, and target difficulty
	valid_nonce, resulting_hash = mine(challenge, xored, target_difficulty)
	print("Resulting hash is: ", hex(resulting_hash))
	print("Soln difficulty (reward):", MAX_TARGET / resulting_hash )
	print("Valid soln nonce is: ", "0x" + valid_nonce.hex())

if __name__ == "__main__":
	main()
