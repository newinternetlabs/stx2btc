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
    let (decoded_version, decoded_bytes) =
        decode_address(stx_address).expect("Failed to decode address");

    // Determine network from Stacks address version
    let hrp = match decoded_version {
        22 => hrp::BC, // Mainnet (SP prefix)
        26 => hrp::TB, // Testnet (ST prefix)
        _ => return Err(ConversionError::UnsupportedNetwork),
    };

    let segwit_address = segwit::encode_v0(hrp, &decoded_bytes)?;

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
    let (hrp, version, decoded_bytes) = segwit::decode(btc_address)?;

    // Only handle version 0 (P2WPKH) addresses because we can't generate a taproot address without
    // the original public key (decoding the stacks address gives us only the 20 byte HASH160)
    if version.to_u8() != 0 {
        return Err(ConversionError::UnsupportedVersion);
    }

    // Determine Stacks version from Bitcoin HRP
    let stx_version = match hrp.as_str() {
        "bc" => 22,   // Mainnet
        "tb" => 26,   // Testnet
        "bcrt" => 26, // Regtest (use testnet version)
        _ => return Err(ConversionError::UnsupportedNetwork),
    };

    let stx_address =
        encode_address(stx_version, &decoded_bytes).expect("Failed to decode address");
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
    #[error("Unsupported network")]
    UnsupportedNetwork,
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
    fn test_mainnet_conversion() {
        // Test mainnet STX to BTC
        let stx_address = "SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP";
        let btc_result = stx2btc(stx_address).unwrap();
        assert!(btc_result.starts_with("bc1"));
        assert_eq!(btc_result, "bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy");

        // Test round-trip conversion
        let stx_result = btc2stx(&btc_result).unwrap();
        assert_eq!(stx_result, stx_address);
    }

    #[test]
    fn test_testnet_conversion() {
        // Create a testnet address using version 26
        // We'll convert the mainnet address to testnet for testing
        let mainnet_stx = "SP2V0G568F20Q1XCRT43XX8Q32V2DPMMYFHHBD8PP";

        // Decode mainnet address to get the hash160
        let (_, decoded_bytes) = c32address::decode_address(mainnet_stx).unwrap();

        // Encode with testnet version
        let testnet_stx = c32address::encode_address(26, &decoded_bytes).unwrap();
        assert!(testnet_stx.starts_with("ST"));

        // Test testnet STX to BTC
        let btc_result = stx2btc(&testnet_stx).unwrap();
        assert!(btc_result.starts_with("tb1"));

        // Test round-trip conversion
        let stx_result = btc2stx(&btc_result).unwrap();
        assert_eq!(stx_result, testnet_stx);
    }

    #[test]
    fn test_btc_mainnet_to_stx() {
        let btc_address = "bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy";
        let stx_result = btc2stx(btc_address).unwrap();
        assert!(stx_result.starts_with("SP"));
    }

    #[test]
    fn test_btc_testnet_to_stx() {
        // Create a valid testnet bitcoin address
        let mainnet_btc = "bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy";
        let (_, _version, decoded_bytes) = segwit::decode(mainnet_btc).unwrap();

        // Encode with testnet HRP
        let testnet_btc = segwit::encode_v0(hrp::TB, &decoded_bytes).unwrap();
        assert!(testnet_btc.starts_with("tb1"));

        let stx_result = btc2stx(&testnet_btc).unwrap();
        assert!(stx_result.starts_with("ST"));
    }

    #[test]
    fn test_btc_regtest_to_stx() {
        // Create a valid regtest bitcoin address
        let mainnet_btc = "bc1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy";
        let (_, _version, decoded_bytes) = segwit::decode(mainnet_btc).unwrap();

        // Encode with regtest HRP
        let regtest_btc = segwit::encode_v0(hrp::BCRT, &decoded_bytes).unwrap();
        assert!(regtest_btc.starts_with("bcrt1"));

        let stx_result = btc2stx(&regtest_btc).unwrap();
        // Regtest uses testnet version, so should produce ST prefix
        assert!(stx_result.starts_with("ST"));
    }

    #[test]
    fn test_unsupported_network_error() {
        // Test with an invalid HRP
        let btc_address = "xyz1qkcypfjrcs9c0txx3ql029cckcnd498nuvl6wpy";
        let result = btc2stx(btc_address);
        assert!(result.is_err());
    }

    #[test]
    fn test_unsupported_version_error() {
        // Test with a P2TR (taproot) address (version 1)
        let btc_address = "bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0";
        let result = btc2stx(btc_address);
        assert!(matches!(result, Err(ConversionError::UnsupportedVersion)));
    }
}

uniffi::setup_scaffolding!();
