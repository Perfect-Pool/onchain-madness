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

    /**
     * @notice Get the current day
     * @dev Uses timestamp to calculate current day, optimized for gas
     * @return year The current year (e.g., 2024)
     * @return month The current month (e.g., 1-12)
     * @return day The current day (e.g., 1-31)
     */
    function getCurrentDate()
        public
        view
        returns (uint256 year, uint256 month, uint256 day)
    {
        unchecked {
            uint256 timestamp = block.timestamp;
            uint256 z = timestamp / 86400 + 719468;
            uint256 era = z / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;

            day = uint8(doy - (153 * mp + 2) / 5 + 1);
            month = uint8(mp < 10 ? mp + 3 : mp - 9);
            year = uint16(yoe + era * 400 + 1);
        }
    }
}
