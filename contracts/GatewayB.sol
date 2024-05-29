// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "hardhat/console.sol";

contract GatewayB is CCIPReceiver {
    string public data = "Empty message";

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(
        Client.Any2EVMMessage memory incomingMessage
    ) internal override {
        data = abi.decode(incomingMessage.data, (string));

        Client.EVM2AnyMessage memory outgoingMessage = Client.EVM2AnyMessage({
            receiver: incomingMessage.sender,
            data: incomingMessage.data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 500000})
            )
        });

        IRouterClient router = IRouterClient(i_ccipRouter);

        uint256 fee = router.getFee(
            incomingMessage.sourceChainSelector,
            outgoingMessage
        );

        router.ccipSend{value: fee}(
            incomingMessage.sourceChainSelector,
            outgoingMessage
        );
    }

    receive() external payable {}
}
