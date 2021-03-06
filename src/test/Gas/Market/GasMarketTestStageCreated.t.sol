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

contract GasMarketTestStageCreated is GasMarketTestShared {
    
    function setUp() override public {
        commonSetup();

        // different market for market creation tests
        deployParams = DeployParams({
            creator:address(this),
            oracle:oracle,
            identifier:"dawdiojdoaidm"
        });
    }

    function test_createMarket() external {
        new Market();
    }

    function test_transfer() external {
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        // Market(marketAddress).fund();
    }

    function test_fund() external {
        MemeToken(memeToken).transfer(marketAddress, 10*10**18);
        Market(marketAddress).fund();
    }

    function test_marketFactoryCreateMarket() external {
        // MarketRouter(marketRouter).createMarket(address(this), deployParams.oracle, deployParams.identifier, 10*10**18);
        MarketFactory(marketFactory).createMarket(address(this), deployParams.oracle, deployParams.identifier);
    }

    function test_marketRouterCreateMarketAndPlaceBet() external {
        MarketRouter(marketRouter).createAndPlaceBetOnMarket(address(this), deployParams.oracle, deployParams.identifier, 1*10**18, 1*10**18, 1);
    }

}   