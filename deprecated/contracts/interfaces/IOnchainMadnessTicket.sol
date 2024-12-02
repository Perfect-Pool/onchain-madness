// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOnchainMadnessTicket {
    function betValidator(uint256 _tokenId) external view returns (uint8[63] memory);

    function getTeamSymbols(uint256 _tokenId)
        external
        view
        returns (string[63] memory);

    function getGameYear(uint256 _tokenId) external view returns (uint256);

    function getBetData(uint256 _tokenId) external view returns (uint256[63] memory);
}