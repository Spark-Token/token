pragma solidity ^0.5.1;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "./ERC918.sol";


contract SparkToken is ERC777, ERC918 {
    using SafeMath for uint256;
    uint256 public MAXIMUM_TARGET = 2**234;

    mapping(address => uint256) public senderChallenges;

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
    // placeholder for compatibility, cannot be used
    function getMiningDifficulty() public view returns (uint256) {
        return 1;
    }

    // ERC918 getChallengeNumber function
    function getChallengeNumber() external view returns (bytes32) {
        return bytes32(senderChallenges[msg.sender]);
    }

    // get the challenge number for a certain address, useful for delegated mining
    function getChallengeNumber(address user) external view returns (bytes32) {
        return bytes32(senderChallenges[user]);
    }

    // validate a solution
    function validate(uint256 nonce, uint256 targetDifficulty)
        public
        view
        returns (bool)
    {
        uint256 n = uint256(
            keccak256(
                abi.encodePacked(
                    senderChallenges[msg.sender],
                    uint256(msg.sender) ^
                    targetDifficulty ^
                    uint256(address(this)),
                    nonce
                )
            )
        );
        return n < MAXIMUM_TARGET.div(targetDifficulty);
    }

    // mint multiple solutions. Challenges can be calculated offchain by incrementing challenges by 1
    function mint(uint256[] memory nonces, uint256 targetDifficulty)
        public
        returns (bool success)
    {
        for (uint256 i = 0; i < nonces.length; i++) {
            require(mint(nonces[i], targetDifficulty), "Unable to mint");
        }
        return true;
    }

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
                    uint256(msg.sender) ^
                    targetDifficulty ^
                    uint256(address(this)),
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
}
