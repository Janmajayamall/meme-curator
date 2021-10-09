import './libraries/MultiSigWallet.sol';
import './interfaces/IModerationCommitee.sol';

contract OracleMultiSig is MultiSigWallet, IModerationCommitte {

    Fee public fee;
    bool public isActive;
    address public tokenC;
    uint public expireAfterBlocks;
    uint public donEscalationLimit;
    uint public donBufferBlocks;
    uint public resolutionBufferBlocks;


    constructor(address[] memory _owners, uint _required, uint maxCount) MultiSigWallet(_owners, _required, maxCount) {}

    function getMarketParams() external view returns (bool, uint, uint, address, uint, uint, uint, uint){
        return (
            isActive, 
            fee.numerator,
            fee.denominator,
            tokenC,
            expireAfterBlocks,
            donEscalationLimit,
            donBufferBlocks,
            resolutionBufferBlocks
        );
    }

    function setupOracle(bool _isActive, uint _feeNum, uint _feeDenom, address _tokenC, uint _expireAfterBlocks, uint _donEscalationLimit, uint _donBufferBlocks, uint _resolutionBufferBlocks) external {
        require(_feeNum <= _feeDenom);
        isActive = _isActive;
        Fee storage _fee = fee;
        _fee.numerator = _feeNum;
        _fee.denominator = _feeDenom;
        tokenC = _tokenC;
        expireAfterBlocks = _expireAfterBlocks;
        donEscalationLimit = _donEscalationLimit;
        donBufferBlocks = _donBufferBlocks;
        resolutionBufferBlocks = _resolutionBufferBlocks;
    }

    /* 
        In factory always check whether the oracle is active or not
     */

    function changeFee(uint _feeNum, uint _feeDenom) external onlyWallet {
        require(_feeNum <= _feeDenom);
        Fee storage _fee = fee;
        fee.numerator = _feeNum;
        fee.denominator = _feeDenom;
    }   

    function changeActive(bool _isActive) external onlyWallet {
        isActive = _isActive;
    }
    
    function changeTokenC(address _tokenC) external onlyWallet {
        tokenC = _tokenC;
    }

    function changeActive(uint _expireAfterBlocks) external onlyWallet {
        expireAfterBlocks = _expireAfterBlocks;
    }

    function changeDonEscalationLimit(uint _donEscalationLimit) external onlyWallet {
        donEscalationLimit = _donEscalationLimit;
    }

    function changeDonBufferBlocks(uint _donBufferBlocks) external onlyWallet {
        donBufferBlocks = _donBufferBlocks;
    }

    function changeResolutionBufferBlocks(uint _resolutionBufferBlocks) external onlyWallet {
        resolutionBufferBlocks = _resolutionBufferBlocks;
    }

    /* 
    Helper functions for adding txs for functions above
     */
    function addTxSetupOracle(bool _isActive, uint _feeNum, uint _feeDenom, address _tokenC, uint _expireAfterBlocks, uint _donEscalationLimit, uint _donBufferBlocks, uint _resolutionBufferBlocks) external ownerExists(msg.sender) {
        bytes memory data = abi.encodeWithSignature(
            "setupOracle(bool,uint,uint,address,uint,uint,uint,uint)", 
            _isActive, _feeNum, _feeDenom, _tokenC, _expireAfterBlocks,_donEscalationLimit, _donBufferBlocks, _resolutionBufferBlocks
            );
        addTransaction(address(this), 0, data);
    }


}