pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../../libraries/Math.sol";
import "./../../../OutcomeToken.sol";
import "./../../../MemeToken.sol";
import "./../../../OracleMultiSig.sol";
import "./../../../Market.sol";
import "./../../../MarketRouter.sol";
import "./../../../MarketFactory.sol";

contract GasMarketTestShared is DSTest {
    struct OracleConfig {
        address tokenC;
        bool isActive;
        uint8 feeNumerator;
        uint8 feeDenominator;
        uint16 donEscalationLimit;
        uint32 expireBufferBlocks;
        uint32 donBufferBlocks;
        uint32 resolutionBufferBlocks;
    }

    struct DeployParams {
        address creator;
        address oracle;
        bytes32 identifier;
    }

    address oracle;
    address marketAddress;
    address memeToken;
    DeployParams public deployParams;
    OracleConfig sharedOracleConfig;

    address marketRouter;
    address marketFactory;

    address hevm = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    function commonSetup() virtual public {
        address[] memory oracleOwners = new address[](1);

        // setup meme token & mint max tokens 
        memeToken = address(new MemeToken());
        MemeToken(memeToken).mint(address(this), type(uint).max);

        // setup oracle
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        sharedOracleConfig = OracleConfig(
            memeToken,
            true, 
            10, 
            100, 
            5, 
            10, 
            10, 
            10);
        OracleMultiSig(oracle).addTxSetupOracle(
            sharedOracleConfig.tokenC,
            sharedOracleConfig.isActive,
            sharedOracleConfig.feeNumerator,
            sharedOracleConfig.feeDenominator,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.expireBufferBlocks,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );  

        // setup oracle deploy params 
        deployParams = DeployParams({
            creator:address(this),
            oracle:oracle,
            identifier:0x0401030400040101040403020201030003000000010202020104010201000103
        });
        marketAddress = address(new Market());

        // setup market factory
        marketFactory = address(new MarketFactory());

        // setup market router
        marketRouter = address(new MarketRouter(marketFactory));

        // give max approval to market router
        MemeToken(memeToken).approve(marketRouter, type(uint256).max);
    }

    function setUp() virtual public {
        commonSetup();
    }

}