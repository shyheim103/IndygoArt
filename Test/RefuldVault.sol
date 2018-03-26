pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Ownable.sol";



/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;
  
  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  
  
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @param _wallet Vault address
   */
  function RefundVault(address _wallet, uint256 depositGoal) public {
    require(_wallet != address(0));
    depositGoal;
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    address myAddress = this;
    wallet.transfer(myAddress.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
  
  
      function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        require(deposited[_from] >= _value);
        // Check for overflows
        require(deposited[_to] + _value > deposited[_to]);
        // Save this for an assertion in the future
        uint previousBalances = deposited[_from] + deposited[_to];
        // Subtract from the sender
        deposited[_from] -= _value;
        // Add the same to the recipient
        deposited[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(deposited[_from] + deposited[_to] == previousBalances);
    }

}
