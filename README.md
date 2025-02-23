# stx2btc

A example Rust library for converting between Stacks (STX) and Bitcoin (BTC) native SegWit addresses.

## WARNING

This library is only a proof concept example. Do not use in production.

## Features

- Convert Stacks addresses to Bitcoin native SegWit addresses (P2WPKH)
- Convert Bitcoin native SegWit addresses back to Stacks addresses (P2WPKH only)
- Maintains the same underlying HASH160 between address formats
- Only supports mainnet addresses
