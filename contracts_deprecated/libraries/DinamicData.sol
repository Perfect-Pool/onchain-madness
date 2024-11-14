// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library DinamicData {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    function buildBetSquare(
        uint16 x,
        uint16 y,
        string memory teamName,
        uint8 status
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text font-family="Arial" font-size="11px">',
                    '<tspan x="',
                    (x + 44).toString(),
                    '" y="',
                    (y + 14).toString(),
                    '" fill="white">',
                    teamName,
                    "</tspan>",
                    "</text>",
                    '<circle cx="',
                    (x + 86).toString(),
                    '" cy="',
                    (y + 10).toString(),
                    '" r="3" fill="#',
                    (
                        status == 0 ? "808080" : status == 1
                            ? "7ED321"
                            : "FF2E47"
                    ),
                    '" />'
                )
            );
    }

    function nftIdSquare(uint256 nftId) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="221.5" y="866.5" width="100" height="23" rx="4.5" fill="#1B2236" stroke="#1C253C" />',
                    '<text font-family="Arial" font-size="12px">',
                    '<tspan x="230" y="881.5" fill="#98A1C0">NFT ID:</tspan></text>',
                    '<text font-family="Arial" font-size="11px">',
                    '<tspan x="275" y="881.5" fill="white">',
                    nftId.toString(),
                    "</tspan></text>"
                )
            );
    }
}
