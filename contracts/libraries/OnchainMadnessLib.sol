// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library OnchainMadnessLib {
    function validateAndScore(
        uint8[63] memory bets,
        uint8[63] memory results
    ) external pure returns (uint8[63] memory validation, uint8 points) {
        for (uint8 i = 0; i < 63; i++) {
            if (results[i] == 0) {
                validation[i] = 0; // Not yet played/no result
            } else if (bets[i] == results[i]) {
                validation[i] = 1; // Correct bet
                points++;
            } else {
                validation[i] = 2; // Wrong bet
            }
        }
        return (validation, points);
    }

    function calculatePrize(
        uint256 totalPot,
        uint256 potClaimed,
        uint256 sameScoredPlayers
    ) external pure returns (uint256) {
        if (sameScoredPlayers == 0) return 0;
        
        uint256 amount = totalPot / sameScoredPlayers;
        uint256 availableClaim = totalPot - potClaimed;

        // This is to avoid rounding errors that could leave some tokens unclaimed
        if (availableClaim < amount) {
            amount = availableClaim;
        }

        return amount;
    }

    /**
     * @dev Calculate shares for treasury and recipient
     * @param shareAmount The total share amount to split
     * @return treasuryShare The share amount for treasury
     * @return recipientShare The share amount for the recipient
     */
    function calculateShares(
        uint256 shareAmount
    ) external pure returns (uint256 treasuryShare, uint256 recipientShare) {
        treasuryShare = shareAmount / 2;
        recipientShare = shareAmount - treasuryShare;
        return (treasuryShare, recipientShare);
    }
}
