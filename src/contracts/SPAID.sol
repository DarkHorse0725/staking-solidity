// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {ERC20} from "../../lib/solady/src/tokens/ERC20.sol";
import {Ownable} from "../../lib/solady/src/auth/Ownable.sol";
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SPAID is ERC20, Ownable {
    using SafeERC20 for IERC20;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Zero address is not allowed.
    error ZeroAddressNotAllowed();

    /// @dev The caller provided amount is out of range.
    error InvalidAmount();

    /// @dev The caller provided tax amount is out of range.
    error InvalidTaxAmount();

    /// @dev There is not enough PAID tokens for transfer.
    error InsufficientPAIDBalance();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Tax was updated to `amount` by `owner`.
    /// This event is emitted anytime `setTax` is called by the `owner`.
    event TaxUpdated(address indexed owner, uint256 amount);

    /// @dev Treasury wallet was updated to `treasuryAddress` by `owner`.
    /// This event is emitted anytime `setTreasury` is called by the `owner`.
    event TreasuryUpdated(address indexed owner, address treasuryAddress);

    /// @dev A deposit of `amount` was made by `user`.
    /// This event is emitted anytime a `deposit` is made by a user.
    event Deposit(address indexed user, uint256 amount);

    /// @dev A withdraw of `amount` was made by `user`.
    /// This event is emitted anytime a `withdraw` is made by a user.
    event Withdraw(address indexed user, uint256 amount);

    /// @dev All staked PAID tokens of `amount` was withdrawn by
    /// `user`, which will be the owner.
    ///
    /// This event is emitted anytime `withdrawAllStaked` is called
    /// by the owner.
    event WithdrawStakedPAID(address indexed user, uint256 amount);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `tokenPAID` points to the PAID token.
    /// Provided in constructor.
    ///
    /// *Immutable*
    IERC20 public immutable tokenPAID;

    /// @dev `treasury` points to the current treasury wallet.
    /// Provided in constructor.
    ///
    /// Can be updated by using `setTreasury` function.
    address public treasury;

    /// @dev `tax` is the current tax amount.
    /// Provided in constructor.
    ///
    /// Can be updated by using `setTax` function.
    uint8 public tax;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Intialize new SPAID contract with the following params:
    /// `tokenPAID_` - address of PAID token
    /// `treasury_` - The address of the treasury wallet.
    ///     All `tax` will go to this wallet.
    /// `tax_` - The amount of tax to add on deposit or subtract on withdraw.
    constructor(address tokenPAID_, address treasury_, uint8 tax_) {
        if (tokenPAID_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (treasury_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (tax_ == 0 || tax_ > 10) {
            revert InvalidTaxAmount();
        }
        _initializeOwner(msg.sender);
        tokenPAID = IERC20(tokenPAID_);
        tax = tax_;
        treasury = treasury_;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC/EXTERNAL FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets `tax_` as the new tax amount for deposit and withdraws.
    /// `_tax` must be in a range of 1 - 10.
    function setTax(uint8 tax_) external onlyOwner {
        if (tax_ == 0 || tax_ > 10) {
            revert InvalidTaxAmount();
        }
        tax = tax_;
        emit TaxUpdated(msg.sender, tax_);
    }

    /// @dev Sets `treasury_` as the new treasury wallet address for taxes.
    function setTreasury(address treasury_) external onlyOwner {
        if (treasury_ == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        treasury = treasury_;
        emit TreasuryUpdated(msg.sender, treasury_);
    }

    /// @dev Returns the `name` of the token.
    function name() public view virtual override returns (string memory) {
        return "Staked PAID";
    }

    /// @dev Returns the `symbol` of the token.
    function symbol() public view virtual override returns (string memory) {
        return "sPAID";
    }

    /// @dev Deposit `amount` of PAID tokens and mint same amount in `sPAID` token.
    /// The total transfer will be `amount` + (`amount` * `tax`).
    ///
    /// Emits a {Deposit} event.
    function deposit(uint256 amount) external {
        if (amount == 0) {
            revert InvalidAmount();
        }

        uint256 fee = amount * tax / 100;
        if (tokenPAID.balanceOf(msg.sender) < amount + fee) {
            revert InsufficientPAIDBalance();
        }

        tokenPAID.safeTransferFrom(msg.sender, treasury, fee);
        tokenPAID.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    /// @dev Withdraw `amount` of PAID tokens and burn same amount of `sPAID` tokens
    /// The amount being withdrawn will have `tax` deducted.
    ///
    /// Emits a {Withdraw} event.
    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (tokenPAID.balanceOf(address(this)) < amount) {
            revert InsufficientPAIDBalance();
        }
        uint256 fee = amount * tax / 100;
        tokenPAID.safeTransfer(treasury, fee);
        tokenPAID.safeTransfer(msg.sender, amount - fee);
        _burn(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @dev Withdraw all currently staked PAID tokens in the contract.
    ///
    /// Emits a {WithdrawStakedPAID} event.
    function withdrawAllStaked() external onlyOwner {
        uint256 paidBalance = tokenPAID.balanceOf(address(this));
        if (paidBalance == 0) {
            revert InsufficientPAIDBalance();
        }
        tokenPAID.safeTransfer(msg.sender, paidBalance);
        emit WithdrawStakedPAID(msg.sender, paidBalance);
    }
}
