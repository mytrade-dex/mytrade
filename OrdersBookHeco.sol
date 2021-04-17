// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;
/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
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
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

}
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
interface IOrdersBook {
    function cancelOrder(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex// 具体订单号（目前是订单的唯一性标识）
    )external returns(bool);
    function addMarketOrder(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )external payable returns(bool);
    function addOrder(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )external payable returns(uint256 reserveNum) ;
    function getInAmount(//需要测试是否会返回零
        uint256 fromNum,
        uint256 toNum,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns(uint256);
    function getPageOrdersForMaker(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker,
        uint256 _type,//1:代表所有;2:代表已取消;3:代表已成交;4:代表未成交;5:代表已取消或者已成交
        uint256 _start,//开始位置
        uint256 _num//数量
    )external view returns(uint256[] memory indexs);
    function getPageOrderDetailsForMaker(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker,
        uint256 _type,//1:代表所有;2:代表已取消;3:代表已成交;4:代表未成交;5:代表已取消或者已成交
        uint256 _start,//开始位置
        uint256 _num//数量
    )external view returns(
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    );
    function getOrderByIndexBatch(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256[] calldata _orderIndexs//必须是已存在的orderIndex，否则会得不到正确结果
    )external view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    );
    function getOrderByIndex(// 根据订单号获取订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex
    )external view returns(
        address maker,//挂单者
        address fromTokenAddr,// 代币地址
        uint256 remainNumber,//初始挂单量
        uint256 timestamp,//初始挂单时间
        uint256 currentNumber,//当前挂单存量
        uint256 toTokenNumber,//初始意向代币目标金额
        uint256 toTokenSum//已经获取的金额
    );
    function getPageOrderDetails(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )external view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    );
    function getPageOrders(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )external view returns(uint256[] memory orderIndexs);
    function getOrderSums(//获取交易对所有订单总下单数(包括所有历史和已取消的订单)
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr// 买入token地址
    )external view returns(uint256 orderMaxIndex);

    function getOrderSumsForMaker(//获取交易对某账户总下单数(包括所有历史和已取消的订单)
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker//必须是正确的数值
    )external view returns(uint256 len);

    function getClosestOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
         uint256 _depth
    )external view returns (uint256 closestOrderIndex, uint8 end);
    function getLastOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr
    )external view returns (uint256 lastOrderIndex);
    function getNextOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )external view returns  (uint256 nextOrderIndex);
    function getPreOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )external view returns (uint256 preOrderIndex);
    function getPair(address tokenA, address tokenB)  external view returns (address);
    function IsCancelOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )external view returns (bool);
}
interface IWHT {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}
contract OrdersBook is Ownable,ReentrancyGuard,IOrdersBook{
    using SafeMath for uint256;
    IUniswapV2Factory immutable public uniswapV2Factory;
    address immutable public whtAddr;
    address public feeAddr;
    uint256 constant UINT256_MAX = ~uint256(0);

    struct Order{
        address payable maker;
        address fromTokenAddr;
        address toTokenAddr;
        uint256 remainNumber;
        uint256 timestamp;
        uint256 fromTokenNumber;// 代币挂单金额
        uint256 toTokenNumber;// 意向代币目标金额
        uint256 toTokenSum;// 已经获取的金额
    }
    struct TokenPair{
        uint256 orderMaxIndex;
        mapping(address=> uint256) lastIndex;
        mapping(uint256=> Order) orderMap;// orderIndex=》Order
        mapping(uint256=> uint256) orderNextSequence;// 价格低的orderIndex=》价格高的orderIndex
        mapping(uint256=> uint256) orderPreSequence;// 价格高的orderIndex=》价格低的orderIndex
        mapping(address => uint256[]) ordersForAddress;// 地址=》该地址对应的orderIndex
    }
    TokenPair[] public tokenPairArray;// tokenPair数组
    mapping (address  => uint256) public tokenPairIndexMap;// token0地址=>tokenPair数组下标
    mapping (uint256  => mapping (uint256  => uint8)) public cancelMap;//是否是已取消订单
    constructor(address _whtAddr,address _uniswapV2Factory) payable  {
        whtAddr=_whtAddr;
        feeAddr=msg.sender;
        tokenPairArray.push();
        uniswapV2Factory=IUniswapV2Factory(_uniswapV2Factory);
    }
    receive() external payable { 
    }
    fallback(bytes calldata _input) external payable returns (bytes memory _output){
    }
    function setFeeAddr(address _feeAddr)public onlyOwner {
        feeAddr=_feeAddr;
    }
    function cancelOrder(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex// 具体订单号（目前是订单的唯一性标识）
    )public override nonReentrant returns(bool) {
        address pairAddr=getPair(_fromTokenAddr,_toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        require(tokenPairIndex!=0,"tokenPair not exist");
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        require(_tokenPair.orderMap[_orderIndex].maker==msg.sender);
        require(_orderIndex!=0);
        cancelMap[tokenPairIndex][_orderIndex]=1;//已取消
        if(_tokenPair.lastIndex[_fromTokenAddr]==_orderIndex){
            _tokenPair.lastIndex[_fromTokenAddr]=_tokenPair.orderNextSequence[_orderIndex];
            _tokenPair.orderPreSequence[_tokenPair.lastIndex[_fromTokenAddr]]=0;
            _tokenPair.orderNextSequence[_orderIndex]=0;
        }else{
            uint256 orderPreIndex=_tokenPair.orderPreSequence[_orderIndex];
            require(orderPreIndex!=0);
            require(_tokenPair.orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr);
            uint256 orderNextIndex=_tokenPair.orderNextSequence[_orderIndex];
            _tokenPair.orderNextSequence[orderPreIndex]=orderNextIndex;
            if(orderNextIndex!=0){
                _tokenPair.orderPreSequence[orderNextIndex]=orderPreIndex;
            }
            _tokenPair.orderPreSequence[_orderIndex]=0;
            _tokenPair.orderNextSequence[_orderIndex]=0;
        }

        uint256 fromTokenNumber=_tokenPair.orderMap[_orderIndex].remainNumber;
        if(fromTokenNumber>0){
            safeTransfer(
                IERC20(_fromTokenAddr),
                msg.sender,
                fromTokenNumber
            );
        }
        _tokenPair.orderMap[_orderIndex].timestamp=block.timestamp;
        return true;
    }

    function _orderIndexSequence(
        uint256 _targetOrderIndex,
        uint256 _orderIndex,
        TokenPair storage _tokenPair,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )internal{
        if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)<=
            _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
            uint256 orderNextSequence=_tokenPair.orderNextSequence[_targetOrderIndex];
            if(orderNextSequence==0){
                _tokenPair.orderNextSequence[_targetOrderIndex]=_orderIndex;
                _tokenPair.orderPreSequence[_orderIndex]=_targetOrderIndex;
            }else{
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderNextSequence].toTokenNumber)<=
                    _tokenPair.orderMap[orderNextSequence].fromTokenNumber.mul(_toTokenNumber)){
                    _orderIndexSequence(orderNextSequence,
                        _orderIndex,_tokenPair,_fromTokenNumber,_toTokenNumber);
                }else{
                    _tokenPair.orderPreSequence[_orderIndex]=_targetOrderIndex;
                    _tokenPair.orderNextSequence[_targetOrderIndex]=_orderIndex;
                    _tokenPair.orderPreSequence[orderNextSequence]=_orderIndex;
                    _tokenPair.orderNextSequence[_orderIndex]=orderNextSequence;
                }
            }
        }else{
            uint256 orderPreIndex=_tokenPair.orderPreSequence[_targetOrderIndex];
            if(orderPreIndex==0){
                _tokenPair.orderPreSequence[_targetOrderIndex]=_orderIndex;
                _tokenPair.orderNextSequence[_orderIndex]=_targetOrderIndex;
            }else{
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderPreIndex].toTokenNumber)>=
                    _tokenPair.orderMap[orderPreIndex].fromTokenNumber.mul(_toTokenNumber)){
                    _orderIndexSequence(orderPreIndex,
                        _orderIndex,_tokenPair,_fromTokenNumber,_toTokenNumber);
                }else{
                    _tokenPair.orderNextSequence[_orderIndex]=_targetOrderIndex;
                    _tokenPair.orderPreSequence[_targetOrderIndex]=_orderIndex;
                    _tokenPair.orderNextSequence[orderPreIndex]=_orderIndex;
                    _tokenPair.orderPreSequence[_orderIndex]=orderPreIndex;
                }
            }
        }
    }
    function addMarketOrder(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public override payable returns(bool) {
        require(addOrder(_fromTokenAddr,_toTokenAddr,
            _targetOrderIndex,_fromTokenNumber,_toTokenNumber.div(100000))==0);
        return true;
    }
   
    function addOrder(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public override payable nonReentrant returns(uint256 reserveNum) {
        if(_fromTokenAddr==whtAddr&&msg.value>=_fromTokenNumber){
            IWHT(whtAddr).deposit{value : msg.value}();
        }else{
            safeTransferFrom(
                IERC20(_fromTokenAddr),
                msg.sender,
                address(this),
                _fromTokenNumber
            );
        }
        uint256 tokenPairIndex=tokenPairIndexMap[getPair(_fromTokenAddr,_toTokenAddr)];
        if(tokenPairIndex== 0){//如果交易对不存在就新增一个
            tokenPairArray.push();
            tokenPairIndex=tokenPairArray.length-1 ;
            tokenPairIndexMap[getPair(_fromTokenAddr,_toTokenAddr)]=tokenPairIndex;
        }
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        uint256 orderIndex=_tokenPair.orderMaxIndex.add(1);
        _tokenPair.orderMaxIndex=orderIndex;

        uint256 lastIndex=_tokenPair.lastIndex[_fromTokenAddr];
        if(lastIndex!=0){
            if(_targetOrderIndex==0){
                _targetOrderIndex=lastIndex;
            }else if(
                _tokenPair.orderNextSequence[_targetOrderIndex]==0&&
                _tokenPair.orderPreSequence[_targetOrderIndex]==0
            ){
                _targetOrderIndex=lastIndex;
            }else if(_tokenPair.orderMap[_targetOrderIndex].fromTokenAddr!=_fromTokenAddr){
                _targetOrderIndex=lastIndex;
            }
            _orderIndexSequence(_targetOrderIndex,orderIndex,_tokenPair,
                _fromTokenNumber,_toTokenNumber
            );
        }

        Order memory order=Order(msg.sender,_fromTokenAddr,_toTokenAddr,
           _fromTokenNumber,block.timestamp,_fromTokenNumber,_toTokenNumber,0);
        _tokenPair.orderMap[orderIndex]=order;
        _tokenPair.ordersForAddress[msg.sender].push(orderIndex);
        if(_tokenPair.orderPreSequence[orderIndex]==0){
            _tokenPair.lastIndex[_fromTokenAddr]=orderIndex;
            checkTrade(_tokenPair,orderIndex);
        }
        reserveNum=_tokenPair.orderMap[orderIndex].remainNumber;
        if(reserveNum==0){
            _tokenPair.lastIndex[_fromTokenAddr]=_tokenPair.orderNextSequence[orderIndex];
            if(_tokenPair.lastIndex[_fromTokenAddr]!=0){
                _tokenPair.orderPreSequence[_tokenPair.lastIndex[_fromTokenAddr]]=0;
            }
            _tokenPair.orderNextSequence[orderIndex]=0;
        }
    }
    function checkTrade(TokenPair storage _tokenPair,uint256 orderIndex) internal {
            Order memory o=_tokenPair.orderMap[orderIndex];
            (uint256 reserveA,uint256 reserveB)=getReserves(o.fromTokenAddr, o.toTokenAddr);
            uint256 fee=0;   
            uint256 cInAmount=getInAmount(o.fromTokenNumber,o.toTokenNumber,reserveA,reserveB);//计算达到当前订单价格需要付出的币数量
            if(cInAmount>1){//如果流动池价格低于当前价格
                {
                    if(cInAmount>o.fromTokenNumber){//如果精度差距，取小的数值
                        cInAmount=o.fromTokenNumber;
                    }
                    uint256 inAmountSum=0;
                    uint256 outAmountSum=0;
                    uint256 tokenBIndex=_tokenPair.lastIndex[o.toTokenAddr];
                    if(tokenBIndex!=0){
                        Order memory bo=_tokenPair.orderMap[tokenBIndex];
                        uint256 newInAmount=getInAmount(
                            bo.toTokenNumber,bo.fromTokenNumber,reserveA,reserveB);//计算对手订单价格需要付出的币数量
                        if(cInAmount>=newInAmount){//全部成交超过对手订单价格
                            uint256 tokenANum=o.fromTokenNumber.sub(newInAmount);
                            while(tokenBIndex>0&&tokenANum>0){
                                {
                                    if(tokenANum>=getToNum(bo)){//如果全部成交也不够
                                        safeTransfer(
                                            IERC20(bo.toTokenAddr),
                                            bo.maker,
                                            getToNum(bo).mul(997).div(1000)
                                        );
                                        fee=fee.add(getToNum(bo).mul(3).div(1000));
                                        inAmountSum=inAmountSum.add(getToNum(bo));
                                        outAmountSum=outAmountSum.add(bo.remainNumber);
                                        uint newBIndex=_tokenPair.orderNextSequence[tokenBIndex];
                                        _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                                        _tokenPair.orderNextSequence[tokenBIndex]=0;
                                        if(newBIndex!=0){
                                            _tokenPair.orderPreSequence[newBIndex]=0;
                                        }
                                        _tokenPair.orderMap[tokenBIndex].toTokenSum=
                                        getToNum(bo).mul(997).div(1000).add(_tokenPair.orderMap[tokenBIndex].toTokenSum);
                                        _tokenPair.orderMap[tokenBIndex].remainNumber=0;
                                        _tokenPair.orderMap[tokenBIndex].timestamp=block.timestamp;
                                        tokenBIndex=newBIndex;
                                        if(tokenBIndex!=0){
                                            bo=_tokenPair.orderMap[tokenBIndex];
                                            newInAmount=getInAmount(bo.toTokenNumber,bo.fromTokenNumber,reserveA,reserveB);
                                            if(cInAmount>=newInAmount&&o.fromTokenNumber>=newInAmount.add(inAmountSum)){//继续向上一条订单价格推进
                                                tokenANum=o.fromTokenNumber.sub(newInAmount).sub(inAmountSum);
                                            }else{
                                                tokenANum=0;//停止向上遍列
                                            }
                                        }
                                    }else{//如果最后一条订单簿能成交够,部分成交订单簿
                                        uint256 atoNum=tokenANum.mul(997).div(1000);
                                        safeTransfer(
                                            IERC20(bo.toTokenAddr),
                                            bo.maker,
                                            atoNum
                                        );
                                        fee=fee.add(tokenANum.mul(3).div(1000));
                                        inAmountSum=inAmountSum.add(tokenANum);
                                        uint256 tokenBNum=atoNum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                                        outAmountSum=outAmountSum.add(tokenBNum);
                                        _tokenPair.orderMap[tokenBIndex].remainNumber=
                                            bo.remainNumber.sub(tokenBNum);
                                        _tokenPair.orderMap[tokenBIndex].toTokenSum=atoNum.add(bo.toTokenSum);
                                        _tokenPair.orderMap[tokenBIndex].timestamp=block.timestamp;
                                        tokenANum=0;//停止向上遍列
                                    }
                                }
                            }
                        }

                    }
                    uint256 inAmount=o.fromTokenNumber.sub(inAmountSum);
                    if(cInAmount<inAmount){
                        inAmount=cInAmount;
                    }
                    if(inAmount>0){
                        {
                            callOptionalReturn(
                                IERC20(o.fromTokenAddr),
                                abi.encodeWithSelector(
                                    IERC20(o.fromTokenAddr).transfer.selector, 
                                    getPair(o.fromTokenAddr, o.toTokenAddr), 
                                    inAmount
                                )
                            );
                            inAmountSum=inAmountSum.add(inAmount);
                            uint256 numerator = reserveA.mul(1000);
                            uint256 denominator = reserveB.sub(1).mul(997);
                            uint256 amountIn = (numerator / denominator).add(2);
                            if(inAmount>=amountIn){
                                uint256 amountOut=getAmountOut(inAmount,reserveA,reserveB);
                                (address token0,) =sortTokens(o.fromTokenAddr, o.toTokenAddr);
                                if(o.fromTokenAddr == token0){
                                    IUniswapV2Pair(getPair(o.fromTokenAddr, o.toTokenAddr)).swap(
                                        0, amountOut, address(this), new bytes(0)
                                    );
                                }else{
                                    IUniswapV2Pair(getPair(o.fromTokenAddr, o.toTokenAddr)).swap(
                                        amountOut, 0, address(this), new bytes(0)
                                    );
                                }
                                outAmountSum=outAmountSum.add(amountOut);
                            }
                        }
                    }
                    if(inAmountSum>0){
                        if(outAmountSum>0){
                            safeTransfer(
                                IERC20(o.toTokenAddr),
                                o.maker,
                                outAmountSum
                            );
                            _tokenPair.orderMap[orderIndex].toTokenSum=outAmountSum.add(
                            _tokenPair.orderMap[orderIndex].toTokenSum);
                        }
                        _tokenPair.orderMap[orderIndex].remainNumber=
                            o.fromTokenNumber.sub(inAmountSum);
                        _tokenPair.orderMap[orderIndex].timestamp=block.timestamp;
                        if(fee>0){
		                    safeTransfer(
		                        IERC20(o.fromTokenAddr),
		                        feeAddr,
		                        fee
		                    );
		                }
                        
                    }
                }

            }else{
                uint256 tokenBIndex=_tokenPair.lastIndex[o.toTokenAddr];
                uint256 inAmountSum=0;
                uint256 outAmountSum=0;
                uint256 tokenANum=o.fromTokenNumber;
                while(tokenBIndex!=0&&tokenANum!=0){
                    Order memory bo=_tokenPair.orderMap[tokenBIndex];
                    if(o.fromTokenNumber.mul(bo.fromTokenNumber)==o.toTokenNumber.mul(bo.toTokenNumber)){
                        tokenANum=o.fromTokenNumber.sub(inAmountSum);
                        uint256 toNum=getToNum(bo);
                        if(tokenANum>=toNum){
                            uint256 atoNum=toNum.mul(997).div(1000);
                            safeTransfer(
                                IERC20(bo.toTokenAddr),
                                bo.maker,
                                atoNum
                            );
                            fee=fee.add(toNum.mul(3).div(1000));
                            inAmountSum=inAmountSum.add(toNum);
                            outAmountSum=outAmountSum.add(bo.remainNumber);
                            uint newBIndex=_tokenPair.orderNextSequence[tokenBIndex];
                            _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                            _tokenPair.orderNextSequence[tokenBIndex]=0;
                            if(newBIndex!=0){
                                _tokenPair.orderPreSequence[newBIndex]=0;
                            }
                            _tokenPair.orderMap[tokenBIndex].toTokenSum=atoNum.add(_tokenPair.orderMap[tokenBIndex].toTokenSum);
                            _tokenPair.orderMap[tokenBIndex].remainNumber=0;
                            _tokenPair.orderMap[tokenBIndex].timestamp=block.timestamp;
                            tokenBIndex=newBIndex;
                        }else{
                            uint256 atoNum=tokenANum.mul(997).div(1000);
                            safeTransfer(
                                IERC20(bo.toTokenAddr),
                                bo.maker,
                                atoNum
                            );
                            fee=fee.add(tokenANum.mul(3).div(1000));
                            inAmountSum=o.fromTokenNumber;
                            uint256 tokenBNum=atoNum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                            outAmountSum=outAmountSum.add(tokenBNum);
                            _tokenPair.orderMap[tokenBIndex].remainNumber=
                                bo.remainNumber.sub(tokenBNum);
                            _tokenPair.orderMap[tokenBIndex].toTokenSum=atoNum.add(bo.toTokenSum);
                            _tokenPair.orderMap[tokenBIndex].timestamp=block.timestamp;
                            break;
                        }
                    }else{
                        break;
                    }
                }
                if(inAmountSum>0){
                    safeTransfer(
                        IERC20(o.toTokenAddr),
                        o.maker,
                        outAmountSum
                    );
                    if(fee>0){
                        safeTransfer(
                            IERC20(o.fromTokenAddr),
                            feeAddr,
                            fee
                        );
                    }
                    _tokenPair.orderMap[orderIndex].toTokenSum=outAmountSum.add(
                        _tokenPair.orderMap[orderIndex].toTokenSum);
                    _tokenPair.orderMap[orderIndex].remainNumber=
                        o.fromTokenNumber.sub(inAmountSum);
                    _tokenPair.orderMap[orderIndex].timestamp=block.timestamp;
                }
            }
        
    }
    function joinNumber(
        uint256 _number,
        uint256[] memory narray
    )internal pure returns(uint256[] memory){
        if(_number==0){
            return narray;
        }
        uint256 nl=narray.length;
        uint256[] memory narray1=new uint256[](nl+1);
        for(uint256 i=0;i<nl;i++){
            narray1[i]=narray[i];
        }
        narray1[nl]=_number;
        return narray1;
    }
    function getPageOrdersForMaker(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker,
        uint256 _type,//1:代表所有;2:代表已取消;3:代表已成交;4:代表未成交;5:代表已取消或者已成交
        uint256 _start,//开始位置
        uint256 _num//数量
    )public override view returns(uint256[] memory indexs){
        address pairAddr =getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                indexs=new uint256[](0);
                uint256[] memory cindexs=tokenPairArray[tokenPairIndex].ordersForAddress[_maker];
                uint256 cl=cindexs.length;
                uint256 i=_start;
                uint256 ll=0;
                while(i<cl){
                    if(_type==2){
                        if(!_IsCancelOrderIndex(cindexs[i],tokenPairIndex)){
                            i=i.add(1);
                            continue;
                        }
                        indexs=joinNumber(cindexs[i],indexs);
                    }
                    if(_type==3){
                        if(!_IsTradeCompleteOrderIndex(cindexs[i],tokenPairIndex)){
                            i=i.add(1);
                            continue;
                        }
                    }
                    if(_type==4){
                        if(!_IsTradeNotCompleteOrderIndex(cindexs[i],tokenPairIndex)){
                            i=i.add(1);
                            continue;
                        }
                    }
                    if(_type==5){
                        if(!(_IsTradeCompleteOrderIndex(cindexs[i],tokenPairIndex)||
                        _IsCancelOrderIndex(cindexs[i],tokenPairIndex))){
                            i=i.add(1);
                            continue;
                        }
                    }
                    indexs=joinNumber(cindexs[i],indexs);
                    if(ll==indexs.length){//新数组长度没变停止
                        break;
                    }
                    ll=indexs.length;//更新新数组长度
                    if(ll==_num){
                        break;
                    }
                    i=i.add(1);
                }
            }
        }
    }

    function getPageOrderDetailsForMaker(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker,
        uint256 _type,//1:代表所有;2:代表已取消;3:代表已成交;4:代表未成交;5:代表已取消或者已成交
        uint256 _start,//开始位置
        uint256 _num//数量
    )public override view returns(
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            if(tokenPairIndexMap[pairAddr]!=0){
                TokenPair storage tokenPair=tokenPairArray[tokenPairIndexMap[pairAddr]];
                uint256[] memory _orderIndexs=getPageOrdersForMaker(_fromTokenAddr,_toTokenAddr,_maker,_type,_start,_num);
                uint256 l=_orderIndexs.length;
                fromTokenAddrs=new address[](l);
                originalNumbers=new uint256[](l);
                currentNumbers=new uint256[](l);
                toTokenNumbers=new uint256[](l);
                timestamps=new uint256[](l);
                toTokenSums=new uint256[](l);
                for(uint256 i=0;i<l;i++){
                    Order memory o=tokenPair.orderMap[_orderIndexs[i]];
                    fromTokenAddrs[i]=o.fromTokenAddr;
                    toTokenNumbers[i]=o.toTokenNumber;
                    originalNumbers[i]=o.fromTokenNumber;
                    currentNumbers[i]=o.remainNumber;
                    timestamps[i]=o.timestamp;
                    toTokenSums[i]=o.toTokenSum;
                }
            }
        }
    }

    function getOrderByIndexBatch(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256[] memory _orderIndexs//必须是已存在的orderIndex，否则会得不到正确结果
    )public override view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage tokenPair=tokenPairArray[tokenPairIndex];
                uint256 l=_orderIndexs.length;
                makers=new  address[](l);
                fromTokenAddrs=new address[](l);
                originalNumbers=new uint256[](l);
                currentNumbers=new uint256[](l);
                toTokenNumbers=new uint256[](l);
                timestamps=new uint256[](l);
                toTokenSums=new uint256[](l);
                for(uint256 i=0;i<l;i++){
                    Order memory o=tokenPair.orderMap[_orderIndexs[i]];
                    makers[i]=o.maker;
                    fromTokenAddrs[i]=o.fromTokenAddr;
                    toTokenNumbers[i]=o.toTokenNumber;
                    originalNumbers[i]=o.fromTokenNumber;
                    currentNumbers[i]=o.remainNumber;
                    timestamps[i]=o.timestamp;
                    toTokenSums[i]=o.toTokenSum;
                }
            }
        }
    }
    function getOrderByIndex(// 根据订单号获取订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex
    )public override view returns(
        address maker,//挂单者
        address fromTokenAddr,// 代币地址
        uint256 remainNumber,//初始挂单量
        uint256 timestamp,//初始挂单时间
        uint256 currentNumber,//当前挂单存量
        uint256 toTokenNumber,//初始意向代币目标金额
        uint256 toTokenSum
    ){
        address pairAddr =getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                Order memory o=tokenPairArray[tokenPairIndex].orderMap[_orderIndex];
                maker=o.maker;
                fromTokenAddr=o.fromTokenAddr;
                toTokenNumber=o.toTokenNumber;
                remainNumber=o.fromTokenNumber;
                currentNumber=o.remainNumber;
                timestamp=o.timestamp;
                toTokenSum=o.toTokenSum;
            }
        }
    }

    function getPageOrderDetails(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )external override view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        return getOrderByIndexBatch(_fromTokenAddr,_toTokenAddr,
            getPageOrders(_fromTokenAddr,_toTokenAddr,_orderStartIndex,_records));
    }
    function getPageOrders(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )public override view returns(uint256[] memory orderIndexs){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage tokenPair=tokenPairArray[tokenPairIndex];
                if(tokenPair.orderNextSequence[_orderStartIndex]==0){
                    uint256 ordersLastIndex=tokenPair.lastIndex[_fromTokenAddr];
                    if(tokenPair.orderPreSequence[_orderStartIndex]!=0||
                    _orderStartIndex==ordersLastIndex){
                        orderIndexs=new uint256[](1);
                        orderIndexs[0]=_orderStartIndex;
                    }
                }else{
                    orderIndexs=new uint256[](1);
                    orderIndexs[0]=_orderStartIndex;
                    if(_records!=1){
                        uint256[] memory newOrderIndexs=joinNumber(
                            tokenPair.orderNextSequence[orderIndexs[0]],orderIndexs);
                        uint256 ll=newOrderIndexs.length;//新数组长度
                        uint256 orderNextSequence=tokenPair.orderNextSequence[newOrderIndexs[ll-1]];
                        while(orderNextSequence>0&&ll<_records){
                            newOrderIndexs=joinNumber(orderNextSequence,newOrderIndexs);
                            if(ll==newOrderIndexs.length){//新数组长度没变停止
                                break;
                            }
                            ll=newOrderIndexs.length;//更新新数组长度
                            orderNextSequence=tokenPair.orderNextSequence[newOrderIndexs[ll-1]];
                        }
                        orderIndexs=newOrderIndexs;
                    }
                }
            }
        }
    }
 
    function getOrderSums(//获取交易对所有订单总下单数(包括所有历史和已取消的订单)
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr// 买入token地址
    )public override view returns(uint256 orderMaxIndex){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                orderMaxIndex=tokenPairArray[tokenPairIndex].orderMaxIndex;
            }
        }
    }

    function getOrderSumsForMaker(//获取交易对某账户总下单数(包括所有历史和已取消的订单)
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        address _maker//必须是正确的数值
    )public override view returns(uint256 len){
        address pairAddr =getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
                if(_tokenPair.ordersForAddress[_maker].length!=0){
                    len=_tokenPair.ordersForAddress[_maker].length;
                }
            }
        }
    }

    function getClosestOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber,
        uint256 _depth
    )public override view returns (uint256 closestOrderIndex,uint8 end){
        if(_depth==0){
            return (_targetOrderIndex,0);
        }
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
                if(_tokenPair.orderNextSequence[_targetOrderIndex]==0
                	&&_tokenPair.orderPreSequence[_targetOrderIndex]==0){
                    _targetOrderIndex=_tokenPair.lastIndex[_fromTokenAddr];
                }
                if(_targetOrderIndex!=0){
                    Order memory o=_tokenPair.orderMap[_targetOrderIndex];
                    if(o.fromTokenAddr!=_fromTokenAddr){
                        _targetOrderIndex=_tokenPair.lastIndex[_fromTokenAddr];
                    }
                    if(_targetOrderIndex!=0){
				        if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)<=
				            _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
				            uint256 orderNextSequence=_tokenPair.orderNextSequence[_targetOrderIndex];
				            if(orderNextSequence==0){
				               return (_targetOrderIndex,1);
				            }else{
				                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderNextSequence].toTokenNumber)<=
				                    _tokenPair.orderMap[orderNextSequence].fromTokenNumber.mul(_toTokenNumber)){
				                    return getClosestOrderIndex(
				                        _fromTokenAddr,
				                        _toTokenAddr,
				                        orderNextSequence,
				                        _fromTokenNumber,
				                        _toTokenNumber,
				                        _depth.sub(1)
				                    );
				                }else{
				                    return (_targetOrderIndex,1);
				                }
				            }
				        }else{
				            uint256 orderPreIndex=_tokenPair.orderPreSequence[_targetOrderIndex];
				            if(orderPreIndex==0){
				                return (_targetOrderIndex,1);
				            }else{
				                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderPreIndex].toTokenNumber)>=
				                    _tokenPair.orderMap[orderPreIndex].fromTokenNumber.mul(_toTokenNumber)){
				                     return getClosestOrderIndex(
				                        _fromTokenAddr,
				                        _toTokenAddr,
				                        orderPreIndex,
				                        _fromTokenNumber,
				                        _toTokenNumber,
				                        _depth.sub(1)
				                    );
				                }else{
				                  return (_targetOrderIndex,1);
				                }
				            }
				        }
                    }
                }
            }
        }
    }
    function getLastOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr
    )public override view returns (uint256 lastOrderIndex){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                lastOrderIndex=tokenPairArray[tokenPairIndex].lastIndex[_fromTokenAddr];
            }
        }
    }
    function getNextOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public override view returns  (uint256 nextOrderIndex){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                if(tokenPairArray[tokenPairIndex].orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr){
                    nextOrderIndex=tokenPairArray[tokenPairIndex].orderNextSequence[_orderIndex];
                }
            }
        }
    }
    function getPreOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public override view returns (uint256 preOrderIndex){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        if(tokenPairIndex!=0){
            if(tokenPairArray[tokenPairIndex].orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr){
                preOrderIndex=tokenPairArray[tokenPairIndex].orderPreSequence[_orderIndex];
            }
        }
    }
     function getToNum(Order memory bo) internal pure returns (uint256 _to){
        _to=bo.toTokenNumber.mul(
            bo.remainNumber
        ).div(bo.fromTokenNumber).mul(1000).div(997);
    }
     /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function safeTransferHT(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: HT_TRANSFER_FAILED');
    }
     function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if(address(token)==whtAddr){
            IWHT(whtAddr).withdraw(value);
            safeTransferHT(to,value);
        }else{
            callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(isContract(address(token)));

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success,"transfer fail");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)),"transfer fail");
        }
    }
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    function IsCancelOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public override view returns (bool){
        address pairAddr = getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            require(tokenPairIndex!=0,"tokenPair not exist");
            return cancelMap[tokenPairIndex][_orderIndex]==1;
        }
        return false;
    }
    function _IsCancelOrderIndex(
        uint256 _orderIndex,
        uint256 _tokenPairIndex
    )internal view returns (bool){
        return cancelMap[_tokenPairIndex][_orderIndex]==1;
    }
    function _IsTradeCompleteOrderIndex(
        uint256 _orderIndex,
        uint256 _tokenPairIndex
    )internal view returns (bool){
        bool b=!_IsCancelOrderIndex(_orderIndex,_tokenPairIndex);
        return b&&_orderIndex!=tokenPairArray[_tokenPairIndex].lastIndex[tokenPairArray[_tokenPairIndex].orderMap[_orderIndex].fromTokenAddr]
        &&(tokenPairArray[_tokenPairIndex].orderNextSequence[_orderIndex]==0&&
        tokenPairArray[_tokenPairIndex].orderPreSequence[_orderIndex]==0);
    }
    function _IsTradeNotCompleteOrderIndex(
        uint256 _orderIndex,
        uint256 _tokenPairIndex
    )internal view returns (bool){
        return
        _orderIndex==tokenPairArray[_tokenPairIndex].lastIndex[tokenPairArray[_tokenPairIndex].orderMap[_orderIndex].fromTokenAddr]||
        tokenPairArray[_tokenPairIndex].orderNextSequence[_orderIndex]!=0||
        tokenPairArray[_tokenPairIndex].orderPreSequence[_orderIndex]!=0;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function getInAmount(
        uint256 fromNum,
        uint256 toNum,
        uint256 reserveA,
        uint256 reserveB
    ) public override pure returns(uint256 z){
        uint256 p=reserveA.mul(reserveB).div(toNum).div(997).mul(fromNum).mul(1000);
        uint256 q=reserveA.mul(reserveA).div(3964107892).mul(8973);
        uint256 x=sqrt(p.add(q));

        uint256 y=reserveA.mul(1997).div(1994);
        if(x>y){
            z=x.sub(y).add(1);
        }else{
            z=0;
        }
    }
    function getPair(address tokenA, address tokenB)  public override view returns (address){
        return uniswapV2Factory.getPair(tokenA, tokenB);
    }
}