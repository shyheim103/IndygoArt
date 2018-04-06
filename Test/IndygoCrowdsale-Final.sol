pragma solidity ^0.4.18;

import "./IncreasingPriceCrowdsale.sol";
import "./RefundableCrowdsale.sol";
import "./MintedCrowdsale.sol";


/**
 * @title SampleCrowdsale
 * @dev This is an example of a fully fledged crowdsale.
 * The way to add new features to a base crowdsale is by multiple inheritance.
 * In this example we are providing following extensions:
 * CappedCrowdsale - sets a max boundary for raised funds
 * RefundableCrowdsale - set a min goal to be reached and returns funds if it's not met
 *
 * After adding multiple features it's good practice to run integration tests
 * to ensure that subcontracts works together as intended.
 */
contract IndygoCrowdsale is IncreasingPriceCrowdsale, RefundableCrowdsale, MintedCrowdsale {
    address public crowdsaleOwner;

  function IndygoCrowdsale(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _initialRate,
    uint256 _finalRate,
    address _wallet,
    Indygo _token,
    uint256 _goal,
    address ownerOfCrowdsale
  )
    public
    Crowdsale(_wallet, _token)
    IncreasingPriceCrowdsale(_initialRate, _finalRate)
    TimedCrowdsale(_openingTime, _closingTime)
    RefundableCrowdsale(_goal)
  {
      crowdsaleOwner = ownerOfCrowdsale;
    //As goal needs to be met for a successful crowdsale
    //the value needs to less or equal than a cap which is limit for accepted funds
    require(_goal >= 0);
  }
  
          function transferTokenOwnerShip(address _newOwner) public onlyOwner {
        require(msg.sender == crowdsaleOwner);
        token.transferOwnership(_newOwner);
    }
}
