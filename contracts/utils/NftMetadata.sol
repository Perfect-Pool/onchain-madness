// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/IOnchainMadnessEntry.sol";

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

    function gameStatus(
        uint256 _gameYear
    ) public view returns (string memory) {
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
                                INftImage(
                                    madnessFactory.contracts("OM_IMAGE")
                                ).buildImage(_poolId, _gameYear, _tokenId),
                                '","attributes":[]}'
                            )
                        )
                    )
                )
            );
    }
}
