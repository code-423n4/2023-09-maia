//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

contract ArbitrumBranchTest is DSTestPlus {
    receive() external payable {}

    uint32 nonce;

    MockERC20 avaxNativeAssethToken;

    MockERC20 avaxNativeToken;

    MockERC20 ftmNativeAssethToken;

    MockERC20 ftmNativeToken;

    ERC20hTokenRoot arbitrumNativeAssethToken;

    MockERC20 arbitrumNativeToken;

    MockERC20 rewardToken;

    ERC20hTokenRoot testToken;

    ERC20hTokenRootFactory hTokenFactory;

    RootPort rootPort;

    CoreRootRouter rootCoreRouter;

    MulticallRootRouter rootMulticallRouter;

    RootBridgeAgentFactory bridgeAgentFactory;

    RootBridgeAgent coreBridgeAgent;

    RootBridgeAgent multicallBridgeAgent;

    ArbitrumBranchPort localPortAddress;

    ArbitrumCoreBranchRouter arbitrumCoreRouter;

    BaseBranchRouter arbitrumMulticallRouter;

    ArbitrumBranchBridgeAgent arbitrumCoreBridgeAgent;

    ArbitrumBranchBridgeAgent arbitrumMulticallBridgeAgent;

    ERC20hTokenBranchFactory localHTokenFactory;

    ArbitrumBranchBridgeAgentFactory localBranchBridgeAgentFactory;

    uint16 rootChainId = uint16(42161);

    uint16 avaxChainId = uint16(1088);

    uint16 ftmChainId = uint16(2040);

    address avaxGlobalToken;

    address ftmGlobalToken;

    address wrappedNativeToken;

    address multicallAddress;

    address testGasPoolAddress = address(0xFFFF);

    address nonFungiblePositionManagerAddress = address(0xABAD);

    address avaxLocalWrappedNativeTokenAddress = address(0xBFFF);
    address avaxUnderlyingWrappedNativeTokenAddress = address(0xFFFB);

    address ftmLocalWrappedNativeTokenAddress = address(0xABBB);
    address ftmUnderlyingWrappedNativeTokenAddress = address(0xAAAB);

    address avaxCoreBridgeAgentAddress = address(0xBEEF);

    address avaxMulticallBridgeAgentAddress = address(0xEBFE);

    address avaxPortAddress = address(0xFEEB);

    address ftmCoreBridgeAgentAddress = address(0xCACA);

    address ftmMulticallBridgeAgentAddress = address(0xACAC);

    address ftmPortAddressM = address(0xABAC);

    address lzEndpointAddress = address(0xABFD);

    address owner = address(this);

    address dao = address(this);

    function setUp() public {
        /////////////////////////////////
        //      Deploy Root Utils      //
        /////////////////////////////////
        wrappedNativeToken = address(new WETH());

        multicallAddress = address(new Multicall2());

        /////////////////////////////////
        //    Deploy Root Contracts    //
        /////////////////////////////////
        rootPort = new RootPort(rootChainId);

        bridgeAgentFactory = new RootBridgeAgentFactory(
            rootChainId,
            lzEndpointAddress,
            address(rootPort)
        );

        rootCoreRouter = new CoreRootRouter(rootChainId, address(rootPort));

        rootMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        hTokenFactory = new ERC20hTokenRootFactory(rootChainId, address(rootPort));

        /////////////////////////////////
        //  Initialize Root Contracts  //
        /////////////////////////////////
        rootPort.initialize(address(bridgeAgentFactory), address(rootCoreRouter));

        hTokenFactory.initialize(address(rootCoreRouter));

        coreBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(rootCoreRouter)))
        );

        multicallBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(rootMulticallRouter)))
        );

        rootCoreRouter.initialize(address(coreBridgeAgent), address(hTokenFactory));

        rootMulticallRouter.initialize(address(multicallBridgeAgent));

        /////////////////////////////////
        // Deploy Local Branch Contracts//
        /////////////////////////////////

        localPortAddress = new ArbitrumBranchPort(rootChainId, address(rootPort), owner);

        arbitrumMulticallRouter = new BaseBranchRouter();

        arbitrumCoreRouter = new ArbitrumCoreBranchRouter();

        localBranchBridgeAgentFactory = new ArbitrumBranchBridgeAgentFactory(
            rootChainId,
            address(bridgeAgentFactory),
            address(arbitrumCoreRouter),
            address(localPortAddress),
            owner
        );

        localPortAddress.initialize(address(arbitrumCoreRouter), address(localBranchBridgeAgentFactory));

        hevm.startPrank(address(arbitrumCoreRouter));

        arbitrumCoreBridgeAgent = ArbitrumBranchBridgeAgent(
            payable(
                localBranchBridgeAgentFactory.createBridgeAgent(
                    address(arbitrumCoreRouter), address(coreBridgeAgent), address(bridgeAgentFactory)
                )
            )
        );

        arbitrumMulticallBridgeAgent = ArbitrumBranchBridgeAgent(
            payable(
                localBranchBridgeAgentFactory.createBridgeAgent(
                    address(arbitrumMulticallRouter), address(multicallBridgeAgent), address(bridgeAgentFactory)
                )
            )
        );

        hevm.stopPrank();

        arbitrumCoreRouter.initialize(address(arbitrumCoreBridgeAgent));
        arbitrumMulticallRouter.initialize(address(arbitrumMulticallBridgeAgent));

        ///////////////////////////////////
        //  Sync Root with new branches  //
        ///////////////////////////////////

        rootPort.initializeCore(address(coreBridgeAgent), address(arbitrumCoreBridgeAgent), address(localPortAddress));

        multicallBridgeAgent.approveBranchBridgeAgent(rootChainId);

        coreBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        coreBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        hevm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            address(arbitrumMulticallBridgeAgent), address(multicallBridgeAgent), rootChainId
        );

        hevm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            avaxCoreBridgeAgentAddress, address(coreBridgeAgent), avaxChainId
        );

        hevm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            avaxMulticallBridgeAgentAddress, address(multicallBridgeAgent), avaxChainId
        );

        hevm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            ftmCoreBridgeAgentAddress, address(coreBridgeAgent), ftmChainId
        );

        hevm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            ftmMulticallBridgeAgentAddress, address(multicallBridgeAgent), ftmChainId
        );

        // Add new chains

        RootPort(rootPort).addNewChain(
            avaxCoreBridgeAgentAddress,
            avaxChainId,
            "Avalanche",
            "AVAX",
            18,
            avaxLocalWrappedNativeTokenAddress,
            avaxUnderlyingWrappedNativeTokenAddress
        );

        RootPort(rootPort).addNewChain(
            ftmCoreBridgeAgentAddress,
            ftmChainId,
            "Fantom Opera",
            "FTM",
            18,
            ftmLocalWrappedNativeTokenAddress,
            ftmUnderlyingWrappedNativeTokenAddress
        );

        avaxGlobalToken = RootPort(rootPort).getGlobalTokenFromLocal(avaxLocalWrappedNativeTokenAddress, avaxChainId);

        ftmGlobalToken = RootPort(rootPort).getGlobalTokenFromLocal(ftmLocalWrappedNativeTokenAddress, ftmChainId);

        //Ensure there are gas tokens from each chain in the system.
        hevm.startPrank(address(rootPort));
        ERC20hTokenRoot(avaxGlobalToken).mint(address(rootPort), 1 ether, avaxChainId);
        ERC20hTokenRoot(ftmGlobalToken).mint(address(rootPort), 1 ether, ftmChainId);
        hevm.stopPrank();

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(avaxLocalWrappedNativeTokenAddress), avaxChainId)
                == avaxGlobalToken,
            "Token should be added"
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(avaxGlobalToken, avaxChainId)
                == address(avaxLocalWrappedNativeTokenAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(avaxLocalWrappedNativeTokenAddress), avaxChainId)
                == address(avaxUnderlyingWrappedNativeTokenAddress),
            "Token should be added"
        );

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(ftmLocalWrappedNativeTokenAddress), ftmChainId)
                == ftmGlobalToken,
            "Token should be added"
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(ftmGlobalToken, ftmChainId)
                == address(ftmLocalWrappedNativeTokenAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(ftmLocalWrappedNativeTokenAddress), ftmChainId)
                == address(ftmUnderlyingWrappedNativeTokenAddress),
            "Token should be added"
        );

        //////////////////////////////////////
        // Deploy Underlying Tokens and Mocks//
        //////////////////////////////////////

        rewardToken = new MockERC20("hermes token", "HERMES", 18);

        testToken = new ERC20hTokenRoot(
            rootChainId,
            address(bridgeAgentFactory),
            address(rootPort),
            "Hermes Global hToken 1",
            "hGT1",
            18
        );

        avaxNativeAssethToken = new MockERC20("hTOKEN-AVAX", "LOCAL hTOKEN FOR TOKEN IN AVAX", 18);
        avaxNativeToken = new MockERC20("underlying token", "UNDER", 18);

        ftmNativeAssethToken = new MockERC20("hTOKEN-FTM", "LOCAL hTOKEN FOR TOKEN IN FMT", 18);
        ftmNativeToken = new MockERC20("underlying token", "UNDER", 18);

        // arbitrumNativeAssethToken
        arbitrumNativeToken = new MockERC20("underlying token", "UNDER", 18);
    }

    struct OutputParams {
        address recipient;
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
    }

    struct OutputMultipleParams {
        address recipient;
        address[] outputTokens;
        uint256[] amountsOut;
        uint256[] depositsOut;
    }

    address public newAvaxAssetGlobalAddress;

    function testAddLocalToken() public {
        // Encode Data
        bytes memory data =
            abi.encode(address(avaxNativeToken), address(avaxNativeAssethToken), "UnderLocal Coin", "UL", uint8(18));

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x02), data);

        uint256 balanceBefore = MockERC20(wrappedNativeToken).balanceOf(address(coreBridgeAgent));

        // Call Deposit function
        GasParams memory gasParams = GasParams(1 ether, 0.5 ether);

        //Call Deposit function
        encodeSystemCall(
            payable(avaxCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            uint32(1),
            packedData,
            gasParams,
            avaxChainId
        );

        newAvaxAssetGlobalAddress =
            RootPort(rootPort).getGlobalTokenFromLocal(address(avaxNativeAssethToken), avaxChainId);

        console2.log("New: ", newAvaxAssetGlobalAddress);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(avaxNativeAssethToken), avaxChainId) != address(0),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, avaxChainId)
                == address(avaxNativeAssethToken),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(avaxNativeAssethToken), avaxChainId)
                == address(avaxNativeToken),
            "Token should be added"
        );

        console2.log("Balance Before: ", balanceBefore);
        console2.log("Balance After: ", address(coreBridgeAgent).balance);
    }

    address public newFtmAssetGlobalAddress;

    function testAddGlobalToken() public {
        // Add Local Token from Avax
        testAddLocalToken();

        //Gas Params
        GasParams memory _gasParams = GasParams(0.5 ether, 0.5 ether);

        //Gas Params
        GasParams[2] memory gasParams = [GasParams(0.5 ether, 0.5 ether), GasParams(0.5 ether, 0.5 ether)];

        //Encode Call Data
        bytes memory data = abi.encode(ftmCoreBridgeAgentAddress, newAvaxAssetGlobalAddress, ftmChainId, gasParams);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        // Call Deposit function
        encodeCallNoDeposit(
            payable(ftmCoreBridgeAgentAddress), payable(address(coreBridgeAgent)), packedData, _gasParams, ftmChainId
        );
        // State change occurs in setLocalToken
    }

    address public newAvaxAssetLocalToken = address(0xFAFA);

    function testSetLocalToken() public {
        // Add Local Token from Avax
        testAddGlobalToken();

        // Encode Data
        bytes memory data = abi.encode(newAvaxAssetGlobalAddress, newAvaxAssetLocalToken, "UnderLocal Coin", "UL");

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x03), data);

        //Gas Params
        GasParams memory _gasParams = GasParams(0.5 ether, 0.5 ether);

        //Call Deposit function
        encodeSystemCall(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            uint32(2),
            packedData,
            _gasParams,
            ftmChainId
        );

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(newAvaxAssetLocalToken, ftmChainId) == newAvaxAssetGlobalAddress,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId) == newAvaxAssetLocalToken,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newAvaxAssetLocalToken), ftmChainId) == address(0),
            "Token should not exist"
        );
    }

    address public mockApp = address(0xDAFA);

    address public newArbitrumAssetGlobalAddress;

    function testAddLocalTokenArbitrum() public {
        // Get some gas.
        hevm.deal(address(this), 1 ether);

        //Get gas params
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Add new localToken
        arbitrumCoreRouter.addLocalToken(address(arbitrumNativeToken), gasParams);

        uint256 balanceBefore = MockERC20(wrappedNativeToken).balanceOf(address(coreBridgeAgent));

        newArbitrumAssetGlobalAddress =
            RootPort(rootPort).getLocalTokenFromUnderlying(address(arbitrumNativeToken), rootChainId);

        console2.log("New: ", newArbitrumAssetGlobalAddress);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newArbitrumAssetGlobalAddress, rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(arbitrumNativeToken),
            "Token should be added"
        );

        console2.log("Balance Before: ", balanceBefore);
        console2.log("Balance After: ", address(coreBridgeAgent).balance);
    }

    function testAddLocalTokenArbitrumFailedIsGlobal() public {
        // Get some gas.
        hevm.deal(address(this), 1 ether);

        address prevAddress = RootPort(rootPort).getLocalTokenFromUnderlying(address(arbitrumNativeToken), rootChainId);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(arbitrumNativeToken), rootChainId)
                == address(prevAddress),
            "Token should be added"
        );

        //Gas Params
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        hevm.expectRevert(abi.encodeWithSignature("ExecutionFailure()"));

        //Add new localToken
        arbitrumCoreRouter.addLocalToken(ftmGlobalToken, gasParams);
    }

    function testAddBridgeAgentArbitrum() public {
        //Get some gas
        hevm.deal(address(this), 2 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(
            payable(RootBridgeAgentFactory(bridgeAgentFactory).createBridgeAgent(address(testMulticallRouter)))
        );

        //Initialize Router
        testMulticallRouter.initialize(address(testRootBridgeAgent));

        //Create Branch Router in FTM
        BaseBranchRouter arbTestRouter = new BaseBranchRouter();

        //Allow new branch from root
        testRootBridgeAgent.approveBranchBridgeAgent(rootChainId);

        //Create Branch Bridge Agent
        rootCoreRouter.addBranchToBridgeAgent{value: 2 ether}(
            address(testRootBridgeAgent),
            address(localBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            rootChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        console2.log("new branch bridge agent", localPortAddress.bridgeAgents(2));

        BranchBridgeAgent arbTestBranchBridgeAgent = BranchBridgeAgent(payable(localPortAddress.bridgeAgents(2)));

        arbTestRouter.initialize(address(arbTestBranchBridgeAgent));

        require(testRootBridgeAgent.getBranchBridgeAgent(rootChainId) == address(arbTestBranchBridgeAgent));
    }

    function testDepositToPort() public {
        // Set up
        testAddLocalTokenArbitrum();

        // Mint Tokens
        arbitrumNativeToken.mint(address(this), 100 ether);

        // Approve Tokens
        arbitrumNativeToken.approve(address(localPortAddress), 100 ether);

        // Call deposit to port
        arbitrumMulticallBridgeAgent.depositToPort(address(arbitrumNativeToken), 100 ether);

        // Test If Deposit was successful
        require(MockERC20(arbitrumNativeToken).balanceOf(address(this)) == 0, "User should have 0 tokens");
        require(
            MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress)) == 100 ether,
            "Port should have underlying tokens"
        );
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)) == 100 ether,
            "User should have 100 global tokens"
        );
    }

    function testDepositToPortUnrecognized() public {
        // Mint Tokens
        arbitrumNativeToken.mint(address(this), 100 ether);

        // Approve Tokens
        arbitrumNativeToken.approve(address(localPortAddress), 100 ether);

        // Call deposit to port
        hevm.expectRevert(abi.encodeWithSignature("UnknownGlobalToken()"));

        arbitrumMulticallBridgeAgent.depositToPort(address(arbitrumNativeToken), 100 ether);
    }

    function testWithdrawFromPort() public {
        // Deposit Tokens
        testDepositToPort();

        arbitrumMulticallBridgeAgent.withdrawFromPort(address(newArbitrumAssetGlobalAddress), 100 ether);

        // Test If Deposit was successful
        require(MockERC20(arbitrumNativeToken).balanceOf(address(this)) == 100 ether, "User should have 100 tokens");
        require(MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress)) == 0, "Port should have 0 tokens");
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)) == 0, "User should have 0 global tokens"
        );
    }

    function testWithdrawFromPortUnknownGlobal() public {
        // Deposit Tokens
        testDepositToPort();

        // Call withdraw from port
        hevm.expectRevert(abi.encodeWithSignature("UnknownGlobalToken()"));
        arbitrumMulticallBridgeAgent.withdrawFromPort(address(arbitrumNativeToken), 100 ether);
    }

    function testCallOutWithDeposit() public {
        // Set up
        testAddLocalTokenArbitrum();

        //Get gas
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newArbitrumAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Prepare call to transfer 100 hAVAX form virtual account to Mock App
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            // Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = rootChainId;

            // RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(address(this), 1 ether);

        // Mint Underlying Token.
        arbitrumNativeToken.mint(address(this), 100 ether);

        // Approve spend by router
        arbitrumNativeToken.approve(address(localPortAddress), 100 ether);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumNativeToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        arbitrumMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(address(this)), packedData, depositInput, gasParams, true
        );

        // Test If Deposit was successful
        testCreateDepositSingle(
            arbitrumMulticallBridgeAgent,
            uint32(1),
            address(this),
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumNativeToken),
            100 ether,
            100 ether,
            1 ether,
            0.5 ether
        );

        console2.log("LocalPort Balance:", MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress)));
        require(
            MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress)) == 50 ether,
            "LocalPort should have 50 tokens"
        );

        console2.log("User Balance:", MockERC20(arbitrumNativeToken).balanceOf(address(this)));
        require(MockERC20(arbitrumNativeToken).balanceOf(address(this)) == 50 ether, "User should have 50 tokens");

        console2.log("User Global Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)));
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)) == 49 ether,
            "User should have 50 global tokens"
        );
    }

    function testCallOutWithDepositExecutionFailed() public {
        // Set up
        testAddLocalTokenArbitrum();

        //Get gas
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newArbitrumAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Prepare call to transfer 100 hAVAX form virtual account to Mock App
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 100 ether)
            });

            // Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = rootChainId;

            // RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(address(this), 1 ether);

        // Mint Underlying Token.
        arbitrumNativeToken.mint(address(this), 100 ether);

        // Approve spend by router
        arbitrumNativeToken.approve(address(localPortAddress), 100 ether);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumNativeToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        hevm.expectRevert(abi.encodeWithSignature("ExecutionFailure()"));
        //Call Deposit function
        arbitrumMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(address(this)), packedData, depositInput, gasParams, true
        );
    }

    function testFuzzCallOutWithDeposit(
        address _user,
        uint256 _amount,
        uint256 _deposit,
        uint256 _amountOut,
        uint256 _depositOut
    ) public {
        _amount %= type(uint256).max / 1 ether;

        // Input restrictions
        hevm.assume(
            _user != address(0) && _amount > _deposit && _amount >= _amountOut && _amount - _amountOut >= _depositOut
                && _depositOut < _amountOut
        );

        // Set up
        testAddLocalTokenArbitrum();

        //Gas Params
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Prepare data
        bytes memory packedData;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            // Prepare call to transfer 100 hAVAX form virtual account to Mock App
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            // Output Params
            OutputParams memory outputParams =
                OutputParams(_user, newArbitrumAssetGlobalAddress, _amountOut, _depositOut);

            // RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, rootChainId);

            // Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        // Get some gas.
        hevm.deal(_user, 1 ether);

        if (_amount - _deposit > 0) {
            // Assure there is enough balance for mock action
            hevm.startPrank(address(rootPort));
            ERC20hTokenRoot(newArbitrumAssetGlobalAddress).mint(_user, _amount - _deposit, rootChainId);
            hevm.stopPrank();
            arbitrumNativeToken.mint(address(localPortAddress), _amount - _deposit);
        }

        // Mint Underlying Token.
        if (_deposit > 0) arbitrumNativeToken.mint(_user, _deposit);

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumNativeToken),
            amount: _amount,
            deposit: _deposit
        });

        console2.log("BALANCE BEFORE:");
        console2.log("arbitrumNativeToken Balance:", MockERC20(arbitrumNativeToken).balanceOf(_user));
        console2.log(
            "newArbitrumAssetGlobalAddress Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user)
        );

        // Mock token decimals call
        hevm.mockCall(address(arbitrumNativeToken), abi.encodeWithSignature("decimals()"), abi.encode(18));

        // Call Deposit function
        hevm.startPrank(_user);
        arbitrumNativeToken.approve(address(localPortAddress), _deposit);
        ERC20hTokenRoot(newArbitrumAssetGlobalAddress).approve(address(rootPort), _amount - _deposit);
        arbitrumMulticallBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(_user), packedData, depositInput, gasParams, true
        );
        hevm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(
            arbitrumMulticallBridgeAgent,
            uint32(1),
            _user,
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumNativeToken),
            _amount,
            _deposit,
            1 ether,
            0.5 ether
        );

        console2.log("Values");
        console2.log(_amount);
        console2.log(_deposit);
        console2.log(_amountOut);
        console2.log(_depositOut);

        address userAccount = address(RootPort(rootPort).getUserAccount(_user));

        console2.log("LocalPort Balance:", MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress)));
        console2.log("Expected:", _amount - _deposit + _deposit - _depositOut);
        require(
            MockERC20(arbitrumNativeToken).balanceOf(address(localPortAddress))
                == _amount - _deposit + _deposit - _depositOut,
            "LocalPort tokens"
        );

        console2.log("RootPort Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)));
        console2.log("Expected:0");
        require(MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)) == 0, "RootPort tokens");

        console2.log("User Balance:", MockERC20(arbitrumNativeToken).balanceOf(_user));
        console2.log("Expected:", _depositOut);
        require(MockERC20(arbitrumNativeToken).balanceOf(_user) == _depositOut, "User tokens");

        console2.log("User Global Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user));
        console2.log("Expected:", _amountOut - _depositOut);
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user) == _amountOut - _depositOut, "User Global tokens"
        );

        console2.log("User Account Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(userAccount));
        console2.log("Expected:", _amount - _amountOut);
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(userAccount) == _amount - _amountOut,
            "User Account tokens"
        );
    }

    function testCreateDepositSingle(
        ArbitrumBranchBridgeAgent _bridgeAgent,
        uint32 _depositNonce,
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit,
        uint128,
        uint128
    ) private view {
        // Cast to Dynamic TODO clean up
        address[] memory hTokens = new address[](1);
        hTokens[0] = _hToken;
        address[] memory tokens = new address[](1);
        tokens[0] = _token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        uint256[] memory deposits = new uint256[](1);
        deposits[0] = _deposit;

        // Get Deposit
        Deposit memory deposit = _bridgeAgent.getDepositEntry(_depositNonce);

        console2.logUint(1);
        console2.log(deposit.hTokens[0], hTokens[0]);
        console2.log(deposit.tokens[0], tokens[0]);

        // Check deposit
        require(deposit.owner == _user, "Deposit owner doesn't match");

        require(
            keccak256(abi.encodePacked(deposit.hTokens)) == keccak256(abi.encodePacked(hTokens)),
            "Deposit local hToken doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.tokens)) == keccak256(abi.encodePacked(tokens)),
            "Deposit underlying token doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.amounts)) == keccak256(abi.encodePacked(amounts)),
            "Deposit amount doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.deposits)) == keccak256(abi.encodePacked(deposits)),
            "Deposit deposit doesn't match"
        );

        require(deposit.status == 0, "Deposit status should be succesful.");
    }

    //////////////////////////////////////////////////////////////////////////   HELPERS   ////////////////////////////////////////////////////////////////////

    function encodeSystemCall(
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        uint32 _nonce,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        hevm.deal(lzEndpointAddress, _gasParams.gasLimit + _gasParams.remoteBranchExecutionGas);

        //Encode Data
        bytes memory inputCalldata = abi.encodePacked(bytes1(0x00), _nonce, _data);

        // Prank into user account
        hevm.startPrank(lzEndpointAddress);

        // Perform Call
        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");
        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        // Prank out of user account
        hevm.stopPrank();
    }

    function encodeCallNoDeposit(
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        hevm.deal(lzEndpointAddress, _gasParams.gasLimit + _gasParams.remoteBranchExecutionGas);
        //Encode Data
        bytes memory inputCalldata = abi.encodePacked(bytes1(0x01), nonce++, _data);

        // Prank into user account
        hevm.startPrank(lzEndpointAddress);

        // Perform Call
        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");
        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        // Prank out of user account
        hevm.stopPrank();
    }
}
