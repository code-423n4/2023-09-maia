//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/ImportHelper.sol";

contract CoreRootBridgeAgentTest is Test {
    uint32 nonce;

    MockERC20 wAvaxLocalhToken;

    MockERC20 wAvaxUnderlyingNativeToken;

    MockERC20 rewardToken;

    MockERC20 arbAssetToken;

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

    mapping(uint16 => uint32) public chainNonce;

    address avaxGlobalToken;

    address ftmGlobalToken;

    function setUp() public {
        // Deploy Root Utils
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

        vm.deal(address(rootPort), 1 ether);

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

        testToken = new ERC20hTokenRoot(
            rootChainId,
            address(bridgeAgentFactory),
            address(rootPort),
            "Hermes Global hToken 1",
            "hGT1",
            18
        );

        // Ensure there are gas tokens from each chain in the system.
        vm.startPrank(address(rootPort));
        ERC20hTokenRoot(avaxGlobalToken).mint(address(rootPort), 1 ether, avaxChainId); // hToken addresses created upon chain addition
        ERC20hTokenRoot(ftmGlobalToken).mint(address(rootPort), 1 ether, ftmChainId); // hToken addresses created upon chain addition
        vm.stopPrank();

        wAvaxLocalhToken = new MockERC20("hAVAX-AVAX", "LOCAL hTOKEN FOR AVAX IN AVAX", 18);

        wAvaxUnderlyingNativeToken = new MockERC20("underlying token", "UNDER", 18);

        rewardToken = new MockERC20("hermes token", "HERMES", 18);
        arbAssetToken = new MockERC20("A", "AAA", 18);
    }

    address public newGlobalAddress;

    function testAddLocalToken() public {
        //get some gas
        vm.deal(address(this), 1.5 ether);

        //Gas Params
        GasParams memory gasParams = GasParams(1 ether, 0.5 ether);

        //Encode Data
        bytes memory data = abi.encode(
            address(wAvaxUnderlyingNativeToken), address(wAvaxLocalhToken), "UnderLocal Coin", "UL", uint8(18)
        );

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x02), data);

        //Call Deposit function
        encodeSystemCall(
            payable(avaxCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[avaxChainId]++,
            packedData,
            gasParams,
            avaxChainId
        );

        newGlobalAddress = RootPort(rootPort).getGlobalTokenFromLocal(address(wAvaxLocalhToken), avaxChainId);

        console2.log("New: ", newGlobalAddress);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(wAvaxLocalhToken), avaxChainId) != address(0),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newGlobalAddress, avaxChainId) == address(wAvaxLocalhToken),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(wAvaxLocalhToken), avaxChainId)
                == address(wAvaxUnderlyingNativeToken),
            "Token should be added"
        );
    }

    function testAddLocalTokenAlreadyAdded() public {
        // Add once
        testAddLocalToken();

        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Encode Data
        bytes memory data = abi.encode(address(wAvaxUnderlyingNativeToken), address(9), "UnderLocal Coin", "UL");

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x02), data);

        // Call Deposit function
        encodeSystemCall(
            payable(avaxCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[avaxChainId]++,
            packedData,
            gasParams,
            avaxChainId
        );

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(wAvaxLocalhToken), avaxChainId) != address(0),
            "Token should not be changed"
        );
    }

    function testAddLocalTokenNotEnoughGas() public {
        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Encode Data
        bytes memory data =
            abi.encode(address(wAvaxUnderlyingNativeToken), address(wAvaxLocalhToken), "UnderLocal Coin", "UL");

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x02), data);

        // Expect revert
        vm.expectRevert();

        // Call Deposit function
        encodeSystemCall(
            payable(avaxCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[avaxChainId]++,
            packedData,
            gasParams,
            avaxChainId
        );
    }

    function testAddLocalTokenFromArbitrum() public {
        //Gas Params
        GasParams memory gasParams = GasParams(0, 0);

        //Perform Call
        arbitrumCoreRouter.addLocalToken(address(arbAssetToken), gasParams);

        //Get new address
        newGlobalAddress = RootPort(rootPort).getLocalTokenFromUnderlying(address(arbAssetToken), rootChainId);

        console2.log("New Global Token Address: ", newGlobalAddress);

        require(
            RootPort(rootPort).getGlobalTokenFromLocal(address(newGlobalAddress), rootChainId)
                == address(newGlobalAddress),
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newGlobalAddress, rootChainId) == address(newGlobalAddress),
            "Token should be added"
        );
        console2.log("NOWNOWNOWON");
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newGlobalAddress), rootChainId)
                == address(arbAssetToken),
            "Token should be added"
        );
    }

    function testAddGlobalToken() public {
        // Add Local Token from Avax
        testAddLocalToken();

        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Encode Call Data
        bytes memory data = abi.encode(ftmCoreBridgeAgentAddress, newGlobalAddress, ftmChainId, 0.0000025 ether);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        // Call Deposit function
        encodeCallNoDeposit(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[ftmChainId]++,
            packedData,
            gasParams,
            ftmChainId
        );
        // State change occurs in setLocalToken
    }

    function testAddGlobalTokenAlreadyAdded() public {
        // Add Local Token from Avax
        testAddGlobalToken();

        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Save current
        address currentAddress = RootPort(rootPort).getLocalTokenFromGlobal(address(newGlobalAddress), ftmChainId);

        // Encode Call Data
        bytes memory data = abi.encode(ftmCoreBridgeAgentAddress, newGlobalAddress, ftmChainId, 0.000025 ether);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        // Call Deposit function
        encodeCallNoDeposit(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[ftmChainId]++,
            packedData,
            gasParams,
            ftmChainId
        );

        require(
            RootPort(rootPort).getLocalTokenFromGlobal(address(newGlobalAddress), ftmChainId) == currentAddress,
            "Token should not be changed"
        );
    }

    function testAddGlobalTokenNotEnoughGas() public {
        // Add Local Token from Avax
        testAddLocalToken();

        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Encode Call Data
        bytes memory data = abi.encode(ftmCoreBridgeAgentAddress, newGlobalAddress, ftmChainId, 200);

        // Pack FuncId
        bytes memory packedData = abi.encodePacked(bytes1(0x01), data);

        // Call Deposit function
        encodeCallNoDeposit(
            payable(ftmCoreBridgeAgentAddress),
            payable(address(coreBridgeAgent)),
            chainNonce[ftmChainId]++,
            packedData,
            gasParams,
            ftmChainId
        );
    }

    address public newLocalToken = address(0xFAFA);

    function testSetLocalToken() public {
        // Add Local Token from Avax
        testAddGlobalToken();

        //Gas Params
        GasParams memory gasParams = GasParams(0.0001 ether, 0.00005 ether);

        //Encode Data
        bytes memory data = abi.encode(newGlobalAddress, newLocalToken, "UnderLocal Coin", "UL");

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
            RootPort(rootPort).getGlobalTokenFromLocal(newLocalToken, ftmChainId) == newGlobalAddress,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getLocalTokenFromGlobal(newGlobalAddress, ftmChainId) == newLocalToken,
            "Token should be added"
        );
        require(
            RootPort(rootPort).getUnderlyingTokenFromLocal(address(newLocalToken), ftmChainId) == address(0),
            "Token should be added"
        );
    }

    ////////////////////////////////////////////////// HELPERS /////////////////////////////////////////////////////////////////

    function encodeSystemCall(
        address payable _fromBridgeAgent,
        address payable _toBridgeAgent,
        uint32 _nonce,
        bytes memory _data,
        GasParams memory _gasParams,
        uint16 _srcChainIdId
    ) private {
        //Get some gas
        vm.deal(address(lzEndpointAddress), _gasParams.gasLimit + _gasParams.remoteBranchExecutionGas);

        //Encode Data
        bytes memory inputCalldata = abi.encodePacked(bytes1(0x00), _nonce, _data);

        // Prank into user account
        vm.startPrank(lzEndpointAddress);

        _toBridgeAgent.call{value: _gasParams.remoteBranchExecutionGas}("");
        RootBridgeAgent(_toBridgeAgent).lzReceive{gas: _gasParams.gasLimit}(
            _srcChainIdId, abi.encodePacked(_toBridgeAgent, _fromBridgeAgent), 1, inputCalldata
        );

        // Prank out of user account
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
        vm.deal(address(lzEndpointAddress), _gasParams.gasLimit + _gasParams.remoteBranchExecutionGas);
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
}
