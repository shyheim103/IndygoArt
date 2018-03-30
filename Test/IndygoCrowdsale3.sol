pragma solidity ^0.4.17;

    contract owned {
        address public owner;
        

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) public onlyOwner {
            owner = newOwner;
        }
    }
    
    


interface token {
    function mint(address receiver, uint amount) external;
    
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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



contract Crowdsale is owned{
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public initialRate;
    uint256 public finalRate;
    token public tokenReward;
    address public crowdsaleOwner;
    
    mapping(address => uint256) public balanceOf;
    
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event OwnershipTransferred(address indexed crowdsaleOwner, address indexed newOwner);
    

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
        address addressOfTokenUsedAsReward,
        address ownerOfCrowdsale
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        closingTime;
        tokenReward = token(addressOfTokenUsedAsReward);
        crowdsaleOwner = ownerOfCrowdsale;
    }
    
            modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnerShipBack(address _newOwner) public onlyOwner {
        require(msg.sender == crowdsaleOwner);
        tokenReward.transferOwnership(_newOwner);
        // owner = crowdsaleOwner;
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
        amountRaised += amount * 1 ether;
        tokenReward.mint(msg.sender, amount / rateAmount);
        tokenReward.mint(beneficiary, amount / rateAmount);
        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= closingTime) _; 
        
    }
    
    
      /**
   * @dev Checks whether funding goal was reached. 
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return amountRaised >= fundingGoal;
  }
   
    
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
