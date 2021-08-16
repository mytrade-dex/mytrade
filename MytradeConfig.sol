//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor ()public {
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
contract MytradeConfig is Ownable{
    struct PairFactor{
        address token0;
        address token1;
        uint256 factorValue;
        uint256 maxLimit;
        uint256 minLimit;
    }
    uint256 public step;
    uint256 public blockAmout;
    struct ProductFactor{
         uint256 value;
         string  _type;
         string  key1;
         string  key2;
    }

    PairFactor[] public pairFactors;
    ProductFactor[] public productFactors;
    
    event UpdateStepAndBlockAmout(
        uint256 indexed step,
        uint256 indexed blockAmout
    );
    event UpdatePairFactor(
        address indexed token0,
        address indexed token1,
        uint256 indexed factorValue,
        uint256 maxLimit,
        uint256 minLimit
    );
    event CommitPairFactor(
        uint8 isCommited
    );
    function commitPairFactor() public onlyOwner{
        emit CommitPairFactor(1);
    } 
    event UpdateProductFactors(
        uint256 value
      
    );
    function updateStepAndBlockAmout(
        uint256 _step,
        uint256 _blockAmout
    ) public onlyOwner {
        step=_step;
        blockAmout=_blockAmout;
        emit UpdateStepAndBlockAmout(_step,_blockAmout);
    }
    
    function addPairFactor(
        address token0,
        address token1,
        uint256 factorValue,
        uint256 maxLimit,
        uint256 minLimit
    ) public onlyOwner {
               
    //  for(uint256 i;i<pairFactors.length;i++)  {
    //         require(((( token0==pairFactors[i].token0)&&(token1==pairFactors[i].token1))||
    //       ((token1==pairFactors[i].token0)&&(token0==pairFactors[i].token1))),"data exsit");
    //     }
     
       bool isExsit=false ;
            for(uint256 i;i<pairFactors.length;i++)  {
            
            if((( token0==pairFactors[i].token0)&&(token1==pairFactors[i].token1))||
          ((token1==pairFactors[i].token0)&&(token0==pairFactors[i].token1))){
                isExsit=true;
                break;
            }
        }
        require(!isExsit,"data exsit");
        pairFactors.push(PairFactor(
            token0,token1,factorValue,maxLimit,minLimit
        ));
        emit UpdatePairFactor(token0,token1,factorValue,maxLimit,minLimit);
    }
    function updatePairFactor(
        uint256 index,
        address token0,
        address token1,
        uint256 factorValue,
        uint256 maxLimit,
        uint256 minLimit
    ) public onlyOwner {
        pairFactors[index].token0=token0;
        pairFactors[index].token1=token1;
        pairFactors[index].factorValue=factorValue;
        pairFactors[index].maxLimit=maxLimit;
        pairFactors[index].minLimit=minLimit;
        emit UpdatePairFactor(token0,token1,factorValue,maxLimit,minLimit);
    }
    function addProductFactors(
        uint256 value,
        string  memory _type,
        string  memory key1,
        string  memory key2
    ) public onlyOwner{
        
        //   for(uint256 i;i<productFactors.length;i++)  {
        //   require((( keccak256(abi.encode(_type))==keccak256(abi.encode(productFactors[i]._type)))&&
        //   (keccak256(abi.encode(key1))==keccak256(abi.encode(productFactors[i].key1)))
        //   &&(keccak256(abi.encode(key2))==keccak256(abi.encode(productFactors[i].key2)) ))
        //   ,"data exsit");
        
     
        // }
        
           bool isExsit=false ;
            for(uint256 i;i<productFactors.length;i++)  {
            
            if(( keccak256(abi.encode(_type))==keccak256(abi.encode(productFactors[i]._type)))&&
           (keccak256(abi.encode(key1))==keccak256(abi.encode(productFactors[i].key1)))
           &&(keccak256(abi.encode(key2))==keccak256(abi.encode(productFactors[i].key2)) )){
                isExsit=true;
                break;
            }
        }
        require(!isExsit,"data exsit");
        productFactors.push(ProductFactor(
            value,_type,key1,key2
        ));
        emit UpdateProductFactors(productFactors.length);
    }
    
    function updateProductFactors(
        uint256 index,
        uint256 value,
        string  memory _type,
        string  memory key1,
        string  memory key2
    ) public onlyOwner{
        productFactors[index].value=value;
        productFactors[index]._type=_type;
        productFactors[index].key1=key1;
        productFactors[index].key2=key2;
        emit UpdateProductFactors(index+1);
    }
    function getPairFactors() public view returns(
        address[] memory token0s,
        address[] memory token1s,
        uint256[] memory factorValues,
        uint256[] memory maxLimits,
        uint256[] memory minLimits
    ){
        uint256 length=pairFactors.length;
        token0s=new address[](length);
        token1s=new address[](length);
        factorValues=new uint256[](length);
        maxLimits=new uint256[](length);
        minLimits=new uint256[](length);
        for(uint256 i;i<pairFactors.length;i++)  {
             token0s[i]=pairFactors[i].token0;
             token1s[i]=pairFactors[i].token1;
             factorValues[i]=pairFactors[i].factorValue;
             maxLimits[i]=pairFactors[i].maxLimit;
             minLimits[i]=pairFactors[i].minLimit;
        }
    }
     function getProductFactorsLen()public view returns(
        uint256 length
        
    )
    {
         length=productFactors.length;
    }
    function getProductFactors(uint256  index)public view returns(
        uint256  values,
        string  memory _types,
        string  memory key1s,
        string  memory key2s
    ){
        uint256 length=productFactors.length;
        if(index<length){
            values=productFactors[index].value;
            _types=productFactors[index]._type;
            key1s=productFactors[index].key1;
            key2s=productFactors[index].key2;
        }
    }
}