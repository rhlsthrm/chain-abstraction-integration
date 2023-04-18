// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;
import "forge-std/Test.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {TransferInfo} from "connext-interfaces/core/IConnext.sol";
import "ExcessivelySafeCall/ExcessivelySafeCall.sol";

contract MockConnext is Test {
  uint256 public originChainForkId;
  uint256 public destinationChainForkId;
  address public destinationAsset;
  uint32 public originDomain;
  uint32 public destinationDomain;
  address public constant SUGAR_DADDY = address(1);

  bytes32 internal constant EMPTY_HASH = keccak256("");

  constructor(
    uint32 _originDomain,
    uint32 _destinationDomain,
    uint256 _originChainForkId,
    uint256 _destinationChainForkId,
    address _destinationAsset
  ) {
    originDomain = _originDomain;
    destinationDomain = _destinationDomain;
    originChainForkId = _originChainForkId;
    destinationChainForkId = _destinationChainForkId;
    destinationAsset = _destinationAsset;
  }

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {
    bytes32 _transferId = bytes32(originChainForkId);
    TransferHelper.safeTransferFrom(_asset, msg.sender, address(this), _amount);

    return bytes32(originChainForkId);
  }

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData,
    uint256 _relayerFee
  ) external returns (bytes32) {}

  function xcallIntoLocal(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32) {}

  function _executeDestination() internal {
    if (keccak256(_callData) == EMPTY_HASH) {
      // no call data, return amount out
      return;
    }

    vm.selectFork(destinationChainForkId);
    vm.deal(SUGAR_DADDY, 1 ether);

    // transfer to destination
    uint256 _destinationAmount = (_amount * (10000 - 5)) / 10000; // simulate router fee
    vm.deal(destinationAsset, address(this), _destinationAmount);

    (bool success, bytes memory returnData) = ExcessivelySafeCall.excessivelySafeCall(
      _to,
      gasleft() - Constants.EXECUTE_CALLDATA_RESERVE_GAS,
      0, // native asset value (always 0)
      Constants.DEFAULT_COPY_BYTES, // only copy 256 bytes back as calldata
      abi.encodeWithSelector(
        IXReceiver.xReceive.selector,
        _transferId,
        _destinationAmount,
        destinationAsset,
        address(0), // fast path only, TODO: figure out slow path
        _originDomain,
        _callData
      )
    );
    
  }
}
