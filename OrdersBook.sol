pragma solidity =0.5.1;
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
library TransferHelper {
    event Log1(bool s,string n,address token, address to, uint256 value);
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, ) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        emit Log1(success,"safeApprove",token,to,value);
    }
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success,) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        emit Log1(success,"safeTransfer",token,to,value);
    }
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, ) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        emit Log1(success,"safeTransferFrom",token,to,value);
    }
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
library UniswapV2Library {
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return IUniswapV2Factory(factory).getPair(tokenA,tokenB);
    }
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () internal {
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
    )external payable returns(bool b,uint256 corderIndex) ;
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
        uint256 originalNumber,//初始挂单量
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
    function getOrderTimes(// 获取订单变更次数
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex//必须是正确的数值
    )external view returns(uint256 times);
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
        uint256 _toTokenNumber
    )external view returns (uint256 closestOrderIndex);
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
contract OrdersBook is Ownable,ReentrancyGuard,IOrdersBook{
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router02;
    IUniswapV2Factory public uniswapV2Factory;
    address payable public hpbForOrderAddress;
    uint256 constant UINT256_MAX = ~uint256(0);

    struct Order{
        address payable maker;
        address fromTokenAddr;
        address toTokenAddr;
        uint256[] originalNumbers;
        uint256[] timestamps;
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
    TokenPair[] tokenPairArray;// tokenPair数组
    mapping (address  => uint256) tokenPairIndexMap;// token0地址=>tokenPair数组下标
    constructor() payable public {
        hpbForOrderAddress=address(new HPBForOrder());
        tokenPairArray.push(TokenPair(0));
    }
    function initContract(address _uniswapV2Router02) public nonReentrant onlyOwner returns(bool){
        uniswapV2Router02=IUniswapV2Router02(_uniswapV2Router02);
        uniswapV2Factory=IUniswapV2Factory(uniswapV2Router02.factory());
    }
    function () payable external {
    }
    function cancelOrder(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex// 具体订单号（目前是订单的唯一性标识）
    )public nonReentrant returns(bool) {
        address pairAddr=getPair(_fromTokenAddr,_toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        require(tokenPairIndex!=0,"tokenPair不存在");
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        require(_tokenPair.orderMap[_orderIndex].maker==msg.sender);
        require(_orderIndex!=0);
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

        uint256 fromTokenNumber=_tokenPair.orderMap[_orderIndex].originalNumbers[
        _tokenPair.orderMap[_orderIndex].originalNumbers.length-1];
        if(fromTokenNumber>0){
            TransferHelper.safeTransfer(
                _fromTokenAddr,
                msg.sender,
                fromTokenNumber
            );
        }
        _tokenPair.orderMap[_orderIndex].timestamps.push(block.timestamp);
        if(_fromTokenAddr==hpbForOrderAddress){
            HPBForOrder(hpbForOrderAddress).withdrawForAddress(msg.sender);
        }
        return true;
    }

    function _orderIndexSequence(
        uint256 _targetOrderIndex,
        uint256 _orderIndex,
        TokenPair storage _tokenPair,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )internal{
        if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)<
            _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
            uint256 orderNextSequence=_tokenPair.orderNextSequence[_targetOrderIndex];
            if(orderNextSequence==0){
                _tokenPair.orderNextSequence[_targetOrderIndex]=_orderIndex;
                _tokenPair.orderPreSequence[_orderIndex]=_targetOrderIndex;
            }else{
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderNextSequence].toTokenNumber)<
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
                if(_fromTokenNumber.mul(_tokenPair.orderMap[orderPreIndex].toTokenNumber)>
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
    )public payable returns(bool) {
        (bool b,uint256 orderIndex)=addOrder(_fromTokenAddr,_toTokenAddr,
            _targetOrderIndex,_fromTokenNumber,_toTokenNumber/100000);
        address pairAddr=getPair(_fromTokenAddr,_toTokenAddr);
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        require(b&&tokenPairArray[tokenPairIndex].orderMap[orderIndex].toTokenSum>=_toTokenNumber);
        tokenPairArray[tokenPairIndex].orderMap[orderIndex].toTokenNumber=_toTokenNumber;
        return true;
    }
    function getToNum(Order memory bo) internal pure returns (uint256 _to){
        _to=bo.toTokenNumber.mul(
            bo.originalNumbers[bo.originalNumbers.length-1]
        )/bo.fromTokenNumber;
    }
    //event Log(string s,uint256 v);
    function addOrder(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _targetOrderIndex,
        uint256 _fromTokenNumber,
        uint256 _toTokenNumber
    )public payable nonReentrant returns(bool b,uint256 corderIndex) {
        address pairAddr=getPair(_fromTokenAddr,_toTokenAddr);
        if(_fromTokenAddr==hpbForOrderAddress){
            require(msg.value>=_fromTokenNumber);
            HPBForOrder(hpbForOrderAddress).deposit.value(msg.value)();
        }else{
            require(IERC20(_fromTokenAddr).balanceOf(msg.sender)>=_fromTokenNumber);
            require(IERC20(_fromTokenAddr).allowance(msg.sender,address(this))>=_fromTokenNumber);
            TransferHelper.safeTransferFrom(
                _fromTokenAddr,
                msg.sender,
                address(this),
                _fromTokenNumber
            );
        }
        uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
        if(tokenPairIndex== 0){//如果交易对不存在就新增一个
            tokenPairIndex= tokenPairArray.push(TokenPair(0))-1;
            tokenPairIndexMap[pairAddr]=tokenPairIndex;
        }
        TokenPair storage _tokenPair=tokenPairArray[tokenPairIndex];
        uint256 orderIndex=_tokenPair.orderMaxIndex.add(1);
        _tokenPair.orderMaxIndex=orderIndex;

        uint256 lastIndex=_tokenPair.lastIndex[_fromTokenAddr];
        //emit Log("lastIndex",lastIndex);
        if(lastIndex!=0){
            if(_targetOrderIndex==0){
                _targetOrderIndex=lastIndex;
            }else if(_tokenPair.orderNextSequence[_targetOrderIndex]==0
            &&_tokenPair.orderPreSequence[_targetOrderIndex]==0
            ){
                _targetOrderIndex=lastIndex;
            }else if(_tokenPair.orderMap[_targetOrderIndex].fromTokenAddr!=_fromTokenAddr){
                _targetOrderIndex=lastIndex;
            }
            _orderIndexSequence(_targetOrderIndex,orderIndex,_tokenPair,
                _fromTokenNumber,_toTokenNumber
            );
        }

        Order memory o=Order(msg.sender,_fromTokenAddr,_toTokenAddr,
            new uint256[](1),new uint256[](1),_fromTokenNumber,_toTokenNumber,0);
        o.originalNumbers[0]=_fromTokenNumber;
        o.timestamps[0]=block.timestamp;

        _tokenPair.orderMap[orderIndex]=o;
        _tokenPair.ordersForAddress[msg.sender].push(orderIndex);
        if(_tokenPair.orderPreSequence[orderIndex]==0){
            _tokenPair.lastIndex[o.fromTokenAddr]=orderIndex;
            (uint256 reserveA,uint256 reserveB)=UniswapV2Library.getReserves(
                address(uniswapV2Factory),o.fromTokenAddr, o.toTokenAddr);
            uint256 cInAmount=getInAmount(o.fromTokenNumber,o.toTokenNumber,reserveA,reserveB);//计算达到当前订单价格需要付出的币数量
            if(cInAmount>1){//如果流动池价格低于当前价格
                {
                    if(cInAmount>o.fromTokenNumber){
                        cInAmount=o.fromTokenNumber;
                    }
                    //emit Log("cInAmount",cInAmount);
                    uint256 inAmountSum=0;
                    uint256 outAmountSum=0;
                    uint256 tokenBIndex=_tokenPair.lastIndex[o.toTokenAddr];
                   /// emit Log("tokenBIndex",tokenBIndex);
                    if(tokenBIndex!=0){
                        Order memory bo=_tokenPair.orderMap[tokenBIndex];
                        uint256 newInAmount=getInAmount(
                            bo.toTokenNumber,bo.fromTokenNumber,reserveA,reserveB);//计算对手订单价格需要付出的币数量
                        if(cInAmount>=newInAmount){//全部成交超过对手订单价格
                            uint256 tokenANum=o.fromTokenNumber.sub(newInAmount);
                            while(tokenBIndex>0&&tokenANum>0){
                                {
                                    if(tokenANum>=getToNum(bo)){//如果全部成交也不够
                                        TransferHelper.safeTransfer(
                                            bo.toTokenAddr,
                                            bo.maker,
                                            getToNum(bo)
                                        );
                                        if(bo.toTokenAddr==hpbForOrderAddress){
                                            HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                                        }
                                        inAmountSum=inAmountSum.add(getToNum(bo));
                                        outAmountSum=outAmountSum.add(bo.originalNumbers[bo.originalNumbers.length-1]);
                                        uint newBIndex=_tokenPair.orderNextSequence[tokenBIndex];
                                        _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                                        _tokenPair.orderNextSequence[tokenBIndex]=0;
                                        if(newBIndex!=0){
                                            _tokenPair.orderPreSequence[newBIndex]=0;
                                        }
                                        _tokenPair.orderMap[tokenBIndex].toTokenSum=getToNum(bo).add(_tokenPair.orderMap[tokenBIndex].toTokenSum);
                                        _tokenPair.orderMap[tokenBIndex].originalNumbers.push(0);
                                        _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
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
                                        TransferHelper.safeTransfer(
                                            bo.toTokenAddr,
                                            bo.maker,
                                            tokenANum
                                        );
                                        if(bo.toTokenAddr==hpbForOrderAddress){
                                            HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                                        }
                                        inAmountSum=inAmountSum.add(tokenANum);
                                        uint256 tokenBNum=tokenANum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                                        outAmountSum=outAmountSum.add(tokenBNum);
                                        _tokenPair.orderMap[tokenBIndex].originalNumbers.push(
                                            bo.originalNumbers[bo.originalNumbers.length-1].sub(tokenBNum));
                                        _tokenPair.orderMap[tokenBIndex].toTokenSum=tokenANum.add(bo.toTokenSum);
                                        _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
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
                            uint256 numerator = reserveA.mul(1000);
                            uint256 denominator = reserveB.sub(1).mul(997);
                            uint256 amountIn = (numerator / denominator).add(2);
                           // emit Log("amountIn",amountIn);
                            //emit Log("inAmount",inAmount);
                            
                            if(inAmount>=amountIn){
                                inAmountSum=inAmountSum.add(inAmount);
                                outAmountSum=outAmountSum.add(_checkUniswapToTrade(inAmount,o.fromTokenAddr,o.toTokenAddr));
                            }else{
                               inAmountSum=o.fromTokenNumber;
                            }
                        }
                    }
                    if(inAmountSum>0){
                        TransferHelper.safeTransfer(
                            o.toTokenAddr,
                            o.maker,
                            outAmountSum
                        );
                        if(o.toTokenAddr==hpbForOrderAddress){
                            HPBForOrder(hpbForOrderAddress).withdrawForAddress(o.maker);
                        }
                        _tokenPair.orderMap[orderIndex].toTokenSum=outAmountSum.add(
                            _tokenPair.orderMap[orderIndex].toTokenSum);
                        _tokenPair.orderMap[orderIndex].originalNumbers.push(
                            o.fromTokenNumber.sub(inAmountSum));
                        _tokenPair.orderMap[orderIndex].timestamps.push(block.timestamp);
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
                        if(tokenANum>=getToNum(bo)){
                            TransferHelper.safeTransfer(
                                bo.toTokenAddr,
                                bo.maker,
                                getToNum(bo)
                            );
                            if(bo.toTokenAddr==hpbForOrderAddress){
                                HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                            }
                            inAmountSum=inAmountSum.add(getToNum(bo));
                            outAmountSum=outAmountSum.add(bo.originalNumbers[bo.originalNumbers.length-1]);
                            uint newBIndex=_tokenPair.orderNextSequence[tokenBIndex];
                            _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                            _tokenPair.orderNextSequence[tokenBIndex]=0;
                            if(newBIndex!=0){
                                _tokenPair.orderPreSequence[newBIndex]=0;
                            }
                            _tokenPair.orderMap[tokenBIndex].toTokenSum=getToNum(bo).add(_tokenPair.orderMap[tokenBIndex].toTokenSum);
                            _tokenPair.orderMap[tokenBIndex].originalNumbers.push(0);
                            _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
                            tokenBIndex=newBIndex;
                        }else{
                            TransferHelper.safeTransfer(
                                bo.toTokenAddr,
                                bo.maker,
                                tokenANum
                            );
                            if(bo.toTokenAddr==hpbForOrderAddress){
                                HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                            }
                            inAmountSum=o.fromTokenNumber;
                            uint256 tokenBNum=tokenANum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                            outAmountSum=outAmountSum.add(tokenBNum);
                            _tokenPair.orderMap[tokenBIndex].originalNumbers.push(
                                bo.originalNumbers[bo.originalNumbers.length-1].sub(tokenBNum));
                            _tokenPair.orderMap[tokenBIndex].toTokenSum=tokenANum.add(bo.toTokenSum);
                            _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
                            break;
                        }
                    }else{
                        break;
                    }
                }
                if(inAmountSum>0){
                    TransferHelper.safeTransfer(
                        o.toTokenAddr,
                        o.maker,
                        outAmountSum
                    );
                    if(o.toTokenAddr==hpbForOrderAddress){
                        HPBForOrder(hpbForOrderAddress).withdrawForAddress(o.maker);
                    }
                    _tokenPair.orderMap[orderIndex].toTokenSum=outAmountSum.add(
                        _tokenPair.orderMap[orderIndex].toTokenSum);
                    _tokenPair.orderMap[orderIndex].originalNumbers.push(
                        o.fromTokenNumber.sub(inAmountSum));
                    _tokenPair.orderMap[orderIndex].timestamps.push(block.timestamp);
                }
            }
        }
        uint256 reserveNum=_tokenPair.orderMap[orderIndex].originalNumbers[
        _tokenPair.orderMap[orderIndex].originalNumbers.length-1];
        if(reserveNum!=0&&o.toTokenNumber==1){//如果是市价单
            uint256 toTokenSum=0;
            uint256 tokenBIndex=_tokenPair.lastIndex[o.toTokenAddr];
            while(tokenBIndex!=0&&reserveNum!=0){
                Order memory bo=_tokenPair.orderMap[tokenBIndex];
                if(reserveNum>=getToNum(bo)){
                    reserveNum=reserveNum.sub(getToNum(bo));
                    TransferHelper.safeTransfer(
                        bo.toTokenAddr,
                        bo.maker,
                        getToNum(bo)
                    );
                    if(bo.toTokenAddr==hpbForOrderAddress){
                        HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                    }
                    toTokenSum=toTokenSum.add(bo.originalNumbers[bo.originalNumbers.length-1]);
                    uint newBIndex=_tokenPair.orderNextSequence[tokenBIndex];
                    _tokenPair.lastIndex[o.toTokenAddr]=newBIndex;
                    _tokenPair.orderNextSequence[tokenBIndex]=0;
                    _tokenPair.orderMap[tokenBIndex].toTokenSum=getToNum(bo).add(_tokenPair.orderMap[tokenBIndex].toTokenSum);
                    _tokenPair.orderMap[tokenBIndex].originalNumbers.push(0);
                    _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
                    if(newBIndex!=0){
                        _tokenPair.orderPreSequence[newBIndex]=0;
                    }
                    tokenBIndex=newBIndex;
                }else{
                    uint256 tokenBNum=reserveNum.mul(bo.fromTokenNumber) / bo.toTokenNumber;
                    if(tokenBNum<2){
                        reserveNum=0;
                        break;
                    }
                    TransferHelper.safeTransfer(
                        bo.toTokenAddr,
                        bo.maker,
                        reserveNum
                    );
                    if(bo.toTokenAddr==hpbForOrderAddress){
                        HPBForOrder(hpbForOrderAddress).withdrawForAddress(bo.maker);
                    }
                    toTokenSum=toTokenSum.add(tokenBNum);
                    _tokenPair.orderMap[tokenBIndex].originalNumbers.push(
                        bo.originalNumbers[bo.originalNumbers.length-1].sub(tokenBNum));
                    _tokenPair.orderMap[tokenBIndex].toTokenSum=reserveNum.add(bo.toTokenSum);
                    _tokenPair.orderMap[tokenBIndex].timestamps.push(block.timestamp);
                    reserveNum=0;
                }
            }
            if(toTokenSum!=0){
                TransferHelper.safeTransfer(
                    o.toTokenAddr,
                    o.maker,
                    toTokenSum
                );
                if(o.toTokenAddr==hpbForOrderAddress){
                    HPBForOrder(hpbForOrderAddress).withdrawForAddress(o.maker);
                }
                _tokenPair.orderMap[orderIndex].toTokenSum=_tokenPair.orderMap[orderIndex].toTokenSum.add(toTokenSum);
                _tokenPair.orderMap[orderIndex].originalNumbers[
                _tokenPair.orderMap[orderIndex].originalNumbers.length-1]=reserveNum;
                _tokenPair.orderMap[orderIndex].timestamps[
                _tokenPair.orderMap[orderIndex].timestamps.length-1]=block.timestamp;
            }else if(reserveNum==0){
                _tokenPair.orderMap[orderIndex].originalNumbers[
                _tokenPair.orderMap[orderIndex].originalNumbers.length-1]=reserveNum;
            }
        }
        if(reserveNum==0){
            _tokenPair.lastIndex[o.fromTokenAddr]=_tokenPair.orderNextSequence[orderIndex];
            if(_tokenPair.lastIndex[o.fromTokenAddr]!=0){
                _tokenPair.orderPreSequence[_tokenPair.lastIndex[o.fromTokenAddr]]=0;
            }
            _tokenPair.orderNextSequence[orderIndex]=0;
        }
        corderIndex=orderIndex;
        b=true;
    }
    function _checkUniswapToTrade(
        uint256 amountInput,
        address _fromTokenAddr,
        address _toTokenAddr
    ) internal returns(uint result){
        TransferHelper.safeApprove(
            _fromTokenAddr,
            address(uniswapV2Router02),
            UINT256_MAX
        );
        address[] memory _addressPair = new address[](2);
        _addressPair[0] = _fromTokenAddr;
        _addressPair[1] = _toTokenAddr;
        uint256[] memory _swapResult=uniswapV2Router02.swapExactTokensForTokens(
            amountInput,
            0,
            _addressPair,
            address(this),
            UINT256_MAX
        );
        result=_swapResult[1];
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
    )public view returns(uint256[] memory indexs){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
    )public view returns(
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
                    originalNumbers[i]=o.originalNumbers[0];
                    currentNumbers[i]=o.originalNumbers[o.originalNumbers.length-1];
                    timestamps[i]=o.timestamps[0];
                    toTokenSums[i]=o.toTokenSum;
                }
            }
        }
    }

    function getOrderByIndexBatch(
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256[] memory _orderIndexs//必须是已存在的orderIndex，否则会得不到正确结果
    )public view returns(
        address[] memory makers,//挂单者
        address[] memory fromTokenAddrs,// 代币地址
        uint256[] memory originalNumbers,//初始挂单量
        uint256[] memory timestamps,//初始挂单时间
        uint256[] memory currentNumbers,//当前挂单存量
        uint256[] memory toTokenNumbers,//初始意向代币目标金额
        uint256[] memory toTokenSums//已经获取的金额
    ){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
                    originalNumbers[i]=o.originalNumbers[0];
                    currentNumbers[i]=o.originalNumbers[o.originalNumbers.length-1];
                    timestamps[i]=o.timestamps[0];
                    toTokenSums[i]=o.toTokenSum;
                }
            }
        }
    }
    function getOrderByIndex(// 根据订单号获取订单
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex
    )public view returns(
        address maker,//挂单者
        address fromTokenAddr,// 代币地址
        uint256 originalNumber,//初始挂单量
        uint256 timestamp,//初始挂单时间
        uint256 currentNumber,//当前挂单存量
        uint256 toTokenNumber,//初始意向代币目标金额
        uint256 toTokenSum
    ){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                Order memory o=tokenPairArray[tokenPairIndex].orderMap[_orderIndex];
                maker=o.maker;
                fromTokenAddr=o.fromTokenAddr;
                toTokenNumber=o.toTokenNumber;
                originalNumber=o.originalNumbers[0];
                currentNumber=o.originalNumbers[o.originalNumbers.length-1];
                timestamp=o.timestamps[0];
                toTokenSum=o.toTokenSum;
            }
        }
    }

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
    ){
        return getOrderByIndexBatch(_fromTokenAddr,_toTokenAddr,
            getPageOrders(_fromTokenAddr,_toTokenAddr,_orderStartIndex,_records));
    }
    function getPageOrders(// 分页获取所有订单号
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderStartIndex,// 订单序号点
        uint256 _records// 每次获取的个数
    )public view returns(uint256[] memory orderIndexs){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
    function getOrderTimes(// 获取订单变更次数
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr,// 买入token地址
        uint256 _orderIndex//必须是正确的数值
    )public view returns(uint256 times){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                times=tokenPairArray[tokenPairIndex].orderMap[_orderIndex].timestamps.length;
            }
        }
    }
    function getOrderSums(//获取交易对所有订单总下单数(包括所有历史和已取消的订单)
        address _fromTokenAddr,// 卖出token地址
        address _toTokenAddr// 买入token地址
    )public view returns(uint256 orderMaxIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
    )public view returns(uint256 len){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
        uint256 _toTokenNumber
    )public view returns (uint256 closestOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
                        if(_fromTokenNumber.mul(o.toTokenNumber)<o.fromTokenNumber.mul(_toTokenNumber)){
                            if(_tokenPair.orderNextSequence[_targetOrderIndex]==0){
                                closestOrderIndex=_targetOrderIndex;
                            }else{
                                closestOrderIndex=getClosestOrderIndex(_fromTokenAddr,_toTokenAddr,
                                    _tokenPair.orderNextSequence[_targetOrderIndex],_fromTokenNumber,_toTokenNumber);
                            }
                        }else{
                            if(_tokenPair.orderPreSequence[_targetOrderIndex]==0){
                                closestOrderIndex=_targetOrderIndex;
                            }else{
                                uint256 orderPreIndex=_tokenPair.orderPreSequence[_targetOrderIndex];
                                if(_fromTokenNumber.mul(_tokenPair.orderMap[_targetOrderIndex].toTokenNumber)>
                                    _tokenPair.orderMap[_targetOrderIndex].fromTokenNumber.mul(_toTokenNumber)){
                                    closestOrderIndex=getClosestOrderIndex(_fromTokenAddr,_toTokenAddr,
                                        orderPreIndex,_fromTokenNumber,_toTokenNumber);
                                }else{
                                    closestOrderIndex=_targetOrderIndex;
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
    )public view returns (uint256 lastOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
    )public view returns  (uint256 nextOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
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
    )public view returns (uint256 preOrderIndex){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                if(tokenPairArray[tokenPairIndex].orderMap[_orderIndex].fromTokenAddr==_fromTokenAddr){
                    preOrderIndex=tokenPairArray[tokenPairIndex].orderPreSequence[_orderIndex];
                }
            }
        }
    }
    function getPair(address tokenA, address tokenB)  public view returns (address){
        address _pairAddress = uniswapV2Factory.getPair(tokenA, tokenB);
        require(_pairAddress != address(0), "Unavailable pair address");
        return _pairAddress;
    }
    function IsCancelOrderIndex(
        address _fromTokenAddr,
        address _toTokenAddr,
        uint256 _orderIndex
    )public view returns (bool){
        address pairAddr = uniswapV2Factory.getPair(_fromTokenAddr, _toTokenAddr);
        if(pairAddr!=address(0)){
            uint256 tokenPairIndex=tokenPairIndexMap[pairAddr];
            if(tokenPairIndex!=0){
                return _IsCancelOrderIndex(_orderIndex,tokenPairIndex);
            }
        }
        return false;
    }
    function _IsCancelOrderIndex(
        uint256 _orderIndex,
        uint256 _tokenPairIndex
    )internal view returns (bool){
        return tokenPairArray[_tokenPairIndex].orderMap[_orderIndex].timestamps.length!=
        tokenPairArray[_tokenPairIndex].orderMap[_orderIndex].originalNumbers.length;
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
    ) public pure returns(uint256 z){
        uint256 p=(reserveA.mul(reserveB)/toNum/997).mul(fromNum).mul(1000);
        uint256 q=(reserveA.mul(reserveA)/3964107892).mul(8973);
        uint256 x=sqrt(p.add(q));

        uint256 y=reserveA.mul(1997)/1994;
        if(x>y){
            z=x.sub(y).add(1);
        }else{
            z=0;
        }
    }

}
contract HPBForOrder is Ownable{
    string public name     = "Wrapped HPB For Order";
    string public symbol   = "WHPB";
    uint8  public decimals = 18;

    event  Approval(address indexed hsrc, address indexed hguy, uint hwad);
    event  Transfer(address indexed hsrc, address indexed hdst, uint hwad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
    function withdrawForAddress(address payable to) public onlyOwner {
        uint wad=balanceOf[to];
        if(wad>0){
            to.transfer(wad);
            balanceOf[to]=0;
            emit Withdrawal(to, wad);
        }
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool){
        require(balanceOf[src] >= wad);
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }
}
