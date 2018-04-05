pragma solidity ^0.4.18;

import "./SafeMath.sol";

// Uses Pausible
// Uses ownable 
// Uses burnable
// Uses freezable
// Uses safemath
// Uses mintable

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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract Indygo is owned {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;
  
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Pause();
    event Unpause();

  bool public paused = false;
  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
   /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }
    

 /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function Indygo(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address centralMinter
    ) Indygo(initialSupply, tokenName, tokenSymbol, centralMinter) public {
        if(centralMinter != 0 ) owner = centralMinter;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        
    }


  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }


  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply += _amount;
    balanceOf[_to] += _amount;
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
  
/* Function to freeze accounts*/
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }



     /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if sending account is frozen
        require(!frozenAccount[msg.sender]);
        // Check if From account is frozen
        require(!frozenAccount[_from]);
        // Check if To account is frozen
        require(!frozenAccount[_to]);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
  

  
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
      require(_to != address(0));
       // Check if sending account is frozen
        require(!frozenAccount[msg.sender]);
        // Check if To account is frozen
        require(!frozenAccount[_to]);
    require(_value <= balanceOf[msg.sender]);
    
    _transfer(msg.sender, _to, _value);
    
  }
    
    
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
   

  function transferFrom(address _from, address _to, uint256 _value) public onlyOwner whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);     //Check if sender has enough

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
    
  }

  
   /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balanceOf[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balanceOf[burner] -= _value;
    totalSupply -= _value;
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}
