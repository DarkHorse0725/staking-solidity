pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {SPAID} from "../src/contracts/SPAID.sol";

contract StakingDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address paidToken = vm.envAddress("PAID_TOKEN_ADDRESS");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address newOwner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        SPAID stakingContract = new SPAID(
            paidToken,
            treasury,
            2
        );

       stakingContract.transferOwnership(newOwner);

        vm.stopBroadcast();
    }
}
