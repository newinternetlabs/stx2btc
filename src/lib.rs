// SPDX-License-Identifier: MIT
// Copyright 2025 New Internet Labs Limited
#![doc = include_str!("../README.md")]

use bech32::{hrp, segwit};
use c32address::{decode_address, encode_address};

/// Converts a Stacks (STX) address to a Bitcoin (BTC) native SegWit address
///
/// This function takes a Stacks address (starting with 'SP' for mainnet),
/// decodes it to get the underlying HASH160 (20 bytes), and creates a native
/// SegWit address (starting with 'bc1' for mainnet) using that same HASH160.
///
/// Only supports conversion to P2WPKH (Pay to Witness Public Key Hash) addresses.
#[uniffi::export]
pub fn stx2btc(stx_address: &str) -> Result<String, ConversionError> {
    // Decode the Stacks address, handling the Result
    let (_decoded_version, decoded_bytes) =
        decode_address(stx_address).expect("Failed to decode address");

    // we should use the proper hrp for the stacks address network (mainnet, testnet, etc)
    let segwit_address = segwit::encode_v0(hrp::BC, &decoded_bytes)?;

    Ok(segwit_address)
}

/// Converts a Bitcoin (BTC) native SegWit address to a Stacks (STX) address
///
/// This function takes a Bitcoin native SegWit address (starting with 'bc1' for mainnet),
/// decodes it to get the underlying witness program (HASH160) for version 0 addresses, and
/// creates a Stacks address using that same HASH160
///
/// Only supports P2WPKH (version 0) addresses because P2TR (version 1) addresses use
/// different underlying data that can't be converted to a Stacks address format without the original public key.
#[uniffi::export]
pub fn btc2stx(btc_address: &str) -> Result<String, ConversionError> {
    let (_hrp, _version, decoded_bytes) = segwit::decode(btc_address)?;

    // Only handle version 0 (P2WPKH) addresses because we can't generate a taproot address without
    // the original public key (decoding the stacks address gives us only the 20 byte HASH160)
    if _version.to_u8() != 0 {
        return Err(ConversionError::UnsupportedVersion);
    }

    // we should use the proper version for the stacks address network (mainnet, testnet, etc)
    let version = 22;
    let stx_address = encode_address(version, &decoded_bytes).expect("Failed to decode address");
    Ok(stx_address)
}

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum ConversionError {
    #[error("Segwit decode error: {0}")]
    SegwitDecode(String),
    #[error("Unsupported version")]
    UnsupportedVersion,
    #[error("Segwit encode error: {0}")]
    SegwitEncode(String),
}

impl From<segwit::DecodeError> for ConversionError {
    fn from(err: segwit::DecodeError) -> Self {
        ConversionError::SegwitDecode(err.to_string())
    }
}

impl From<segwit::EncodeError> for ConversionError {
    fn from(err: segwit::EncodeError) -> Self {
        ConversionError::SegwitEncode(err.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let stx_address = "SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP";
        let result = stx2btc(stx_address);
        println!("{:?}", result);

        assert_eq!(
            result.as_ref().unwrap(),
            "bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy"
        );

        let result2 = btc2stx(result.unwrap().as_str());
        println!("{:?}", result2);
        assert_eq!(result2.unwrap(), stx_address);
    }
}

uniffi::setup_scaffolding!();
