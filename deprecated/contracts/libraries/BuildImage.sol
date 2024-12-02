// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RegionsData.sol";
import "./FixedData.sol";

library BuildImage {
    function fullSvgImage(
        uint8[63] memory betValidator,
        string[63] memory tokens,
        uint256 tokenId
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    FixedData.svgPartUp(),
                    RegionsData.regionEast(betValidator, tokens),
                    RegionsData.regionSouth(betValidator, tokens),
                    RegionsData.regionWest(betValidator, tokens),
                    RegionsData.regionMidWest(betValidator, tokens),
                    RegionsData.finalFour(betValidator, tokens),
                    DinamicData.nftIdSquare(tokenId),
                    FixedData.svgPartDown()
                )
            );
    }
}
//https://nftstorage.link/ipfs/bafkreiblsdf2cyvdmmnzvtvdtsyj3gcscarmdnryljppllt3za3w3dg52m
//https://perfect-pool-dev-public.s3.amazonaws.com/marchmadness/images/fundo.svg
