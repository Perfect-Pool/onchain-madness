// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Base64.sol";
import "../interfaces/IMarchMadnessFactory.sol";
import "../interfaces/IGamesHub.sol";
import "../interfaces/IOnchainMadnessTicket.sol";

interface INftImage {
    function buildImage(
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
        uint256 _gameId,
        uint256 _tokenId
    ) public view returns (string memory) {
        (, uint8 status) = abi.decode(
            IMarchMadnessFactory(gamesHub.games(keccak256("MM_DEPLOYER")))
                .getGameStatus(_gameId),
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
                        IMarchMadnessFactory(
                            gamesHub.games(keccak256("MM_DEPLOYER"))
                        ).getFinalResult(_gameId)
                    )
                ) ==
                keccak256(
                    abi.encodePacked(
                        IOnchainMadnessTicket(
                            gamesHub.helpers(keccak256("MM_TICKET"))
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
        uint256 _gameId,
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
                                    gamesHub.helpers(keccak256("MM_IMAGE"))
                                ).buildImage(_tokenId),
                                '","attributes":[{"trait_type":"Game Status:","value":"',
                                gameStatus(_gameId, _tokenId),
                                '"},]}'
                            )
                        )
                    )
                )
            );
    }
}
