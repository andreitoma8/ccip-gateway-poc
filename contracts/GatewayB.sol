// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract GatewayB is CCIPReceiver {
    enum PayFeesIn {
        Native,
        LINK
    }

    PayFeesIn public feeType;

    IERC20 linkToken;

    string public data = "Empty message";

    constructor(address router, IERC20 _linkToken) CCIPReceiver(router) {
        linkToken = _linkToken;
    }

    function setFeeType(PayFeesIn _payFeesIn) external {
        feeType = _payFeesIn;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory incomingMessage
    ) internal override {
        data = abi.decode(incomingMessage.data, (string));

        Client.EVM2AnyMessage memory outgoingMessage = Client.EVM2AnyMessage({
            receiver: incomingMessage.sender,
            data: incomingMessage.data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: feeType == PayFeesIn.LINK
                ? address(linkToken)
                : address(0),
            extraArgs: ""
        });

        IRouterClient router = IRouterClient(i_ccipRouter);

        uint256 fee = router.getFee(
            incomingMessage.sourceChainSelector,
            outgoingMessage
        );

        console.log(linkToken.balanceOf(address(this)));
        console.log(fee);
        console.log(linkToken.allowance(address(this), address(router)));

        if (feeType == PayFeesIn.LINK) {
            linkToken.approve(address(router), fee);
            router.ccipSend(
                incomingMessage.sourceChainSelector,
                outgoingMessage
            );
        } else {
            router.ccipSend{value: fee}(
                incomingMessage.sourceChainSelector,
                outgoingMessage
            );
        }
    }

    receive() external payable {}
}
