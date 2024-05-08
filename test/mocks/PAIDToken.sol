pragma solidity 0.8.19;

import {ERC20 as SMERC20} from "@solmate/tokens/ERC20.sol";

contract PAIDToken is SMERC20 {
    constructor() SMERC20("PAID Network", "PAID", 18) {
        _mint(msg.sender, 500000000 * 10 ** 18);
    }
}
