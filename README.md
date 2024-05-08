# Ignition Staking 2.0

New Ignition 2.0 staking contract. Simple `deposit` and `withdraw` mechanics
with a `tax` set that goes to a destination `treasury` wallet on both desposits and withdraws of staked tokens.

## Highlevel Overview of functionality

The goal of this smart contract is to provide a simple staking contract that
that will `mint` or `burn` a derivative token `sPAID` to users wallets on
`desposit` and `withdraw` respectively.

We can then use the balance of the `sPAID` token to provide top holders/stakers
and provide rewards, airdrops, and voting power in the future.

### Deposit

The sender wallet will call the `desposit` function to deposit an `amount` of PAID tokens. This will have `tax` added on top of the `amount` for the total
transfer.

Example. A user deposits 75000 `PAID` tokens. The tax is set to the default `2%`. They will transfer a total of 765000 `PAID` tokens. 1500 `PAID` tokens will go to the `treasury` wallet, and 75000 `PAID` tokens will be transfered to
the `SPAID` contract. The same amount of tokens will be minted as `sPAID` tokens
into the sender wallet address.

### Withdraws

When a user is ready to unstake their tokens, they can call the `withdraw` function with the `amount` they would like to unstake. The following happens:

1. The `amount` of `sPAID` is burned.
2. The `amount` is taxed at the rate if `tax` and subtracted from `amount`
3. The remaining `amount` is transferred back to the sender wallet address.

Example. User had already deposited 75000 `PAID` tokens. User calls the `withdraw` function with `amount` of 75000. 1500 `PAID` goes to treasury as `tax`. 73500 `PAID` goes back to user.

### Owner functionality

There are 3 functions that only the owner of the contract can call:

`setTax` - This will update the current tax of both `desposit` and `withdraw`. It must be in the range of 1 - 10.

`setTreasury` - This updates the `treasury` wallet. All `tax` is sent to this wallet address.

`withdrawAllStaked` - In case we decide that we no longer want to use this contract, we need a way to withdraw any remaining tokens from the contract without being taxed via the `tax` amount. We then can decide to airdrop tokens
back to users for example.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

To see all the logs and traces use the following:

```shell
$ forge test -vvvv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Help

```shell
$ forge --help
```
