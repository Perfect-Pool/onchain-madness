// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RegionsData.sol";
import "./FixedData.sol";

library BuildImage {
    function fullSvgImage(
        uint8[63] memory betValidator,
        string[63] memory tokens,
        uint256 tokenId,
        uint256 poolId,
        string memory poolName,
        string memory prize,
        bool claimed
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    FixedData.svgPartUp(),
                    FixedData.middle(),
                    RegionsData.regionEast(betValidator, tokens),
                    RegionsData.regionSouth(betValidator, tokens),
                    RegionsData.regionWest(betValidator, tokens),
                    RegionsData.regionMidWest(betValidator, tokens),
                    RegionsData.finalFour(betValidator, tokens),
                    DinamicData.nftIdSquare(tokenId, poolId, poolName, prize, claimed),
                    FixedData.svgPartDown()
                )
            );
    }

    function formatPrize(
        string memory prize
    ) public pure returns (string memory) {
        uint256 len = bytes(prize).length;
        string memory normalizedPrize = len < 6
            ? appendZeros(prize, 6 - len)
            : prize;

        string memory integerPart = len > 6
            ? substring(normalizedPrize, 0, len - 6)
            : "0";
        string memory decimalPart = substring(
            normalizedPrize,
            len > 6 ? len - 6 : 0,
            2
        );

        return string(abi.encodePacked(integerPart, ".", decimalPart));
    }

    function substring(
        string memory str,
        uint startIndex,
        uint length
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(length);

        for (uint i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }

        return string(result);
    }

    function appendZeros(
        string memory str,
        uint numZeros
    ) private pure returns (string memory) {
        bytes memory zeros = new bytes(numZeros);
        for (uint i = 0; i < numZeros; i++) {
            zeros[i] = "0";
        }
        return string(abi.encodePacked(zeros, str));
    }
}
