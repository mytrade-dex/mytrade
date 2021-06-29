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
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: MyTradeOrderBook TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: MyTradeOrderBook ETH_TRANSFER_FAILED');
    }
}
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

}
contract MyTradeOrderMining is Ownable,ReentrancyGuard{
    using SafeMath for uint;
    IUniswapV2Factory immutable public uniswapV2Factory;
    constructor(
        address _uniswapV2Factory,
        uint _startBlock
    ) payable  {
        startBlock = _startBlock;
        uniswapV2Factory=IUniswapV2Factory(_uniswapV2Factory);
        userInfoArray.push();
    }
    receive() external payable { 
    }
    fallback(bytes calldata _input) external payable returns (bytes memory _output){
    }
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
    uint public maxLimitTimes=10;
   
    function setMaxLimitTimes(
        uint _maxLimitTimes
    ) onlyApproved(msg.sender) public returns(bool) {
        maxLimitTimes= _maxLimitTimes;
        return true;
    }
    address public userRewardToken;
    function setUserRewardToken(
        address _userRewardToken
    ) onlyApproved(msg.sender) public returns(bool) {
        userRewardToken=_userRewardToken;
        return true;
    }
    address public totalPoolAddr;
    function setTotalPoolAddr(
        address _totalPoolAddr
    ) onlyApproved(msg.sender) public returns(bool) {
        totalPoolAddr=_totalPoolAddr;
        return true;
    }
    uint public orderMiningPerBlock;
    function setOrderMiningPerBlock(
        uint _orderMiningPerBlock
    ) onlyApproved(msg.sender) public returns(bool) {
        orderMiningPerBlock=_orderMiningPerBlock;
        return true;
    }
    function updatetUserRewardByOuter() public nonReentrant() returns (bool){
        return updateUserReward();
    }
    // The block number when mining starts.
    uint256 public startBlock;
    function setOrderMiningStartBlock(
        uint _startBlock
    ) onlyApproved(msg.sender) public returns(bool) {
        startBlock=_startBlock;
        return true;
    }
    struct TokenPairMining{
        mapping(uint256=> uint256) blockNums;// orderIndex=》blocknum
    }
    uint256 public poolSumQuantity;
    uint256 public poolQuantity;
    struct UserInfo {
        address maker;
        uint256 reward;
        uint256 sumQuantity;
        uint256 quantity;
        uint256 blockNumber;
    }
    UserInfo[] public userInfoArray;// UserInfo数组
    mapping (address  => uint256) public userInfoIndexMap;// maker地址=>userInfoArray数组下标
    uint256[] public settlements;
    event UpdateUserQuantity(
        address indexed orderMaker,
        uint256 quantity
    );
    function updatetUserQuantity(
        address _orderMaker,
        uint256 _quantity
    ) public onlyApproved(msg.sender) returns (bool){
        uint256 userInfoIndex=userInfoIndexMap[_orderMaker];
        if(userInfoIndex== 0){//如果交易对不存在就新增一个
            userInfoArray.push();
            userInfoIndex=userInfoArray.length-1 ;
            userInfoIndexMap[_orderMaker]=userInfoIndex;
            userInfoArray[userInfoIndex].maker=_orderMaker;
            userInfoArray[userInfoIndex].blockNumber=block.number;
        }
        if(userInfoArray[userInfoIndex].quantity==0){
            settlements.push();
            settlements[settlements.length-1]=userInfoIndex;
        }
        userInfoArray[userInfoIndex].quantity=userInfoArray[userInfoIndex].quantity.add(_quantity);
        emit UpdateUserQuantity(_orderMaker,_quantity);
        return true;
    }
    
    function updateUserReward() public returns (bool){
        if(block.number > startBlock){
            uint256 reward=block.number.sub(startBlock).mul(orderMiningPerBlock);
            startBlock=block.number;
            TransferHelper.safeTransferFrom(
                userRewardToken,
                totalPoolAddr,
                address(this),
                reward
            );
        }
        for(uint i=0;i<maxLimitTimes;i++){
            if(settlements.length==0){
                break;
            }
            _updateReward(settlements[settlements.length-1]);
            delete settlements[settlements.length-1];
            settlements.pop();
        }
        return true;
    }
    
    function _updateReward(uint userInfoIndex) internal {
        uint _quantity=userInfoArray[userInfoIndex].quantity;
        userInfoArray[userInfoIndex].sumQuantity=userInfoArray[userInfoIndex].sumQuantity.add(_quantity);
        poolSumQuantity=poolSumQuantity.add(_quantity);
        poolQuantity=poolQuantity.add(_quantity);
        userInfoArray[userInfoIndex].reward=userInfoArray[userInfoIndex].reward.add(
            IERC20(userRewardToken).balanceOf(address(this)).mul(_quantity).div(poolQuantity)
        );
        userInfoArray[userInfoIndex].quantity=0;
    }
    function withdrawUserReward() public nonReentrant returns (bool){
        uint256 userInfoIndex=userInfoIndexMap[msg.sender];
        require(userInfoIndex!= 0);
        require(updateUserReward());
        require(userInfoArray[userInfoIndex].reward>0);
        TransferHelper.safeTransfer(
            userRewardToken,
            msg.sender,
            userInfoArray[userInfoIndex].reward
        );
        userInfoArray[userInfoIndex].reward=0;
        return true;
    }
}