// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract PaymentChannel {

    uint256 public balance;
    uint256 public constant MINIMAL_TOPUP = 0.001 ether;
    address public user;
    address public burner;
    address public rhascauManager;
    bool public firstTopUpDone = false;

    modifier isUser() {
        require(msg.sender == user, "Rhascau Payment Channel: You are not an onwer of the channel");
        _;
    }

    modifier isBurner() {
        require(msg.sender == burner, "Rhascau Payment Channel: This burner is not allowed to interact with this channel");
        _;
    }

    constructor(address _user, address _burner, address _manager) payable {
        balance = msg.value;
        user = _user;
        burner = _burner;
        rhascauManager = _manager;
    }

    function topUp() external payable isUser {
        balance += msg.value;
        if(!firstTopUpDone) {
            (bool sent,) = burner.call{value: MINIMAL_TOPUP}("");
            require(sent, "Rhascau Payment Channel: Failed to fund burner");
            firstTopUpDone = true;
            balance -= MINIMAL_TOPUP;
        }
    }
    
    function burnerFaucet(uint256 _amount) isBurner external payable {
        require(_amount <= balance, "Rhascau Payment Channel: Amount exceeds channel balance");
        balance -= _amount;
        (bool sent, ) = burner.call{value: _amount}("");
        require(sent, "Rhascau Payment Channel: Failed to fund burner");
    }

    function destroyChannel() external payable isUser {
        selfdestruct(payable(user));
    }
}
