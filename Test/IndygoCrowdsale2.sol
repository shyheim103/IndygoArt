
pragma solidity ^0.4.16;



/**
 * @title Owned
 * @dev The Owned contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Owned {
  address public owner;
  address public tokens;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event TokenOwnershipTransferred(address indexed previousOwner, address indexed tokens);


  /**
   * @dev The Owned constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Owned() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
}
 

    function transferTokenOwnership(address _newOwner) public onlyOwner {
    require(msg.sender == tokens); // Only the owner of the crowdsale contract should be able to call this function.

    token.transferTokenOwnership(_newOwner);
}
}

interface token {
    function mint(address receiver, uint amount) external;
    
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract FCCCrowdsale is Owned{
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public initialRate;
    uint256 public finalRate;
    token public tokenReward;
    
    
    mapping(address => uint256) public balanceOf;
    
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

      event Closed();

  /**
   * @dev Reverts if not in crowdsale time range. 
   */
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }
      /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
    
    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        closingTime;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

 /**
   * @dev Constructor, takes intial and final rates of tokens received per wei contributed.
   * @param _initialRate Number of tokens a buyer gets per wei at the start of the crowdsale
   * @param _finalRate Number of tokens a buyer gets per wei at the end of the crowdsale
   */
  function IncreasingPriceCrowdsale(uint256 _initialRate, uint256 _finalRate) public {
    require(_initialRate >= _finalRate);
    require(_finalRate > 0);
    initialRate = _initialRate;
    finalRate = _finalRate;
  }

  /**
   * @dev Returns the rate of tokens per wei at the present time. 
   * Note that, as price _increases_ with time, the rate _decreases_. 
   * @return The number of tokens a buyer gets per wei at a given time
   */
  function getCurrentRate() public view returns (uint256) {
    uint256 elapsedTime = now - openingTime;
    uint256 timeRange = closingTime - openingTime;
    uint256 rateRange = initialRate - finalRate;
    return initialRate - elapsedTime * rateRange / timeRange;
  }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 currentRate = getCurrentRate();
    return currentRate * _weiAmount;
  }
  
  

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint256 rateAmount = getCurrentRate();
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.mint(msg.sender, amount / rateAmount);
        tokenReward.mint(beneficiary, amount / rateAmount);
        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= closingTime) _; }
    
    
     /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() afterDeadline public {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                  emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
    
  

}
