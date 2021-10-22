// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../libraries/Math.sol";
import "./../../OutcomeToken.sol";
import "./../../OracleMultiSig.sol";
import "./../../Market.sol";
contract GasMathTest is DSTest {

    struct OracleConfig {
        bool isActive;
        uint feeNum;
        uint feeDenom;
        address tokenC;
        uint expireAfterBlocks;
        uint donEscalationLimit;
        uint donBufferBlocks;
        uint resolutionBufferBlocks;
    }
    address oracle;


    function setUp() public {
        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        OracleConfig memory sharedOracleConfig = OracleConfig(true, 10, 100, address(this), 10, 5, 10, 10);
        OracleMultiSig(oracle).addTxSetupOracle(
            sharedOracleConfig.isActive,
            sharedOracleConfig.feeNum,
            sharedOracleConfig.feeDenom,
            sharedOracleConfig.tokenC,
            sharedOracleConfig.expireAfterBlocks,
            sharedOracleConfig.donEscalationLimit,
            sharedOracleConfig.donBufferBlocks,
            sharedOracleConfig.resolutionBufferBlocks
        );   
    }

    // function test_plusN() public {
    //     uint a =1329227995784915872903807060280344574;
    //     uint b =1329227995784915872903807060280344574;
    //     uint c = a+b;
    // }
    // function test_plusNOUTUUUUUUU() public {
    //     uint a =1329227995784915872903807060280344574;
    //     uint b =1329227995784915872903807060280344574;
    //     uint c;
    //     assembly {
    //         // if iszero(0){
    //         //     let b := mul(1329227995784915872903807060280344574,1329227995784915872903807060280344574)
    //         // }
    //         function safeMul(_a,_b) -> _v {
    //                 _v := add(_a,_b)
    //                 if or(lt(_v,_a), lt(_v,_b)) {revert(0,0)}
    //             }
    //         c := safeMul(a,b)
    //     }
    // }

    // function test_useless() public {
    //     uint a = (type(uint256).max/2)+2;
    //     uint b;
    //     assembly {
    //         b := mul(a,2)
    //     }
    //     emit log_named_uint("dad", b);
    //     assertEq(uint(0),uint(1));
    // }

    // function test_getAmountCToBuyTokens() public {
    //     uint a = Math.getAmountCToBuyTokens(
    //         1329227995784915872903807060280344575, 
    //         1093260665644886653583746608747661123, 
    //         1329227995784915872903807060280344575, 
    //         1329227995784915872903807060280344574
    //     );
    // }

    // function test_sqrt() external {
    //     Math.sqrt(type(uint256).max);
    // }

    // function test_getAmountCBySellTokens() public {
    //     uint a = Math.getAmountCBySellTokens(
    //         99929545749180196506802031401635932, 
    //         1329227995784915872903807060280344575, 
    //         1329227995784915872903807060280344574, 
    //         1111871825054533892096512879497761333
    //     );
    // }

    // function test_getTokenAmountToBuyWithAmountC() public {
    //     uint a0 = Math.getTokenAmountToBuyWithAmountC(
    //         0, 
    //         1, 
    //         551455025153312868521400950885683982, 
    //         1329227995784915872903807060280344575, 
    //         40698612001058230291149623598822520
    //     );
    // }

    // function test_getTokenAmountToSellForAmountC() public {         
    //     uint a0 = Math.getTokenAmountToSellForAmountC(
    //         0, 
    //         1, 
    //         1329227995784915872903807060280344573, 
    //         1329227995784915872903807060280344574, 
    //         1329227995784915872903807060280344573
    //     );
    // }

    function test_creatingOutcomeToken() public {
        address(new OutcomeToken());
        address(new OutcomeToken());
    }


    struct DeployParams {
        address creator;
        address oracle;
        bytes32 identifier;
    }
    DeployParams public deployParams;
    function test_market() public {
        deployParams = DeployParams({creator: address(this), oracle: oracle, identifier:0x0401030400040101040403020201030003000000010202020104010201000103});
        address marketAddress = address(new Market());
    }
}
