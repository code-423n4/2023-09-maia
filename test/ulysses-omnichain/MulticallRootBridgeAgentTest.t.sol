//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

contract MulticallRootBridgeAgentTest is Test {
    uint32 nonce;

    MockERC20 avaxNativeAssethToken;

    MockERC20 avaxNativeToken;

    MockERC20 ftmNativeAssethToken;

    MockERC20 ftmNativeToken;

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

    address lzEndpointAddress = address(0xCAFE);

    address owner = address(this);

    address dao = address(this);

    address ftmGlobalToken;

    address avaxGlobalToken;

    mapping(uint256 => uint32) public chainNonce;

    address public newAvaxAssetGlobalAddress;

    function setUp() public {
        // Deploy Root Utils
        wrappedNativeToken = address(new WETH());

        multicallAddress = address(new Multicall2());

        // Deploy Root Contracts
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

        // Initialize Root Contracts
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

        // Deploy Local Branch Contracts
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

        vm.startPrank(address(arbitrumCoreRouter));

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
                    address(arbitrumMulticallRouter), address(rootMulticallRouter), address(bridgeAgentFactory)
                )
            )
        );

        vm.stopPrank();

        arbitrumCoreRouter.initialize(address(arbitrumCoreBridgeAgent));
        arbitrumMulticallRouter.initialize(address(arbitrumMulticallBridgeAgent));

        // Deploy Remote Branchs Contracts

        //////////////////////////////////

        // Sync Root with new branches

        rootPort.initializeCore(address(coreBridgeAgent), address(arbitrumCoreBridgeAgent), address(localPortAddress));

        coreBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        coreBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        multicallBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        vm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            avaxCoreBridgeAgentAddress, address(coreBridgeAgent), avaxChainId
        );

        vm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            avaxMulticallBridgeAgentAddress, address(multicallBridgeAgent), avaxChainId
        );

        vm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            ftmCoreBridgeAgentAddress, address(coreBridgeAgent), ftmChainId
        );

        vm.prank(address(rootCoreRouter));
        RootPort(rootPort).syncBranchBridgeAgentWithRoot(
            ftmMulticallBridgeAgentAddress, address(multicallBridgeAgent), ftmChainId
        );

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

        // Ensure there are gas tokens from each chain in the system.
        vm.startPrank(address(rootPort));
        ERC20hTokenRoot(avaxGlobalToken).mint(address(rootPort), 1 ether, avaxChainId);
        ERC20hTokenRoot(ftmGlobalToken).mint(address(rootPort), 1 ether, ftmChainId);
        vm.stopPrank();

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

        rewardToken = new MockERC20("hermes token", "HERMES", 18);
    }

    ////////////////////////////////////////////////////////////////////////// MULTICALL ////////////////////////////////////////////////////////////////////

    address public mockApp = address(0xDAFA);

    function testMulticallNoOutputNoDeposit() public {
        vm.mockCall(mockApp, abi.encodeWithSignature("distro()"), abi.encode(0));

        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        calls[0] =
            Multicall2.Call({target: mockApp, callData: abi.encodeWithSelector(bytes4(keccak256(bytes("distro()"))))});

        // RLP Encode Calldata
        bytes memory data = abi.encode(calls);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        //GasParams
        GasParams memory gasParams = GasParams(500_000, 0);

        vm.expectCall(mockApp, abi.encodeWithSignature("distro()"));

        //Call Deposit function
        encodeCallNoDeposit(
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId]++,
            packedData,
            gasParams,
            avaxChainId
        );

        checkNonceState(multicallBridgeAgent, chainNonce[avaxChainId] - 1, avaxChainId);
    }

    function testMulticallTwoTimesMessage() public {
        vm.mockCall(mockApp, abi.encodeWithSignature("distro()"), abi.encode(0));

        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        calls[0] =
            Multicall2.Call({target: mockApp, callData: abi.encodeWithSelector(bytes4(keccak256(bytes("distro()"))))});

        // RLP Encode Calldata
        bytes memory data = abi.encode(calls);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        //GasParams
        GasParams memory gasParams = GasParams(500_000, 0);

        vm.expectCall(mockApp, abi.encodeWithSignature("distro()"));

        //Call Deposit function
        encodeCallNoDeposit(
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId]++,
            packedData,
            gasParams,
            avaxChainId
        );

        vm.expectRevert(abi.encodeWithSignature("AlreadyExecutedTransaction()"));
        //Make previous call again
        encodeCallNoDeposit(
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId] - 1,
            packedData,
            gasParams,
            avaxChainId
        );
    }

    function testMulticallSignedNoOutputDepositSingle() public {
        // Add Local Token from Avax
        testSetLocalToken();

        //GasParams
        GasParams memory gasParams = GasParams(5_000_000, 0);

        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        // Prepare call to transfer 100 hAVAX form virtual account to Mock App (could be bribes)
        calls[0] = Multicall2.Call({
            target: avaxGlobalToken,
            callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 100 ether)
        });

        // RLP Encode Calldata
        bytes memory data = abi.encode(calls);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        encodeCallWithDepositSigned(
            address(this),
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId]++,
            address(avaxLocalWrappedNativeTokenAddress),
            address(avaxUnderlyingWrappedNativeTokenAddress),
            100 ether,
            100 ether,
            packedData,
            gasParams,
            avaxChainId
        );

        checkNonceState(multicallBridgeAgent, chainNonce[avaxChainId] - 1, avaxChainId);
    }

    function testMulticallMismatchTokens() public {
        // Add Local Token from Avax
        testSetLocalToken();

        //GasParams
        GasParams memory gasParams = GasParams(5_000_000, 0);

        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        // Prepare call to transfer 100 hAVAX form virtual account to Mock App (could be bribes)
        calls[0] = Multicall2.Call({
            target: avaxGlobalToken,
            callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 100 ether)
        });

        // RLP Encode Calldata
        bytes memory data = abi.encode(calls);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        vm.expectRevert(abi.encodeWithSignature("InvalidInputParams()"));
        encodeCallWithDepositSigned(
            address(this),
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId]++,
            address(avaxGlobalToken),
            address(avaxUnderlyingWrappedNativeTokenAddress),
            100 ether,
            100 ether,
            packedData,
            gasParams,
            avaxChainId
        );
    }

    function testMulticallSignedNoOutputDepositSingleNative() public {
        // Add Local Token from Avax
        testSetLocalToken();

        //GasParams
        GasParams memory gasParams = GasParams(5_000_000, 0);

        Multicall2.Call[] memory calls = new Multicall2.Call[](1);

        // Prepare call to transfer 100 hAVAX form virtual account to Mock App (could be bribes)
        calls[0] = Multicall2.Call({
            target: avaxGlobalToken,
            callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 100 ether)
        });

        // RLP Encode Calldata
        bytes memory data = abi.encode(calls);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        //Call Deposit function
        encodeCallWithDepositSigned(
            address(this),
            payable(avaxMulticallBridgeAgentAddress),
            payable(multicallBridgeAgent),
            chainNonce[avaxChainId]++,
            address(avaxLocalWrappedNativeTokenAddress),
            address(avaxUnderlyingWrappedNativeTokenAddress),
            100 ether,
            100 ether,
            packedData,
            gasParams,
            avaxChainId
        );

        checkNonceState(multicallBridgeAgent, chainNonce[avaxChainId] - 1, avaxChainId);
    }

    ////////////////////////////////////////////////////////////////////////// ADD TOKENS ////////////////////////////////////////////////////////////////////

    function testAddLocalToken() internal {
        // Encode Data
        bytes memory data =
            abi.encode(address(avaxNativeToken), address(avaxNativeAssethToken), "UnderLocal Coin", "UL");

        GasParams memory gasParams = GasParams(5_000_000, 0);

        //Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x02), data);

        uint32 _nonce = chainNonce[avaxChainId]++;

        //Call Deposit function
        encodeSystemCall(
            payable(avaxCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            _nonce,
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
    }

    address public newFtmAssetGlobalAddress;

    function testAddGlobalToken() internal {
        // Add Local Token from Avax
        testAddLocalToken();

        GasParams memory _gasParams = GasParams(5_000_000, 0.5 ether);

        GasParams[2] memory gasParams = [GasParams(5_000_000, 0.5 ether), GasParams(5_000_000, 0.5 ether)];

        //Encode Call Data
        bytes memory data = abi.encode(ftmCoreBridgeAgentAddress, newAvaxAssetGlobalAddress, ftmChainId, gasParams);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        // Call Deposit function
        encodeCallNoDeposit(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[ftmChainId]++,
            packedData,
            _gasParams,
            ftmChainId
        );
        // State change occurs in setLocalToken
    }

    address public newAvaxAssetLocalTokenInFtm = address(0xFAFA);

    function testSetLocalToken() internal {
        // Add Local Token from Avax
        testAddGlobalToken();

        GasParams memory gasParams = GasParams(5_000_000, 0);

        //Encode Data
        bytes memory data = abi.encode(newAvaxAssetGlobalAddress, newAvaxAssetLocalTokenInFtm, "UnderLocal Coin", "UL");

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x03), data);

        // Call Deposit function
        encodeSystemCall(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[ftmChainId]++,
            packedData,
            gasParams,
            ftmChainId
        );

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(newAvaxAssetLocalTokenInFtm, ftmChainId)
                == newAvaxAssetGlobalAddress,
            "Global should be matched with local"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId)
                == newAvaxAssetLocalTokenInFtm,
            "Local Token should be matched with global"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newAvaxAssetLocalTokenInFtm), ftmChainId)
                == address(0),
            "No underlying should be added"
        );

        console2.log("New: ", newAvaxAssetGlobalAddress);
    }

    ////////////////////////////////////////////////////////////////////////// HELPERS ////////////////////////////////////////////////////////////////////

    function encodeSystemCall(
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        uint32 _nonce,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        vm.deal(address(lzEndpointAddress), _gasParams.gasLimit * tx.gasprice + _gasParams.remoteBranchExecutionGas);

        //Encode Data
        bytes memory inputCalldata = abi.encodePacked(bytes1(0x00), _nonce, _data);

        uint256 depositExecutionStateBefore =
            RootBridgeAgent(_toBridgeAgent).executionState(_srcChainIdId, chainNonce[_srcChainIdId] - 1);

        require(depositExecutionStateBefore == 0, "Execution state should be 0");

        // Prank into user account
        vm.startPrank(lzEndpointAddress);

        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");
        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        vm.stopPrank();
    }

    function encodeCallNoDeposit(
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        uint32 _nonce,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        vm.deal(lzEndpointAddress, _gasParams.gasLimit * tx.gasprice + _gasParams.remoteBranchExecutionGas);
        //Encode Data
        bytes memory inputCalldata = abi.encodePacked(bytes1(0x01), _nonce, _data);

        // Prank into user account
        vm.startPrank(lzEndpointAddress);

        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");

        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        // Prank out of user account
        vm.stopPrank();
    }

    function encodeCallWithDepositSigned(
        address _user,
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        uint32 _nonce,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        vm.deal(lzEndpointAddress, _gasParams.gasLimit * tx.gasprice + _gasParams.remoteBranchExecutionGas);

        //Encode Data
        bytes memory inputCalldata =
            abi.encodePacked(bytes1(0x05), _user, _nonce, _hToken, _token, _amount, _deposit, _data);

        // Prank into user account
        vm.startPrank(lzEndpointAddress);

        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");
        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        // Prank out of user account
        vm.stopPrank();
    }

    function checkNonceState(RootBridgeAgent rootBridgeAgent, uint32 _nonce, uint16 _chainId) internal view {
        uint256 depositExecutionStateAfter = rootBridgeAgent.executionState(_chainId, _nonce);

        require(depositExecutionStateAfter == 1, "Execution state should be 1");
    }
}
