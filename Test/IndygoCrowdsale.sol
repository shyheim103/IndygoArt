
pragma solidity ^0.4.16;

import "./RefundVault.sol";

/**
 * @title Owned
 * @dev The Owned contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Owned {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

}

interface token {
    function mint(address receiver, uint amount) external;
}


contract FCCCrowdsale is RefundVault, Owned{
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public initialRate;
    uint256 public finalRate;
    // minimum amount of funds to be raised in weis
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;
    
    token public tokenReward;
    
    mapping(address => uint256) public balanceOf;
    
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    bool public isFinalized = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event Finalized();

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
    uint256 elapsedTime = now.sub(openingTime);
    uint256 timeRange = closingTime.sub(openingTime);
    uint256 rateRange = initialRate.sub(finalRate);
    return initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
  }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 currentRate = getCurrentRate();
    return currentRate.mul(_weiAmount);
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
   * @dev Constructor, creates RefundVault. 
   * @param _goal Funding goal
   */
  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }
  
  
  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(goal < amountRaised);

    vault.refund(msg.sender);
  }
  
  
   /**
   * @dev Checks whether funding goal was reached. 
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return amountRaised >= goal;
  }

    
    /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());
    
    finalization();
    emit Finalized();

    isFinalized = true;
  }
  
   /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }



}
