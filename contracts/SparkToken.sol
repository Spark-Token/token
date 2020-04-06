pragma solidity ^0.5.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ERC918.sol";

contract SparkToken is ERC20, ERC20Detailed, ERC918 {
    using SafeMath for uint256;
    uint public timeOfLastProof;
    uint256 public MINIMUM_TARGET = 2**16;
    uint256 public MAXIMUM_TARGET = 2**234;

    mapping (address => bytes32) public senderChallenges;

    constructor() public ERC20Detailed("Spark Token", "SPARK", 0) {
        // no premine, initial supply of 0, tokens can only
        // be create via proof of work submissions to the mint()
        // function per the ERC918 specification

        // initialize the proof timer
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
    // minimum is 1
    function getMiningDifficulty() public view returns (uint256) {
        return 1;
    }

    // ERC918 getChallengeNumber function
    function getChallengeNumber() external view returns (bytes32) {
        return senderChallenges[msg.sender];
    }

    // get the challenge number for a certain address, useful for delegated mining
    function getChallengeNumber(address user) external view returns (bytes32) {
        return senderChallenges[user];
    }

    function getMiningDifficulty(uint nonce) public view returns (uint) {
        uint n = uint(
            keccak256(abi.encodePacked(senderChallenges[msg.sender], msg.sender, nonce))
        );
        return MAXIMUM_TARGET.div(n);
    }

    // ERC918 mint function
    function mint(uint nonce) public returns (bool success) {
        // prevent gas racing by setting the maximum gas price to 5 gwei
        require(tx.gasprice < 5 * 1000000000);

        // derive solution hash n
        uint n = uint(
            keccak256(abi.encodePacked(senderChallenges[msg.sender], msg.sender, nonce))
        );
        // check that the minimum difficulty is met
        require(n < MAXIMUM_TARGET, "Minimum difficulty not met");

        // reward the mining difficulty - the number of zeros on the PoW solution
        uint reward = MAXIMUM_TARGET.div(n);
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
