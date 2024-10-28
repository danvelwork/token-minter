// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlockMintedToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxSupply = 21_000_000 * 10**18; // Cap at 21 million tokens
    uint256 public constant rewardAmount = 50 * 10**18; // Reward 50 tokens per interval
    uint256 public rewardInterval = 20; // 20-second reward interval

    uint256 public lastMintTime;
    mapping(address => bool) public hasDelegated;
    address[] public participants;

    event Debug(uint256 intervalsPassed, uint256 lastMintTime, uint256 participantsCount);

    constructor() ERC20("BlockMintedToken", "BMT") Ownable(msg.sender) {
        lastMintTime = block.timestamp; // Initialize last mint time to contract deployment time
    }

    // Delegate 1 ETH to participate in mining rewards
    function delegate() external payable {
        require(msg.value == 1 ether, "Must delegate exactly 1 ETH");
        require(!hasDelegated[msg.sender], "Already delegated");

        hasDelegated[msg.sender] = true;
        participants.push(msg.sender);
    }

    // Mint rewards based on the number of 20-second intervals passed
    function mintReward() external {
        require(participants.length > 0, "No participants");

        // Calculate how many reward intervals have passed
        uint256 intervalsPassed = (block.timestamp - lastMintTime) / rewardInterval;
        require(intervalsPassed > 0, "Reward interval not reached");

        uint256 totalMintableRewards = intervalsPassed * rewardAmount;

        // Ensure we don't exceed the max supply
        require(totalSupply().add(totalMintableRewards) <= maxSupply, "Max supply reached");

        emit Debug(intervalsPassed, lastMintTime, participants.length); // Emit debug info

        // Mint one reward per interval passed
        for (uint256 i = 0; i < intervalsPassed; i++) {
            // Re-calculate random selection within each iteration using i for independent randomness
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants, i))) % participants.length;
            address winner = participants[randomIndex];

            // Mint reward tokens to the winner
            _mint(winner, rewardAmount);
        }

        // Update last mint time to reflect the intervals processed
        lastMintTime = block.timestamp;
    }

    // Check participant balance
    function checkBalance(address participant) external view returns (uint256) {
        return balanceOf(participant);
    }

    // View total number of participants
    function getParticipants() external view returns (uint256) {
        return participants.length;
    }

    // Withdraw 1 ETH delegation (for testing purposes)
    function withdrawDelegation() external {
        require(hasDelegated[msg.sender], "No delegation to withdraw");

        hasDelegated[msg.sender] = false;
        payable(msg.sender).transfer(1 ether);
    }

    // Helper function to view all participants (optional for testing)
    function getParticipantList() external view returns (address[] memory) {
        return participants;
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
