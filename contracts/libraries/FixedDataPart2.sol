// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";

library FixedDataPart2 {
    function eastTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="421" y="163">East</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="163">Round 1</text>',
                    '<rect x="72" y="172" width="349" height="166" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="372">Round 2</text>',
                    '<rect x="72" y="381" width="349" height="87" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="502">Round 3</text>',
                    '<rect x="72" y="511" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }

    function westTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="778" y="163">West</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="163">Round 1</text>',
                    '<rect x="429" y="172" width="349" height="166" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="372">Round 2</text>',
                    '<rect x="429" y="381" width="349" height="87" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="502">Round 3</text>',
                    '<rect x="429" y="511" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }

    function southTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="421" y="673">South</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="673">Round 1</text>',
                    '<rect x="72" y="682" width="349" height="166" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="882">Round 2</text>',
                    '<rect x="72" y="891" width="349" height="87" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="1012">Round 3</text>',
                    '<rect x="72" y="1021" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }

    function midwestTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="778" y="673">Midwest</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="673">Round 1</text>',
                    '<rect x="429" y="682" width="349" height="166" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="882">Round 2</text>',
                    '<rect x="429" y="891" width="349" height="87" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="429" y="1012">Round 3</text>',
                    '<rect x="429" y="1021" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }

    function finalFourTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" x="72" y="592">Final Four</text>',
                    '<rect x="72" y="601.5" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" x="429" y="592">Final Four</text>',
                    '<rect x="429" y="601.5" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }

    function finalsTop() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="778" y="1102">Finals</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="1102">Round 1</text>',
                    '<rect x="429" y="1111.5" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<rect x="72" y="1111.5" width="349" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />',
                    '<text style="font-size:14px;fill:#FBBF24;font-family:Arial;font-weight:800" text-anchor="end" x="778" y="1179">Last Match</text>',
                    '<text style="font-size:14px;fill:white;font-family:Arial;font-weight:800" x="72" y="1179">Round 2</text>',
                    '<rect x="72" y="1184.75" width="706" height="47.5" rx="8" fill="#202738" fill-opacity="0.34" />'
                )
            );
    }
}
