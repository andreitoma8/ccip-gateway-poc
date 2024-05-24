// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "hardhat/console.sol";

contract GatewayA is CCIPReceiver {
    string public data = "Empty message";

    constructor(address router) CCIPReceiver(router) {}

    function sendMessage(
        uint64 _destinationChainSelector,
        address _destinationContract,
        string calldata _message
    ) external payable {
        // Send a message to another chain
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_destinationContract),
            data: abi.encode(_message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 1000000})
            )
        });

        IRouterClient router = IRouterClient(i_ccipRouter);

        uint256 fee = router.getFee(_destinationChainSelector, message);

        router.ccipSend{value: fee}(_destinationChainSelector, message);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory _message
    ) internal override {
        // Do something with the message
        data = abi.decode(_message.data, (string));
    }

    receive() external payable {}
}
