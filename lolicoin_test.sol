// Specifies that the source code is for a version
// of Solidity greater than 0.5.0
pragma solidity >=0.5.0 <0.7.0;

// ------------------------------------------------------------------------
// Operaciones matemáticas seguras que lancen excepciones en caso de que 
// el el resultado de un cálculo no sea correcto. 
// Con esta librería evitaríamos, por ejemplo, el problema de overflow 
// generado al sumar dos números cuyo resultado es mayor que el máximo 
// aceptado por el tipo usado. De OpenZeppelin Contracts
// ------------------------------------------------------------------------
library SafeMath {
    
    //Suma
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    //Resta
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    //Comprobacion de error de resta, B es menor A
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    //Multiplicacion con comprobacion de error
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    //Division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    //Division con comprobacion de error
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    //Modulo
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    //Modulo con comprobacion de error
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

//Contrato Propio (Prestado de:https://github.com/bokkypoobah/Tokens#fixed-supply-token)
contract OwnedContract {
    
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract LoliCoin is OwnedContract{
    
    using SafeMath for uint256;
    
    string private _name;
    string private  _symbol;
    uint8 private _decimals;
    uint256 _totalSupply;

    //Balances en cada cuenta
    mapping(address => uint256) balances;

    //El propietario de la cuenta aprueba la transferencia de un monto hacia otra cuenta
    mapping(address => mapping (address => uint256)) allowed;

    
    constructor() public {
        _name = "Loli-Chan Coin";
        _symbol = "TCHAN";
        _decimals = 18;
        _totalSupply = 1000 * (uint256(10)**_decimals);
        //El balance de todos los tokens se vuelve el balance del dueño
        balances[msg.sender] = _totalSupply;
        //Transfiere los tokens a la cuenta del dueño
        emit Transfer(address(0), owner, _totalSupply);
    }


    //ERC Token #20 Interface.
    //Tomado de https://en.bitcoinwiki.org/wiki/ERC20

    function totalSupply() public view returns (uint){
        return _totalSupply  - balances[address(0)];
    }

    ////Obtiene el balance de la cuenta del dueño del token
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }

    //Devuelve la cantidad de tokens aprobados por el propietario 
    //que pueden transferirse a la cuenta del gastador
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];
    }

    //Transfiere el balance de una cuenta a otra
    //El dueño de la cuenta debe tener suficiente balance para transferir
    //Transferencias de valores 0 estan permitidos
    function transfer(address to, uint tokens) public returns (bool success){
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    //El propietario del token puede aprobar que 'spender' transferFrom(...) (transfiera) 'tokens' 
    //desde la cuenta del propietario del token
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /*El método transferFrom se utiliza para un flujo de trabajo de retiro,
    lo que permite que los contratos envíen tokens en su nombre, 
    por ejemplo para "depositar" en una dirección de contrato y / o cobrar 
    tarifas en sub monedas; el comando debería fallar a menos que la cuenta _from haya 
    autorizado deliberadamente al remitente del mensaje a través de algún mecanismo*/
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    //Prestado de: https://github.com/bokkypoobah/Tokens#fixed-supply-token
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    //El propietario puede transferir cualquier token ERC20 enviado accidentalmente
    //function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    //    return ERC20Interface(tokenAddress).transfer(owner, tokens);
    //}

    //No acepta ETH
    fallback () external payable {
        revert();
    }

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}