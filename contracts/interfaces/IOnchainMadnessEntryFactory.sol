// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOnchainMadnessEntryFactory {
    /**
     * @dev Gets the bet data for a specific token in a pool
     * @param _poolId The ID of the pool
     * @param _tokenId The ID of the token
     * @return The bet data array
     */
    function getBetData(
        uint256 _poolId,
        uint256 _tokenId
    ) external view returns (uint8[63] memory);

    /**
     * @dev Validates the bet data for a specific token in a pool
     * @param _poolId The ID of the pool
     * @param _tokenId The ID of the token
     * @return The validated bet data array and game year
     */
    function betValidator(
        uint256 _poolId,
        uint256 _tokenId
    ) external view returns (uint8[63] memory, uint256);

    /**
     * @dev Gets the pool address for a specific pool ID
     * @param _poolId The ID of the pool
     * @return The pool address
     */
    function getPoolAddress(uint256 _poolId) external view returns (address);

    /**
     * @dev Gets the pool ID for a specific pool address
     * @param _poolAddress The address of the pool
     * @return The pool ID
     */
    function getPoolId(address _poolAddress) external view returns (uint256);

    /**
     * @dev Gets the prize data for a specific token in a pool
     * @param _poolId The ID of the pool
     * @param _tokenId The ID of the token
     * @return amountToClaim The amount of USDC to be claimed
     * @return amountClaimed The amount of USDC already claimed
     */
    function amountPrizeClaimed(
        uint256 _poolId,
        uint256 _tokenId
    ) external view returns (uint256 amountToClaim, uint256 amountClaimed);

    /**
     * @dev Returns the created pool data
     * @param poolId The ID of the pool
     * @return name The name of the pool
     * @return poolAddress The address of the pool
     * @return isPrivate Whether the pool is private
     * @return isProtocol Whether the pool is created by the protocol
     * @return pin The PIN required to join the pool
     * @return creator The address of the creator of the pool
     */
    function getPoolData(
        uint256 poolId
    )
        external
        view
        returns (
            string memory name,
            address poolAddress,
            bool isPrivate,
            bool isProtocol,
            bytes memory pin,
            address creator
        );
}
