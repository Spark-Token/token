pragma solidity ^0.5.1;

interface ERC918 {
    function mint(uint256 nonce) external returns (bool success);

    function getChallengeNumber() external view returns (bytes32);

    function getMiningDifficulty() external view returns (uint256);

    function getMiningTarget() external view returns (uint256);

    function getMiningReward() external view returns (uint256);
}