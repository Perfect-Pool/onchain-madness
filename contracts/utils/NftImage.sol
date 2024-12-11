// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../libraries/BuildImage.sol";
import "../interfaces/IOnchainMadnessFactory.sol";
import "../interfaces/IOnchainMadnessEntryFactory.sol";

contract NftImage {
    using Strings for uint16;
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

    function buildImage(
        uint256 _poolId,
        uint256 _gameYear,
        uint256 _tokenId
    ) public view returns (string memory) {
        (uint8[63] memory bets, ) = IOnchainMadnessEntryFactory(
            madnessFactory.contracts("OM_ENTRY_DEPLOYER")
        ).betValidator(_poolId, _tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                BuildImage.fullSvgImage(
                                    bets,
                                    madnessFactory.getTeamSymbols(
                                        _gameYear,
                                        IOnchainMadnessEntryFactory(
                                            madnessFactory.contracts(
                                                "OM_ENTRY_DEPLOYER"
                                            )
                                        ).getBetData(_poolId, _tokenId)
                                    ),
                                    _tokenId
                                )
                            )
                        )
                    )
                )
            );
    }
}
