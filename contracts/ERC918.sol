pragma solidity ^0.5.1;

interface ERC918 {
    function mint(uint nonce, uint targetDifficulty) external returns (bool success);

    function getChallengeNumber() external view returns (bytes32);

    function getMiningDifficulty() external view returns (uint);

    function getMiningTarget() external view returns (uint);

    function getMiningReward() external view returns (uint);
}