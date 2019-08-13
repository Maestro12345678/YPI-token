pragma solidity ^0.4.24;

// Safe Math

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


// Ownable


contract Ownable {
  address public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    _owner = msg.sender;
  }


  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract YPIToken is ERC20Interface, Ownable {
  using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 private _totalSupply;
    uint private _minPayment;
    uint private _maxPayment;
    uint private airdropAmount;
    uint256 private _soldTokens;
    uint256 public _startDate;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
       symbol = "YPI";
       name = "YPI Token";
       decimals = 18;
       _minPayment = 0.05 ether; //Minimal amount allowed to buy tokens
       _maxPayment = 5 ether; //Maximum amount allowed to buy tokens
       _soldTokens = 0; //Total number of sold tokens (excluding bonus tokens)

        _startDate = 1566507660; //Beginning of token sale 23.08.2019

       _totalSupply = 1000000 * (10 ** uint256(decimals));
       airdropAmount = 300000 * (10 ** uint256(decimals));

       _balances[_owner] = airdropAmount;
       _balances[address(this)] = (_totalSupply-airdropAmount);
       _allowed[address(this)][_owner]=_totalSupply;
       emit Transfer(address(0), _owner, airdropAmount);
    }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

    // Method for batch distribution of airdrop tokens.
    function sendBatchCS(address[] _recipients, uint[] _values) external onlyOwner returns (bool) {
        require(_recipients.length == _values.length);
        uint senderBalance = _balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            senderBalance = senderBalance - value;
            _balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        _balances[msg.sender] = senderBalance;
        return true;
    }


// Function to burn undistributed amount of tokens after ICO is finished
    function burn() external onlyOwner {
      _burn(address(this),_balances[address(this)]);
    }

  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);

    emit Transfer(account, 0x0000000000000000000000000000000000000000, amount);
  }


  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);
    require(amount <=_balances[account]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }


  function () external payable {
    buyTokens(msg.sender);
  }

  function sendTokens(address from, address to, uint256 value) internal returns (bool) {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
    return true;
  }


  function soldTokens() public view returns (uint256) {
    return _soldTokens;
  }


  function _forwardFunds(uint256 amount) external onlyOwner {
    require (address(this).balance > 0);
    require (amount <= address(this).balance);
    require (amount > 0);
    _owner.transfer(amount);
  }


  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256 tokens) {
    if (_soldTokens < 100000) {
      if (weiAmount / (0.0001 ether)  + _soldTokens <= 100000) {
        tokens = weiAmount / (0.0001 ether);
      } else {
        tokens = (100000 - _soldTokens) + (weiAmount - (100000 - _soldTokens)*(0.0001 ether))/(0.0005 ether);
      }

    }
    if (_soldTokens > 100000 && _soldTokens < 300000 ) {
      if (weiAmount / (0.0005 ether)  + _soldTokens <= 300000) {
        tokens = weiAmount / (0.0005 ether);
      } else {
        tokens = (300000 - _soldTokens) + (weiAmount - (300000 - _soldTokens)*(0.0005 ether))/(0.0025 ether);
      }

    }
    if (_soldTokens > 300000 && _soldTokens < 600000 ) {
      if (weiAmount / (0.0025 ether)  + _soldTokens <= 600000) {
        tokens = weiAmount / (0.0025 ether);
      } else {
        tokens = (600000 - _soldTokens) + (weiAmount - (600000 - _soldTokens)*(0.0025 ether))/(0.01 ether);
      }

    }
    if (_soldTokens >= 600000 ) {
        tokens = weiAmount / (0.01 ether);
    }
    return tokens;
  }


  function buyTokens(address beneficiary) public payable {
    require (now >= _startDate);
    require (msg.value >= _minPayment);
    require (msg.value <= _maxPayment);
    require(beneficiary != address(0));
    require (_balances[address(this)] > 0);

    uint256 tokens = _getTokenAmount(msg.value);

    require(_balances[address(this)] >= tokens * (10 ** uint256(decimals)));

    sendTokens(address(this), beneficiary, tokens * (10 ** uint256(decimals)));

    _soldTokens = _soldTokens.add(tokens);

    emit TokensPurchased(msg.sender, beneficiary,  msg.value, tokens);
  }

}



