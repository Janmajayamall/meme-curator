// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../libraries/Math.sol";
import "./../../OutcomeToken.sol";
import "./../../OracleMultiSig.sol";
import "./../../Market.sol";
contract GasMathTest is DSTest {

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
    DeployParams public deployParams;


    function setUp() public {
        address[] memory oracleOwners = new address[](1);
        oracleOwners[0] = address(this);
        oracle = address(new OracleMultiSig(oracleOwners, 1, 10));
        OracleConfig memory sharedOracleConfig = OracleConfig(
            address(this),
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
        deployParams = DeployParams({
            creator:address(this),
            oracle:oracle,
            identifier:0x0401030400040101040403020201030003000000010202020104010201000103
        });
    }

    function test_plusN() public {
        uint a =1329227995784915872903807060280344574;
        uint b =1329227995784915872903807060280344574;
        uint c = a+b;
    }
    function test_plusNOUTUUUUUUU() public {
        uint a =1329227995784915872903807060280344574;
        uint b =1329227995784915872903807060280344574;
        uint c;
        assembly {
            // if iszero(0){
            //     let b := mul(1329227995784915872903807060280344574,1329227995784915872903807060280344574)
            // }
            function safeMul(_a,_b) -> _v {
                    _v := add(_a,_b)
                    if or(lt(_v,_a), lt(_v,_b)) {revert(0,0)}
                }
            c := safeMul(a,b)
        }
    }

    function test_useless() public {
        uint a = (type(uint256).max/2)+2;
        uint b;
        assembly {
            b := mul(a,2)
        }
        emit log_named_uint("dad", b);
        assertEq(uint(0),uint(1));
    }

    function test_getAmountCToBuyTokens() public {
        uint a = Math.getAmountCToBuyTokens(
            1329227995784915872903807060280344575, 
            1093260665644886653583746608747661123, 
            1329227995784915872903807060280344575, 
            1329227995784915872903807060280344574
        );
    }

    function test_sqrt() external {
        Math.sqrt(type(uint256).max);
    }

    function test_getAmountCBySellTokens() public {
        uint a = Math.getAmountCBySellTokens(
            99929545749180196506802031401635932, 
            1329227995784915872903807060280344575, 
            1329227995784915872903807060280344574, 
            1111871825054533892096512879497761333
        );
    }

    function test_getTokenAmountToBuyWithAmountC() public {
        uint a0 = Math.getTokenAmountToBuyWithAmountC(
            0, 
            1, 
            551455025153312868521400950885683982, 
            1329227995784915872903807060280344575, 
            40698612001058230291149623598822520
        );
    }

    function test_getTokenAmountToSellForAmountC() public {         
        uint a0 = Math.getTokenAmountToSellForAmountC(
            0, 
            1, 
            1329227995784915872903807060280344573, 
            1329227995784915872903807060280344574, 
            1329227995784915872903807060280344573
        );
    }

    function test_creatingOutcomeToken() public {
        address(new OutcomeToken());
        address(new OutcomeToken());
    }


 
    function test_market() public {
        address marketAddress = address(new Market());
    }

    function test_empty() public {

    }

    function test_keccack() public {
        // bytes32 dad = keccak256(abi.encode(address(this), uint(12)));
        bytes32 dad1 = keccak256(abi.encodePacked(address(this), uint8(12)));
        // emit log_named_bytes("encode", dad);
        // emit log_named_bytes("encodePacked", dad1);
        // // log_named_bytes("encode", dad);
        // assertTrue(false);
    }
}
