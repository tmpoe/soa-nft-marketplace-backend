// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftCatAttributes is VRFConsumerBaseV2, Ownable {
    enum Breed {
        Ragdoll,
        Sphynx,
        Persian,
        numberOfBreeds
    }
    enum Color {
        blue,
        yellow,
        grey,
        red,
        numberOfColors
    }

    enum Rarity {
        mythic,
        legendary,
        epic,
        rare,
        uncommon,
        common,
        numberOfRarities
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 4;
    uint256[] private rarity_values = new uint256[](6);

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    mapping(uint256 => address) public s_requestIdToSender;

    event NftCatAttributesRequested(uint256 requestId, address requester);
    event NftCatAttributesCreated(
        uint256 requestId,
        address requester,
        Breed breed,
        Color eyecolor,
        uint256 playfulness,
        uint256 cuteness,
        Rarity rarity
    );

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        rarity_values = [9900, 9600, 9100, 8100, 6600];
    }

    function requestCatAttributes(address owner) external onlyOwner returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = owner;
        emit NftCatAttributesRequested(requestId, owner);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address owner = s_requestIdToSender[requestId];
        uint256 breedIndex = randomWords[0] % uint256(Breed.numberOfBreeds);
        uint256 eyeColorIndex = randomWords[1] % uint256(Color.numberOfColors);
        uint256 playfulness = randomWords[2] % 100;
        uint256 cuteness = randomWords[3] % 100;
        Rarity rarity = getRarity(playfulness * cuteness);

        emit NftCatAttributesCreated(
            requestId,
            owner,
            Breed(breedIndex),
            Color(eyeColorIndex),
            playfulness,
            cuteness,
            rarity
        );
    }

    function getRarity(uint256 rarity) public view returns (Rarity) {
        for (uint256 i = 0; i < rarity_values.length; i++) {
            if (rarity > rarity_values[i]) {
                return Rarity(i);
            }
        }
        return Rarity(5);
    }
}
