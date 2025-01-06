// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../libraries/BuildImage.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/IOnchainMadnessEntryFactory.sol";

interface INftImage {
    function buildImage(
        uint256 _poolId,
        uint256 _tokenId,
        string[63] memory betTeamNames,
        uint8[63] memory bets
    ) external view returns (string memory);
}

interface IBetCheck {
    function getBetResults(
        uint256 year,
        uint8[63] memory bets
    )
        external
        view
        returns (
            string[63] memory betTeamNames,
            uint8[63] memory betResults,
            uint8 points
        );
}

contract NftMetadata {
    using Strings for uint8;
    using Strings for uint256;

    IOnchainMadnessFactory public madnessFactory;

    constructor(address _madnessFactory) {
        madnessFactory = IOnchainMadnessFactory(_madnessFactory);
    }

    modifier onlyAdmin() {
        require(madnessFactory.owner() == msg.sender, "Caller is not admin");
        _;
    }

    function setDeployer(address _factory) public onlyAdmin {
        madnessFactory = IOnchainMadnessFactory(_factory);
    }

    function gameStatus(uint256 _gameYear) public view returns (string memory) {
        (, uint8 status) = abi.decode(
            madnessFactory.getGameStatus(_gameYear),
            (uint256, uint8)
        );
        if (status == 1) {
            return "Bets Open";
        } else if (status == 2) {
            return "On Going";
        } else {
            return "Finished";
        }
    }

    function buildMetadata(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _tokenId
    ) public view returns (string memory) {
        IOnchainMadnessEntryFactory entryFactory = IOnchainMadnessEntryFactory(
            madnessFactory.contracts("OM_ENTRY_DEPLOYER")
        );
        IBetCheck betCheck = IBetCheck(madnessFactory.contracts("BET_CHECK"));

        (
            string[63] memory betTeamNames,
            uint8[63] memory betResults,
            uint8 points
        ) = betCheck.getBetResults(
                _gameYear,
                entryFactory.getBetData(_poolId, _tokenId)
            );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Onchain Madness Entry #',
                                _tokenId.toString(),
                                '","description":"Onchain Madness NFT from PerfectPool.","image":"',
                                INftImage(madnessFactory.contracts("OM_IMAGE"))
                                    .buildImage(
                                        _poolId,
                                        _tokenId,
                                        betTeamNames,
                                        betResults
                                    ),
                                '","attributes":[{"trait_type":"Game Year","value":"',
                                _gameYear.toString(),
                                '"},{"trait_type":"Points","value":"',
                                points.toString(),
                                '"},]}'
                            )
                        )
                    )
                )
            );
    }
}