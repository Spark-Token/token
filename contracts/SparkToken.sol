pragma solidity ^0.5.1;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "./ERC918.sol";


contract SparkToken is ERC777, ERC918 {
    using SafeMath for uint;
    uint public MINIMUM_TARGET = 2**16;
    uint public MAXIMUM_TARGET = 2**234;
    uint public DEFAULT_TARGET_DIFFICULTY = 1;

    mapping(address => uint) public senderChallenges;

    constructor() public ERC777("Spark", "SPARK", new address[](0)) {
        // no premine, initial supply of 0, tokens can only
        // be create via proof of work submissions to the mint()
        // function per the ERC918 specification
    }

    // ERC918 getMiningTarget function
    function getMiningTarget() external view returns (uint256) {
        return MAXIMUM_TARGET;
    }

    // ERC918 getMiningReward function
    function getMiningReward() external view returns (uint256) {
        return getMiningDifficulty();
    }

    // ERC918 getMiningDifficulty function
    // the number of zeroes the digest of the PoW solution requires
    // minimum is 2**16
    function getMiningDifficulty() public view returns (uint256) {
        return DEFAULT_TARGET_DIFFICULTY;
    }

    // ERC918 getChallengeNumber function
    function getChallengeNumber() external view returns (bytes32) {
        return bytes32(senderChallenges[msg.sender]);
    }

    // get the challenge number for a certain address, useful for delegated mining
    function getChallengeNumber(address user) external view returns (uint) {
        return senderChallenges[user];
    }

    // get the mining difficulty of a nonce
    function getMiningDifficulty(uint nonce, uint targetDifficulty)
        public
        view
        returns (uint)
    {
        uint n = uint(
            keccak256(
                abi.encodePacked(
                    senderChallenges[msg.sender],
                    msg.sender,
                    nonce,
                    targetDifficulty
                )
            )
        );
        return MAXIMUM_TARGET.div(n);
    }

    // mint multiple solutions. Challenges can be calculated offchain by hash chaining them:
    // nextChallenge = keccak( currentChallenge )
    function mint(uint[] memory nonces, uint targetDifficulty)
        public
        returns (bool success)
    {
        for (uint i = 0; i < nonces.length; i++) {
            require(mint(nonces[i], targetDifficulty), "Unable to mint");
        }
        return true;
    }

    // mint function with variable difficulty
    function mint(uint nonce, uint targetDifficulty)
        public
        returns (bool success)
    {
        // derive solution hash n
        uint n = uint(
            keccak256(
                abi.encodePacked(
                    senderChallenges[msg.sender],
                    msg.sender,
                    nonce,
                    targetDifficulty
                )
            )
        );
        // check that the minimum difficulty is met
        require(n < MAXIMUM_TARGET, "Minimum difficulty not met");
        // check that the target difficulty is met
        require(n < targetDifficulty, "Target difficulty not met");

        // reward the target difficulty - the number of zeros on the PoW solution
        uint reward = targetDifficulty * 10**18;

        // update the challenge to prevent proof resubmission
        // proof challenges are simple counters
        senderChallenges[msg.sender] += 1;

        // perform the mint operation
        _mint(msg.sender, msg.sender, reward, "", "");
        return true;
    }
}
