pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./../../../libraries/Math.sol";
import "./../../../OutcomeToken.sol";
import "./../../../MemeToken.sol";
import "./../../../OracleMultiSig.sol";
import "./../../../Market.sol";
import "./GasMarketTestShared.t.sol";
import "./../../../MarketRouter.sol";
import "./../../../MarketFactory.sol";

contract GasMarketTestStageFunded is GasMarketTestShared {

    address token0;
    address token1;
    
    function setUp() override public {
        commonSetup();

        (,token0, token1) = Market(marketAddress).getTokenAddresses();

        // fund market & transition to stage MarketFunded 
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();

        // buy some tokens for selling tests
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).buy(10*10**18, 10*10**18, address(this));

        // give max approval to marketRouter for outcome tokens
        OutcomeToken(token0).approve(marketRouter, type(uint256).max);
        OutcomeToken(token1).approve(marketRouter, type(uint256).max);
    }

    function test_buy() external {
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).buy(10*10**18, 10*10**18, address(this));
    }

    function test_sell() external {
        OutcomeToken(token0).transfer(marketAddress, 5*10**18);
        Market(marketAddress).sell(2*10**18, address(this));
    }

    function test_marketRouterBuyExactTokensForMaxCTokens() external {
        MarketRouter(marketRouter).buyExactTokensForMaxCTokens(10*10**18, 0, 10*10**18, marketAddress);
    }

    function test_marketRouterBuyMinTokensForExactCTokens() external {
        MarketRouter(marketRouter).buyMinTokensForExactCTokens(10*10**18, 0, 10*10**18, 1, marketAddress);
    }

    function test_marketRouterSellExactTokensForMinCTokens() external {
        MarketRouter(marketRouter).sellExactTokensForMinCTokens(5*10**18, 0, 2*10**18, marketAddress);
    }

    function test_marketRouterSellMaxTokensForExactCTokens() external {
        MarketRouter(marketRouter).sellMaxTokensForExactCTokens(5*10**18, 0, 2*10**18, 1, marketAddress);
    }
}    
