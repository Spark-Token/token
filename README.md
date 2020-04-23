# Spark Token
### An EIP918 smart contract that tokenizes proof of work difficulty

Spark is an EIP918 token that provides miners the ability to tokenize hashpower directly, without having to compete against other miners. Tokens are minted based solely on the difficulty target (the number of zeros) of the provided solution, defined as:

```
MAX_TARGET = 2**234
target_difficulty = 10
t = target_difficulty / MAX_TARGET
```

In the above scenario the mining for target would provide the miner with at least 10 Spark tokens. Since the mining process itself is random, the resulting solution could also be higher providing a higher payout than with traditional difficulty adjusted/block reward based tokens.

### Advantages

* Energy Savings: Spark Tokens use much less electricity than difficulty-adjusted tokens because they remove the need for network competition. There is no race to submit your solution, as each challenge is tied to individual mining accounts, so there is zero wasted hash power in the production of Sparks. The reward is purely based on work performed. In fact you could accumulate as much difficulty as you want to, for as long as you want to, and submit it to the contract at any time without penalty. These energy savings benefit miners, pool relayers and the planet.

* Portability: Sparks are utility tokens that can be used to transfer value between any Mineable Token (EIP918 compatible). They are designed to represent proof of work and can be atomically applied to many scenarios. They may be useful in backing NFTs with proofs of work as a store of value, providing gated functions on smart contracts or creating fair, decentralized EIP918 token swaps.

* Offchain mining: Since address challenges are simple, deterministic counters, miners can solve multiple difficulty solutions and submit them in batches once ready. This means more savings for miners and pool operators.

### Minting Spark Tokens

Spark Tokens are minted the same way any EIP918 compliant tokens are. A Proof of Work nonce is discovered by mining clients, the solution is hashed with the contract's challenge number and miner address and then checked that it meets required difficulty levels. ( The minimum difficulty of the Spark Token being 1 )

Spark tokens are relatively competatively fair with a very low difficulty floor (1) that miners have to adhere to. This means that if you mine 1,000,000,000 tokens or just 1 you have the same advantage in submitting your solution. This important feature of the token levels the playing field for smaller miners looking to accumulate hashpower independently.

Primary mint function:
```solidity
// mint function with variable difficulty
function mint(uint256 nonce, uint256 targetDifficulty)
    public
    returns (bool success)
{
    // derive solution hash n
    uint256 n = uint256(
        keccak256(
            abi.encodePacked(
                senderChallenges[msg.sender],
                keccak256(abi.encodePacked(msg.sender, targetDifficulty, address(this))),
                nonce
            )
        )
    );

    // check that the target difficulty is met
    require(
        n < MAXIMUM_TARGET.div(targetDifficulty),
        "Target difficulty not met"
    );

    // reward the target difficulty - the number of zeros on the PoW solution
    uint256 reward = targetDifficulty * 10**18;

    // update the challenge to prevent proof resubmission
    // proof challenges are simple counters
    senderChallenges[msg.sender] += 1;

    // perform the mint operation
    _mint(msg.sender, msg.sender, reward, "", "");
    return true;
}
```

ERC918 mint function using default difficulty of 2**16. Note that this function contains a 5 second time throttle to help prevent collisions
```solidity
// default ERC918 mint function using relavtively small default target difficulty
function mint(uint nonce) public returns (bool success) {
    // add time based throttle to default mint since difficulty is low 
    uint timeSinceLastProof = (now - timeOfLastProof);
    require(timeSinceLastProof >  5 seconds);
    timeOfLastProof = now;
    return mint(nonce, DEFAULT_TARGET_DIFFICULTY);
}
```

### Usage Scenario 1: EIP918 Token Swap

For example if I wanted to mine 100 Spark Tokens I would tell my miner to target a difficulty of 100. I would submit the solution to the Spark contract and receive 100 Spark Tokens in return. Since Spark Tokens use the same difficulty system as 0xbitcoin, KIWI, and others, I could conceivably trade difficulty for the appropriate amount of tokens. So, given that the current difficulty of 0xBitcoin is 1,179,290,918, I should be able to trade an equal amount of Spark Tokens for the block reward ( 50 0xBTC ). In the same respect, as a small miner that has mined 100,000 Spark Tokens, I am be able to perform a similar calculation to receive the appropriate fractional amount of tokens as such:

`100,000 Spark Tokens / 1,179,290,918 0xBitcoin Difficulty * 50 0xBTC reward = 0.00423983 0xBitcoin`

Since 0xBitcoin, KIWI and other EIP918 tokens have a deterministic difficulty, a decentralized swap contract could be created to ensure fair trade value per the following pseudocode:

```solidity
contract Spark0xBitcoinSwapper {
  // 0xBitcoin
  EIP918 btc = EIP918(0xb6ed7644c69416d67b522e20bc294a9a9b405b31);
  ERC20 erc20Btc = ERC20(0xb6ed7644c69416d67b522e20bc294a9a9b405b31);
  ERC20 spark = ERC20(0xSPARKADDRESS);
  
  function buy0xBitcoin(uint sparks) public {
    // calulate amount of EIP918 tokens
    uint amount =  sparks / btc.getDifficulty() * btc.getReward();
    
    // transfer spark tokens to this contract
    spark.transferFrom(msg.sender, this, sparks);
    
    // send 0xbitcoin to sender
    erc20Btc.transfer(amount, msg.sender);
  }
  
  function buySpark(uint bitcoins) public {
     // calulate amount of EIP918 tokens
    uint amount =  btc.getDifficulty() * bitcoins / btc.getReward();
    
    // transfer 0xbitcoins to this contract
    erc20Btc.transferFrom(msg.sender, this, bitcoins);
    
    // send sparks to sender
    spark.transfer(amount, msg.sender);
  }
}

```

### Usage Scenario 2: Smart Contract and off-chain Throttling

Since Spark Tokens are work proofs, they can be used as generalized throttling mechanisms to economically de-incentivize bad actors from DDOS-ing or incorrectly updating application state for nefarious reasons. This can be acheived with on chain and off chain services.

For example, if I wanted to create an Ethereum Smart contract that required additional proof of work security I could create a function modifier that requires a certain number of Spark Tokens to execute (see difficulty(tokens) function). Alternatively, I could have the end user submit a nonce of required difficulty instead of tokens, and mine them directly to the contract. (see difficulty(uint nonce, uint diff) function)

Solidity pseudocode:
```solidity
contract Throttled {

    EIP918 sparkEIP918 = EIP918(0xSPARKADDRESS);
    ERC20 sparkERC20 = ERC20(0xSPARKADDRESS);

    // require that a number of spark tokens need to be sent
    // to this contract in order to execute target function
    modifier difficulty(uint tokens) {
        require(
            sparkERC20.transferFrom(msg.sender,tokens,this);
        );
        _;
    }
    
    // require a solution of a minimum difficulty be used
    // this modifier submits a solution to the Spark contract
    // and the resulting tokens are received by this contract
    // effectively allowing a user to submit a proof instead of
    // tokens directly
    modifier difficulty(uint nonce, uint diff) {
        require(
            sparkEIP918.getMiningDifficulty(nonce) >= diff
        );
        require(
            sparkEIP918.mint(nonce)
        );
        _;
    }
    
    // ensure end users are mining against the proper challenge
    function getChallenge() public returns (uint) {
        return sparkEIP918.getChallenge();
    }
}

contract MyContract is Throttled {
    
    // require that the method use 1000 difficulty in order to execute
    function doSomething() public difficulty(1000) {
        ...
    }
    
    // require sender to supply a solution proof of a certain difficulty
    // note that senders must use this contract's getChallenge() method
    // in order to mine Spark Tokens directly to the contract as payment
    function doSomethingElse(uint nonce) public difficulty(nonce, 1000) {
        ...
    }
}
```

nodejs pseudocode:

```javascript
const Web3 = require('web3')
const web3 = new Web3()
const spark = require('./lib/SparkToken')
const serviceAddress = 0xServiceAddress

const MIN_DIFFICULTY = 1000

// function to handle request, requires 1000 Spark Tokens
// to be sent to the target address in order to execute
function doSomething(msgSender, tokens){
    if (tokens < MIN_DIFFICULTY || 
        !sparkERC20.transferFrom(msgSender,tokens,serviceAddress) ) {
        throw 'difficulty not met'
    }
    ...
}

// function to handle request, requires 1000 Spark Tokens
// to be sent to the target address in order to execute
// end users must mine against getChallengeNumber(serviceAddress)
function doSomethingElse(nonce){
    if (sparkERC20.getMiningDifficulty(nonce) < MIN_DIFFICULTY ) {
        throw 'difficulty not met'
    }
    // mint difficulty directly to target service owner
    if(!sparkEIP918.mint(nonce, {from: serviceAddress})){
        throw 'unable to mine nonce'
    }
    ...
}
```

## Other Uses

1. Arbitrage mining against flucuating 0xBitcoin, KIWI, etc. difficulty. Difficulty Tokens allow miners to store difficulty when 0xBitcoin diff is high and sell it back when diff is low.
2. Difficulty Tokens can also be traded for DAI,USDT,USDC, etc. on open markets as there is a dollar amount(price of electricity) associated with the costs of mining. This triangular market effectively creates a decentralized price oracle for USD.
3. A "metapool" whereby pool operators exchange hashpower for EIP918 tokens
4. A generic token for thottling external of-chain services with proof of work
5. Triangular arbitrage between EIP918 tokens without having to use ETH or USD tethers. Example: KIWI-Spark-0xBitcoin This would provide market liquidity for tokens.

## Ropsten Testnet Deployment
https://ropsten.etherscan.io/address/0x9Ad77cBd452e2Cc7F8325aE909c9f2993116AEC7

## References

Spark Token was inspired by:
* [FuelToken](https://github.com/snissn/FuelToken) designed by [@mikers](https://github.com/snissn) ( don't forget to [mine](http://mike.rs/) with @mikers )
* [MineableToken](https://github.com/liberation-online/MineableToken) designed by [@adamjamesmartin](https://github.com/adamjamesmartin) of the [KIWI project](https://kiwi-token.com/)
* [0xBitcoin](https://etherscan.io/address/0xb6ed7644c69416d67b522e20bc294a9a9b405b31#code) designed by [@Infernal_toast](https://github.com/admazzola) of the [0xBitcoin Project](https://0xbitcoin.org/)
