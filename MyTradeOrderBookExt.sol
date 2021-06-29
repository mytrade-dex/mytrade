// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IMyTradeOrderBookExt{
    function liquidityPrice(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _pairAddr,
        uint _reserve0,
        uint _reserve1
    )external;
    
    
    function cancelOrderWithNum(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )external;
    
    function addOrder(
        address _maker,
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 _orderIndex
    )external;
    function updateOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex,
        uint256 _toTokenNum
    )external;
    function getOrderIndexsForMaker(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _maker
    )external view returns(uint256[] memory cindexs);
    function getOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
   )external view returns(uint256 _orderTime,uint256 _toTokenSum);
}
contract MyTradeOrderBookExt is Ownable,ReentrancyGuard,IMyTradeOrderBookExt{
    using SafeMath for uint;
    IUniswapV2Factory immutable public uniswapV2Factory;
    constructor(address _uniswapV2Factory) payable  {
        tokenPairExtArray.push();
        uniswapV2Factory=IUniswapV2Factory(_uniswapV2Factory);
    }
    receive() external payable { 
    }
    fallback(bytes calldata _input) external payable returns (bytes memory _output){
    }

    struct TokenPairExt{
        mapping(uint256=> uint256) toTokenSumMap;// orderIndex=》toTokenSum
        mapping(uint256=> uint256) timeMap;// orderIndex=》time
        mapping(address => uint256[]) ordersForAddress;// 下单地址=》该地址对应的orderIndex
    }
    
    TokenPairExt[] tokenPairExtArray;// tokenPair数组
    mapping (address  => uint256) public tokenPairExtIndexMap;// token0地址=>tokenPairExt数组下标
    
    modifier onlyApproved(
        address payable addr
    ) {
        require(isApproved(address(this),addr));//必须经过该地址允许才能操作
        _;
    }
    // Mapping from owner to operator approvals
    mapping (address  => mapping (address  => bool)) private _operatorApprovals;
    /**
     *指定允许代理其对合约操作的权限的操作员
     */
    function setApproval(
        address to, 
        bool approved
    ) public onlyOwner returns(bool) {
        _operatorApprovals[address(this)][to] = approved;
        return true;
    }
    function isApproved(
        address addr, 
        address operator
    ) public view returns (bool) {
        if (addr == operator) {//如果是自己，默认允许
            return true;
        }
        return _operatorApprovals[addr][operator];
    }
    event LiquidityPrice(
        address indexed _fromTokenAddr,// 卖出token地址
        address indexed _toTokenAddr,// 买入token地址
        address indexed _pairAddr,
        uint _reserve0,
        uint _reserve1
    );
    function liquidityPrice(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _pairAddr,
        uint _reserve0,
        uint _reserve1
    )onlyApproved(msg.sender) override public {
        LiquidityPrice(_fromTokenAddr,_toTokenAddr,_pairAddr,_reserve0,_reserve1);
    }
    event CancelOrderWithNum(
        address indexed _fromTokenAddr,// 卖出token地址
        address indexed _toTokenAddr,// 买入token地址
        uint256 indexed _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    );
   function cancelOrderWithNum(//按数量取消订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex,// 具体订单号（目前是订单的唯一性标识）
        uint256 _num
    )onlyApproved(msg.sender) override public {
        
        emit CancelOrderWithNum(_fromTokenAddr,_toTokenAddr,_orderIndex,_num);
    }
    event AddOrder(
        address indexed _maker,
        address indexed _fromTokenAddr,
        address _toTokenAddr,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 indexed _orderIndex
    );
    
    function addOrder(
        address _maker,
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 _orderIndex
    )onlyApproved(msg.sender) override public {
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        uint256 tokenPairIndex=tokenPairExtIndexMap[pairAddr];
        if(tokenPairIndex== 0){//如果交易对不存在就新增一个
            tokenPairExtArray.push();
            tokenPairIndex=tokenPairExtArray.length-1 ;
            tokenPairExtIndexMap[pairAddr]=tokenPairIndex;
        }
        tokenPairExtArray[tokenPairIndex].ordersForAddress[_maker].push(_orderIndex);
        tokenPairExtArray[tokenPairIndex].timeMap[_orderIndex]=block.timestamp;
        emit AddOrder(_maker,_fromTokenAddr,_toTokenAddr,_fromTokenNumber,_toTokenNumber,_orderIndex);
    }
    event UpdateOrderInfo(
        address indexed _fromTokenAddr,
        address indexed _toTokenAddr,
        uint256 indexed _orderIndex,
        uint256 _toTokenNum
    );
    function updateOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex,
        uint256 _toTokenNum
    )onlyApproved(msg.sender) override public {
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        uint256 tokenPairIndex=tokenPairExtIndexMap[pairAddr];
        tokenPairExtArray[tokenPairIndex].toTokenSumMap[_orderIndex]=
        _toTokenNum.add(tokenPairExtArray[tokenPairIndex].toTokenSumMap[_orderIndex]);
        tokenPairExtArray[tokenPairIndex].timeMap[_orderIndex]=block.timestamp;
        emit UpdateOrderInfo(_fromTokenAddr,_toTokenAddr,_orderIndex,_toTokenNum);
    }
    function getOrderIndexsForMaker(
        address _fromTokenAddr,
        address _toTokenAddr,
        address _maker
    )override public view returns(uint256[] memory cindexs){
        address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        uint256 tokenPairIndex=tokenPairExtIndexMap[pairAddr];
        return tokenPairExtArray[tokenPairIndex].ordersForAddress[_maker];
    }
    function getOrderInfo(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
   )override public view returns(uint256 _orderTime,uint256 _toTokenSum){
       address pairAddr=uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
       uint256 tokenPairIndex=tokenPairExtIndexMap[pairAddr];
       return (tokenPairExtArray[tokenPairIndex].timeMap[_orderIndex],tokenPairExtArray[tokenPairIndex].toTokenSumMap[_orderIndex]);
   }
}