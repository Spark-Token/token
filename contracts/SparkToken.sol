pragma solidity ^0.5.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ERC918.sol";

contract SparkToken is ERC20, ERC20Detailed, ERC918 {
    using SafeMath for uint;
    uint public timeOfLastProof;
    uint public MINIMUM_TARGET = 2**16;
    uint public MAXIMUM_TARGET = 2**234;
    uint public DEFAULT_TARGET_DIFFICULTY = 2**16;

    mapping (address => bytes32) public senderChallenges;

    constructor() public ERC20Detailed("Spark Token", "SPARK", 0) {
        // no premine, initial supply of 0, tokens can only
        // be create via proof of work submissions to the mint()
        // function per the ERC918 specification

        // initialize the proof timer for the default mint function
        timeOfLastProof = now;
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
        return senderChallenges[msg.sender];
    }

    // get the challenge number for a certain address, useful for delegated mining
    function getChallengeNumber(address user) external view returns (bytes32) {
        return senderChallenges[user];
    }

    // get the mining difficulty of a nonce
    function getMiningDifficulty(uint nonce, uint targetDifficulty) public view returns (uint) {
        uint n = uint(
            keccak256(abi.encodePacked(senderChallenges[msg.sender], msg.sender, nonce, targetDifficulty))
        );
        return MAXIMUM_TARGET.div(n);
    }

    // default ERC918 mint function using relavtively small default target difficulty
    function mint(uint nonce) public returns (bool success) {
        // add time based throttle to default mint since difficulty is low 
        uint timeSinceLastProof = (now - timeOfLastProof);
        require(timeSinceLastProof >  5 seconds);
        timeOfLastProof = now;
        return mint(nonce, DEFAULT_TARGET_DIFFICULTY);
    }

    // mint function with variable difficulty
    function mint(uint nonce, uint targetDifficulty) public returns (bool success) {
        // prevent gas racing by setting the maximum gas price to 5 gwei
        require(tx.gasprice < 5 * 1000000000);

        // derive solution hash n
        uint n = uint(
            keccak256(abi.encodePacked(senderChallenges[msg.sender], msg.sender, nonce, targetDifficulty))
        );
        // check that the minimum difficulty is met
        require(n < MAXIMUM_TARGET, "Minimum difficulty not met");

        // reward the target difficulty - the number of zeros on the PoW solution
        uint reward = targetDifficulty;
        // emit Mint Event
        emit Mint(msg.sender, reward, 0, senderChallenges[msg.sender]);
        // update the challenge to prevent proof resubmission
        senderChallenges[msg.sender] = keccak256(
            abi.encodePacked(
                nonce,
                senderChallenges[msg.sender],
                now,
                blockhash(block.number - 1)
            )
        );

        // perform the mint operation
        _mint(msg.sender, reward);
        return true;
    }
}
