// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import '@arbitrum/nitro-contracts-2.1.0/src/osp/IOneStepProofEntry.sol';
import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupAdmin.sol';
// import '@arbitrum/nitro-contracts-2.1.0/src/rollup/IRollupCore.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

interface ISeqInboxAvailDAinit {
  function initializeDABridge(address daBridge_) external;
}

/**
 * @title DeployAvailNitroContracts2Point1Point0UpgradeActionScript
 * @notice  Set wasm module root and upgrade challenge manager for stylus ArbOS upgrade.
 *          Also upgrade Rollup logic contracts to include fast confirmations feature.
 */
contract AvailNitroContracts2Point1Point0UpgradeAction {
  bytes32 public immutable newWasmModuleRoot;
  address public immutable newAvailDABridgeImpl;
  address public immutable newSequencerInboxImpl;

  constructor(
    bytes32 _newWasmModuleRoot,
    address _newAvailDABridgeImpl,
    address _newSequencerInboxImpl
  ) {
    require(
      _newWasmModuleRoot != bytes32(0),
      'NitroContracts2Point1Point0UpgradeAction: _newWasmModuleRoot is empty'
    );
    require(
      Address.isContract(_newAvailDABridgeImpl),
      'NitroContracts2Point1Point0UpgradeAction: _newAvailDABridgeImpl is not a contract'
    );
    // require(
    //   Address.isContract(_newSequencerInboxImpl),
    //   'NitroContracts2Point1Point0UpgradeAction: _newSequencerInboxImpl is not a contract'
    // );

    newWasmModuleRoot = _newWasmModuleRoot;
    newAvailDABridgeImpl = _newAvailDABridgeImpl;
    newSequencerInboxImpl = _newSequencerInboxImpl;
  }

  function perform(
    bytes32 wasmModuleRoot,
    IRollupCore rollup,
    ProxyAdmin proxyAdmin
  ) external {
    IRollupAdmin(address(rollup)).setWasmModuleRoot(newWasmModuleRoot);
    /// check that wasmModuleRoot is correct
    require(
      rollup.wasmModuleRoot() == wasmModuleRoot,
      'NitroContracts2Point1Point0UpgradeAction: wasm module root mismatch'
    );

    address newAvailDABridgeProxy = _deployAvailDABridgeProxy(proxyAdmin);

    /// do the upgrade
    _upgradeSequencerInbox(rollup, proxyAdmin, newAvailDABridgeProxy);
  }

  function _deployAvailDABridgeProxy(
    ProxyAdmin adminProxy
  ) internal returns (address) {
    return
      address(
        new TransparentUpgradeableProxy(
          newAvailDABridgeImpl,
          address(adminProxy),
          ''
        )
      );
  }

  function _upgradeSequencerInbox(
    IRollupCore rollup,
    ProxyAdmin proxyAdmin,
    address daBridge
  ) internal {
    // set the new challenge manager impl
    TransparentUpgradeableProxy sequencerInbox = TransparentUpgradeableProxy(
      payable(address(rollup.sequencerInbox()))
    );
    proxyAdmin.upgradeAndCall(
      sequencerInbox,
      newSequencerInboxImpl,
      abi.encodeCall(ISeqInboxAvailDAinit.initializeDABridge, (daBridge))
    );

    // verify
    require(
      proxyAdmin.getProxyImplementation(sequencerInbox) ==
        newSequencerInboxImpl,
      'NitroContracts2Point1Point0UpgradeAction: new challenge manager implementation set'
    );

    // set new wasm module root
    IRollupAdmin(address(rollup)).setWasmModuleRoot(newWasmModuleRoot);

    // verify:
    require(
      rollup.wasmModuleRoot() == newWasmModuleRoot,
      'NitroContracts2Point1Point0UpgradeAction: wasm module root not set'
    );
  }
}
