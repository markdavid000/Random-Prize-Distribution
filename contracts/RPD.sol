// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

error ALREADY_REGISTERED();
error NOT_REGISTERED();

contract RPD is VRFConsumerBase, Ownable {
    // Chainlink VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    bytes32 public requestId;
    // ERC20 token contract
    IERC20 tokenContract;

    // Participant structure
    struct Participant {
        uint256 entries;
        bool registered;
    }

    // Total number of participants
    uint256 public totalParticipants;

    // Number of winners and total prize
    uint256 public numberOfWinners;
    uint256 public totalPrize;


    // Keeping track of the participants and their address
    mapping(address => Participant) participants;

    // Event for logging prize distribution
    event PrizeDistributionEvent(address[] indexed winners, uint256[] indexed amounts);

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee, address _tokenAddress) VRFConsumerBase(_vrfCoordinator, _link) Ownable(msg.sender){
        keyHash = _keyHash;
        fee = _fee;
        tokenContract = IERC20(_tokenAddress);
    }

    // Register as a participant
    function register() external {
        if(participants[msg.sender].registered) {
            revert ALREADY_REGISTERED();
        }

        participants[msg.sender].registered = true;
        totalParticipants++;
    }

    // Participate in an activity to earn entries
    function participate(uint256 _entries) external {
        if(!participants[msg.sender].registered) {
            revert NOT_REGISTERED();
        }

        participants[msg.sender].entries += _entries;
    }

    // Trigger the prize distribution
    function prizeDistribution(uint256 _numberOfWinners, uint256 _totalPrize) external onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to fulfill randomness request");
        require(_numberOfWinners > 0 && _numberOfWinners <= 10, "Invalid Number of winners");
        require(_totalPrize > 0, "Total Price must be greater than 0");

        numberOfWinners = _numberOfWinners;
        totalPrize = _totalPrize;

        // Request random number from chainlink VRF
        requestRandomness(keyHash, fee);
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(_requestId == requestId, "Invalid request ID");
        randomResult = _randomness;

        // Select winners based on random number
        address[] memory winners = new address[](numberOfWinners);
        uint256[] memory prizes = new uint256[](totalPrize);

        uint256 remainingParticipants = totalParticipants;

        for (uint256 i = 0; i < numberOfWinners; i++) {
            uint256 winnerIndex = _randomness % remainingParticipants;


            // Find the winner by looping through participants
            for (uint256 j = 0; j < totalParticipants; j++) {
                // Convert the loop counter 'j' to an address using explicit type casting
                // This allows accessing the address in the mapping of participants
                address participantAddress = address(uint160(uint256(j)));

                if(!participants[participantAddress].registered) continue;

                if(winnerIndex == 0) {
                    winners[i] = participantAddress;
                    prizes[i] = prizeCalculation(participants[participantAddress].entries, totalPrize);

                    // Remove winner from list
                    delete participants[participantAddress];

                    totalParticipants--;
                    remainingParticipants--;
                    break;
                }

                winnerIndex--;
            }
            // Update random number for next iteration
            _randomness = uint256(keccak256(abi.encode(_randomness)));
        }

        // Distribute Prizes
        for(uint256 i; i < numberOfWinners; i++) {
            tokenContract.transfer(winners[i], prizes[i]);
        }

        // Emit event
        emit PrizeDistributionEvent(winners, prizes);
    }

    // Calculate prize for a winner
    function prizeCalculation(uint256 _entries, uint256 _totalPrize) internal pure returns (uint256) {
        // Simple distribution based on entries
        uint256 calculatedPrize = (_entries * _totalPrize) / _totalPrize;

        return calculatedPrize;
    }
}
