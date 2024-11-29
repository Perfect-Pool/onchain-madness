// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Base64.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/IGamesHub.sol";
import "../interfaces/IOnchainMadnessTicket.sol";

interface INftImage {
    function buildImage(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _tokenId
    ) external view returns (string memory);
}

contract NftMetadata {
    using Strings for uint8;
    using Strings for uint256;

    IGamesHub public gamesHub;

    constructor(address _gamesHub) {
        gamesHub = IGamesHub(_gamesHub);
    }

    function gameStatus(
        uint256 _gameYear,
        uint256 _tokenId
    ) public view returns (string memory) {
        (, uint8 status) = abi.decode(
            IOnchainMadnessFactory(gamesHub.games(keccak256("OM_DEPLOYER")))
                .getGameStatus(_gameYear),
            (uint256, uint8)
        );
        if (status == 1) {
            return "Bets Open";
        } else if (status == 2) {
            return "On Going";
        } else {
            if (
                keccak256(
                    abi.encodePacked(
                        IOnchainMadnessFactory(
                            gamesHub.games(keccak256("OM_DEPLOYER"))
                        ).getFinalResult(_gameYear)
                    )
                ) ==
                keccak256(
                    abi.encodePacked(
                        IOnchainMadnessTicket(
                            gamesHub.helpers(keccak256("OM_TICKET"))
                        ).getBetData(_tokenId)
                    )
                )
            ) {
                return "Winner";
            } else {
                return "Loser";
            }
        }
    }

    function buildMetadata(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _tokenId
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Madness Ticket #',
                                _tokenId.toString(),
                                '","description":"Onchain Madness NFT from PerfectPool.","image":"',
                                INftImage(
                                    gamesHub.helpers(keccak256("OM_IMAGE"))
                                ).buildImage(_poolId, _gameYear, _tokenId),
                                '","attributes":[{"trait_type":"Game Status:","value":"',
                                gameStatus(_gameYear, _tokenId),
                                '"},]}'
                            )
                        )
                    )
                )
            );
    }
}
