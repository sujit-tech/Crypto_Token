// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    function renounceOwnership() public virtual onlyOwner {
        transferOwnership(address(0));
    }

}

interface ERC20Basic {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface ERC20 is ERC20Basic {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
}

contract StandardToken is ERC20, Ownable {
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) internal allowed;

    mapping(address => uint256) balances;

    function transfer(
        address _to,
        uint256 _value
    ) public virtual returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        unchecked{  
        balances[msg.sender] = balances[msg.sender]-(_value);
        }
        balances[_to] = balances[_to]+(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        unchecked{
        balances[_from] = balances[_from]-(_value);
        }
        balances[_to] = balances[_to]+(_value);
        unchecked{
        allowed[_from][msg.sender] = allowed[_from][msg.sender]-(_value);
        }    
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public virtual returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                approve(spender, currentAllowance - amount);
            }
        }
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    ) public virtual returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender]+(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    ) public virtual returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            unchecked{
            allowed[msg.sender][_spender] = oldValue - (_subtractedValue);
            }}
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract Simple is StandardToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Burn(address indexed burner, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals,
        uint256 _supply,
        address tokenOwner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10 ** _decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        unchecked {
            balances[_who] = balances[_who] - (_value);
            totalSupply = totalSupply - (_value);
        }
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}
