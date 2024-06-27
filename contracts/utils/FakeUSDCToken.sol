// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FakeUSDCToken is ERC20, ERC20Permit {
    constructor()
        ERC20("FakeUSDCToken", "USDC.f")
        ERC20Permit("FakeUSDCToken")
    {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
