// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { DeploymentHelpersScript } from '../helper/DeploymentHelpers.s.sol';
import { AvailNitroContracts2Point1Point0UpgradeAction, IOneStepProofEntry } from '../../../contracts/parent-chain/avail-nitro-contract-upgrades/AvailNitroContracts2Point1Point0UpgradeAction.sol';
import { MockArbSys } from '../helper/MockArbSys.sol';
import { SequencerInbox } from '@arbitrum/nitro-contracts-2.1.0/src/bridge/SequencerInbox.sol';

import { console } from 'forge-std/console.sol';
/**
 * @title DeployNitroContracts2Point1Point0UpgradeActionScript
 * @notice This script deploys OSPs, ChallengeManager and Rollup templates, and the upgrade action.
 */
contract DeployAvailNitroContracts2Point1Point0UpgradeActionScript is
  DeploymentHelpersScript
{
  bytes32 public constant AVAIL_WASM_MODULE_ROOT =
    0x279171794990ee78fb4e6be5a86b439a6a95135bba8ac8eeeeb496c952de300c;

  // ArbOS v31 https://github.com/OffchainLabs/nitro/releases/tag/consensus-v31
  bytes32 public constant ARB_WASM_MODULE_ROOT =
    0x260f5fa5c3176a856893642e149cf128b5a8de9f828afec8d11184415dd8dc69;

  function run() public {
    bool isArbitrum = vm.envBool('PARENT_CHAIN_IS_ARBITRUM');
    if (isArbitrum) {
      //fetch a mock ArbSys contract so that foundry simulate it nicely
      bytes memory mockArbSysCode = address(new MockArbSys()).code;
      vm.etch(address(100), mockArbSysCode);
    }

    console.logBool(isArbitrum);

    vm.startBroadcast();

    SequencerInbox sequencerInbox = SequencerInbox(
      vm.envAddress('SEQUENCER_INBOX_ADDRESS')
    );

    address reader4844Address = address(sequencerInbox.reader4844());

    console.logAddress(reader4844Address);
    // deploy new RollupUserLogic contract from v2.1.0
    address seqencerInbox = deployBytecodeWithConstructorFromJSON(
      '/scripts/foundry/avail-nitro-contract-upgrades/SequencerInbox.sol/SequencerInbox.json',
      abi.encode(
        vm.envUint('MAX_DATA_SIZE'),
        reader4844Address,
        !vm.envBool('IS_FEE_TOKEN_CHAIN')
      )
    );
    // address seqencerInbox = deployBytecodeFromJSON(
    //   '/scripts/foundry/avail-nitro-contract-upgrades/SequencerInbox.sol/SequencerInbox.json'
    // );

    // deploy new Avail Bridge contract
    // address availDABridge = deployBytecodeFromJSON(
    //   '/scripts/foundry/avail-nitro-contract-upgrades/AvailDABridge.sol/AvailDABridge.json'
    // );

    // finally deploy upgrade action
    // new AvailNitroContracts2Point1Point0UpgradeAction({
    //   _newWasmModuleRoot: AVAIL_WASM_MODULE_ROOT,
    //   _newAvailDABridgeImpl: availDABridge,
    //   _newSequencerInboxImpl: seqencerInbox
    // });

    vm.stopBroadcast();
  }
}
