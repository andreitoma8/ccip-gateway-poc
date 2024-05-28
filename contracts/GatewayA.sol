// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract GatewayA is CCIPReceiver {
    enum PayFeesIn {
        Native,
        LINK
    }

    string public data = "Empty message";

    IERC20 linkToken;

    constructor(address _router, IERC20 _linkToken) CCIPReceiver(_router) {
        linkToken = _linkToken;
    }

    function sendMessage(
        uint64 _destinationChainSelector,
        address _destinationContract,
        string calldata _message,
        PayFeesIn _payFeesIn
    ) external payable {
        // Send a message to another chain
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_destinationContract),
            data: abi.encode(_message),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: _payFeesIn == PayFeesIn.LINK
                ? address(linkToken)
                : address(0),
            extraArgs: ""
        });

        IRouterClient router = IRouterClient(i_ccipRouter);

        uint256 fee = router.getFee(_destinationChainSelector, message);

        console.log(linkToken.balanceOf(address(this)));
        console.log(fee);
        console.log(linkToken.allowance(address(this), address(router)));

        if (_payFeesIn == PayFeesIn.LINK) {
            linkToken.approve(address(router), fee);
            router.ccipSend(_destinationChainSelector, message);
        } else {
            router.ccipSend{value: fee}(_destinationChainSelector, message);
        }
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory _message
    ) internal override {
        // Do something with the message
        data = abi.decode(_message.data, (string));
    }

    receive() external payable {}
}
