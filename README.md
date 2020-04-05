# Spark Token
### An EIP918 smart contract that tokenizes proof of work difficulty

Spark is an EIP918 token that provides miners the ability to tokenize hashpower. Tokens are minted based solely on the difficulty target (the number of zeros) of the provided solution, defined as:

```
MAX_TARGET = 2**234
target_difficulty = 10
t = target_difficulty / MAX_TARGET
```

In the above scenario the mining for target would provide the miner with at least 10 Spark tokens. Since the mining process itself is random, the resulting solution could also be higher providing a higher payout than with traditional difficulty adjusted/block reward based tokens.

### Minting Spark Tokens

Spark Tokens are minted the same way any EIP918 compliant tokens are. A Proof of Work nonce is discovered by mining clients, the solution is hashed with the contract's challenge number and miner address and then checked that it meets required difficulty levels. ( The minimum difficulty of the Spark Token being 1 )

Spark tokens are relatively competatively fair with a very low difficulty floor (1) that miners have to adhere to. This means that if you mine 1,000,000,000 tokens or just 1 you have the same advantage in submitting your solution. This important feature of the token levels the playing field for smaller miners looking to accumulate hashpower independently.

```solidity
// ERC918 mint function
function mint(uint256 nonce) public returns (bool success) {
    // prevent gas racing by setting the maximum gas price to 5 gwei
    require(tx.gasprice < 5 * 1000000000);
        
    // derive solution hash n
    uint256 n = uint256(
        keccak256(abi.encodePacked(currentChallenge, msg.sender, nonce))
    );
    // check that the minimum difficulty is met
    require(n < MAXIMUM_TARGET, "Minimum difficulty not met");

    // reward the mining difficulty - the number of zeros on the PoW solution
    uint256 reward = MAXIMUM_TARGET.div(n);
    // emit Mint Event
    emit Mint(msg.sender, reward, 0, currentChallenge);
    // update the challenge to prevent proof resubmission
    currentChallenge = keccak256(
        abi.encodePacked(
            nonce,
            currentChallenge,
            now,
            blockhash(block.number - 1)
        )
    );

    // perform the mint operation
    _mint(msg.sender, reward);
    return true;
}
```

### Example Scenario

For example if I wanted to mine 100 Spark Tokens I would tell my miner to target a difficulty of 100. My miner could come back with a solution that is of 112, since it only checks that a random nonce has a *minimum* difficulty of 100. I would submit the solution to the Spark contract and receive 112 Spark Tokens in return. Since Spark Tokens use the same difficulty system as 0xbitcoin, KIWI, and others, I could conceivably trade difficulty for the appropriate amount of tokens. So, given that the current difficulty of 0xBitcoin is 1,179,290,918, I should be able to trade an equal amount of Spark Tokens for the block reward ( 50 0xBTC ). In the same respect, as a small miner that has mined 100,000 Spark Tokens, I am be able to perform a similar calculation to receive the appropriate fractional amount of tokens as such:

`100,000 Spark Tokens / 1,179,290,918 0xBitcoin Difficulty * 50 0xBTC reward = 0.00423983 0xBitcoin`

Since 0xBitcoin, KIWI and other EIP918 tokens have a deterministic difficulty, a decentralized swap contract could be created to ensure fair trade value per the following pseudocode:

```solidity
contract Spark0xBitcoinSwapper {
  // 0xBitcoin
  EIP918Interface btc = EIP918Interface(0xb6ed7644c69416d67b522e20bc294a9a9b405b31);
  ERC20 erc20Btc = ERC20(0xb6ed7644c69416d67b522e20bc294a9a9b405b31);
  ERC20 spark = ERC20(0xSPARKADDRESS);
  
  function swap(uint sparks) {
    // calulate amount of EIP918 tokens
    uint amount =  sparks / btc.getDifficulty() * btc.getReward();
    
    // transfer spark tokens to this contract
    spark.transferFrom(msg.sender, this, sparks);
    
    // send 0xbitcoin to sender
    erc20Btc.transfer(amount, msg.sender);
  }
}

```

## Other Uses

1. Arbitrage mining against flucuating 0xBitcoin, KIWI, etc. difficulty. Difficulty Tokens allow miners to store difficulty when 0xBitcoin diff is high and sell it back when diff is low.
2. Difficulty Tokens can also be traded for DAI,USDT,USDC, etc. on open markets as there is a dollar amount(price of electricity) associated with the costs of mining. This triangular market effectively creates a decentralized price oracle for USD.
3. A "metapool" whereby pool operators exchange hashpower for EIP918 tokens
4. A generic token for thottling external of-chain services with proof of work
5. Triangular arbitrage between EIP918 tokens without having to use ETH or USD tethers. Example: KIWI-Spark-0xBitcoin This would provide market liquidity for tokens.

## Ropsten Testnet Deployment
https://ropsten.etherscan.io/address/0x1ce8d42bde881b7846bc525e968e3a50a032781d

## References

Spark Token was inspired by:
* [FuelToken](https://github.com/snissn/FuelToken) designed by [@mikers](https://github.com/snissn) ( don't forget to [mine](http://mike.rs/) with @mikers )
* [MinableToken](https://github.com/liberation-online/MineableToken) designed by [@adamjamesmartin](https://github.com/adamjamesmartin) of the [KIWI project](https://kiwi-token.com/)
* [0xBitcoin](https://etherscan.io/address/0xb6ed7644c69416d67b522e20bc294a9a9b405b31#code) designed by [@Infernal_toast](https://github.com/admazzola) of the [0xBitcoin Project](https://0xbitcoin.org/)
