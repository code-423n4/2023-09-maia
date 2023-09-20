//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./helpers/RootForkHelper.t.sol";

pragma solidity ^0.8.0;

contract RootForkTest is LzForkTest {
    using MulticallRootRouterHelper for MulticallRootRouter;
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;
    using CoreRootRouterHelper for CoreRootRouter;
    using RootBridgeAgentFactoryHelper for RootBridgeAgentFactory;

    // Consts

    //Arb
    uint16 constant rootChainId = uint16(110);

    //Avax
    uint16 constant avaxChainId = uint16(106);

    //     //Ftm
    uint16 constant ftmChainId = uint16(112);

    //// System contracts

    // Root

    RootPort rootPort;

    ERC20hTokenRootFactory hTokenRootFactory;

    RootBridgeAgentFactory rootBridgeAgentFactory;

    RootBridgeAgent coreRootBridgeAgent;

    RootBridgeAgent multicallRootBridgeAgent;

    CoreRootRouter coreRootRouter;

    MulticallRootRouter rootMulticallRouter;

    // Arbitrum Branch

    ArbitrumBranchPort arbitrumPort;

    ArbitrumBranchBridgeAgentFactory arbitrumBranchBridgeAgentFactory;

    ArbitrumBranchBridgeAgent arbitrumCoreBranchBridgeAgent;

    ArbitrumBranchBridgeAgent arbitrumMulticallBranchBridgeAgent;

    ArbitrumCoreBranchRouter arbitrumCoreBranchRouter;

    BaseBranchRouter arbitrumMulticallRouter;

    // Avax Branch

    BranchPort avaxPort;

    ERC20hTokenBranchFactory avaxHTokenFactory;

    BranchBridgeAgentFactory avaxBranchBridgeAgentFactory;

    BranchBridgeAgent avaxCoreBridgeAgent;

    BranchBridgeAgent avaxMulticallBridgeAgent;

    CoreBranchRouter avaxCoreRouter;

    BaseBranchRouter avaxMulticallRouter;

    // Ftm Branch

    BranchPort ftmPort;

    ERC20hTokenBranchFactory ftmHTokenFactory;

    BranchBridgeAgentFactory ftmBranchBridgeAgentFactory;

    BranchBridgeAgent ftmCoreBridgeAgent;

    BranchBridgeAgent ftmMulticallBridgeAgent;

    CoreBranchRouter ftmCoreRouter;

    BaseBranchRouter ftmMulticallRouter;

    // ERC20s from different chains.

    address avaxMockAssethToken;

    MockERC20 avaxMockAssetToken;

    address ftmMockAssethToken;

    MockERC20 ftmMockAssetToken;

    ERC20hTokenRoot arbitrumMockAssethToken;

    MockERC20 arbitrumMockToken;

    // Mocks

    address arbitrumGlobalToken;
    address avaxGlobalToken;
    address ftmGlobalToken;

    address avaxWrappedNativeToken;
    address ftmWrappedNativeToken;

    address avaxLocalWrappedNativeToken;
    address ftmLocalWrappedNativeToken;

    address multicallAddress;

    address nonFungiblePositionManagerAddress = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address lzEndpointAddress = address(0x3c2269811836af69497E5F486A85D7316753cf62);
    address lzEndpointAddressAvax = address(0x3c2269811836af69497E5F486A85D7316753cf62);
    address lzEndpointAddressFtm = address(0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7);

    address owner = address(this);

    address dao = address(this);

    function setUp() public override {
        /////////////////////////////////
        //         Fork Setup          //
        /////////////////////////////////

        // Set up default fork chains
        console2.log("Adding Default Chains...");
        setUpDefaultLzChains();
        console2.log("Added Default Chains.");

        /////////////////////////////////
        //      Deploy Root Utils      //
        /////////////////////////////////
        console2.log("Deploying Root Contracts...");
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        multicallAddress = address(new Multicall2());

        /////////////////////////////////
        //    Deploy Root Contracts    //
        /////////////////////////////////

        _deployRoot();

        /////////////////////////////////
        //  Initialize Root Contracts  //
        /////////////////////////////////

        console2.log("Initializing Root Contracts...");

        _initRoot();

        /////////////////////////////////
        //Deploy Local Branch Contracts//
        /////////////////////////////////

        console2.log("Deploying Arbitrum Local Branch Contracts...");

        _deployLocalBranch();

        //////////////////////////////////
        // Deploy Avax Branch Contracts //
        //////////////////////////////////

        console2.log("Deploying Avalanche Branch Contracts...");

        _test_deployAvaxBranch();

        //////////////////////////////////
        // Deploy Ftm Branch Contracts //
        //////////////////////////////////

        console2.log("Deploying Fantom Contracts...");

        _test_deployFtmBranch();

        /////////////////////////////
        //  Add new branch chains  //
        /////////////////////////////

        console2.log("Adding new Branch Chains to Root...");

        _test_addNewBranchChainsToRoot();

        ///////////////////////////////////
        //  Approve new Branches in Root  //
        ///////////////////////////////////

        _test_approveNewBranchesInRoot();

        ///////////////////////////////////////
        //  Add new branches to  Root Agents //
        ///////////////////////////////////////

        _test_addNewBranchesToRootAgents();

        /////////////////////////////////////
        //  Initialize new Branch Routers  //
        /////////////////////////////////////

        _test_initNewBranchRouters();

        //////////////////////////////////////
        //Deploy Underlying Tokens and Mocks//
        //////////////////////////////////////

        _test_deployUnderlyingTokensAndMocks();
    }

    function _deployRoot() internal {
        (rootPort, rootBridgeAgentFactory, hTokenRootFactory, coreRootRouter, rootMulticallRouter) =
            RootForkHelper._deployRoot(rootChainId, lzEndpointAddress, multicallAddress);
    }

    function _initRoot() internal {
        (coreRootBridgeAgent, multicallRootBridgeAgent) = RootForkHelper._initRoot(
            rootPort, rootBridgeAgentFactory, hTokenRootFactory, coreRootRouter, rootMulticallRouter
        );
    }

    function _deployLocalBranch() internal {
        (
            arbitrumPort,
            arbitrumMulticallRouter,
            arbitrumCoreBranchRouter,
            arbitrumBranchBridgeAgentFactory,
            arbitrumCoreBranchBridgeAgent
        ) = RootForkHelper._deployLocalBranch(rootChainId, rootPort, owner, rootBridgeAgentFactory, coreRootBridgeAgent);
    }

    function _test_deployAvaxBranch() internal {
        _deployAvaxBranch();

        // TODO: Tests
    }

    function _test_deployFtmBranch() internal {
        _deployFtmBranch();

        // TODO: Tests
    }

    function _test_addNewBranchChainsToRoot() internal {
        _addNewBranchChainsToRoot();

        check_addNewBranchChainsToRoot();
    }

    function _test_approveNewBranchesInRoot() internal {
        _approveNewBranchesInRoot();

        // TODO: Tests
    }

    function _test_addNewBranchesToRootAgents() internal {
        _addNewBranchesToRootAgents();

        // TODO: Tests
    }

    function _test_initNewBranchRouters() internal {
        _initNewBranchRouters();

        // TODO: Tests
    }

    function _test_deployUnderlyingTokensAndMocks() internal {
        _deployUnderlyingTokensAndMocks();

        // TODO: Tests
    }

    function _deployAvaxBranch() internal {
        (
            avaxPort,
            avaxHTokenFactory,
            avaxCoreRouter,
            avaxWrappedNativeToken,
            avaxBranchBridgeAgentFactory,
            avaxMulticallRouter
        ) = _deployBranch(
            "Avalanche Ulysses ",
            "avax-u",
            rootChainId,
            avaxChainId,
            owner,
            rootBridgeAgentFactory,
            lzEndpointAddressAvax
        );

        (avaxCoreBridgeAgent, avaxLocalWrappedNativeToken) = _initBranch(
            coreRootBridgeAgent,
            avaxWrappedNativeToken,
            avaxPort,
            avaxHTokenFactory,
            avaxCoreRouter,
            avaxBranchBridgeAgentFactory
        );
    }

    function _deployFtmBranch() internal {
        (
            ftmPort,
            ftmHTokenFactory,
            ftmCoreRouter,
            ftmWrappedNativeToken,
            ftmBranchBridgeAgentFactory,
            ftmMulticallRouter
        ) = _deployBranch(
            "Fantom Ulysses ", "ftm-u", rootChainId, ftmChainId, owner, rootBridgeAgentFactory, lzEndpointAddressFtm
        );

        (ftmCoreBridgeAgent, ftmLocalWrappedNativeToken) = _initBranch(
            coreRootBridgeAgent,
            ftmWrappedNativeToken,
            ftmPort,
            ftmHTokenFactory,
            ftmCoreRouter,
            ftmBranchBridgeAgentFactory
        );
    }

    function _deployBranch(
        string memory _name,
        string memory _symbol,
        uint16 _rootChainId,
        uint16 _branchChainId,
        address _owner,
        RootBridgeAgentFactory _rootBridgeAgentFactory,
        address _lzEndpointAddressBranch
    )
        internal
        returns (
            BranchPort _branchPort,
            ERC20hTokenBranchFactory _branchHTokenFactory,
            CoreBranchRouter _branchCoreRouter,
            address _branchWrappedNativeToken,
            BranchBridgeAgentFactory _branchBridgeAgentFactory,
            BaseBranchRouter _branchMulticallRouter
        )
    {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(_branchChainId);

        _branchPort = new BranchPort(_owner);

        _branchHTokenFactory = new ERC20hTokenBranchFactory(_rootChainId, address(_branchPort), _name, _symbol);

        _branchCoreRouter = new CoreBranchRouter(address(_branchHTokenFactory));

        _branchWrappedNativeToken = address(new WETH());

        _branchBridgeAgentFactory = new BranchBridgeAgentFactory(
            _branchChainId,
            _rootChainId,
            address(_rootBridgeAgentFactory),
            _lzEndpointAddressBranch,
            address(_branchCoreRouter),
            address(_branchPort),
            _owner
        );

        _branchMulticallRouter = new BaseBranchRouter();
    }

    function _initBranch(
        RootBridgeAgent _coreRootBridgeAgent,
        address _branchWrappedNativeToken,
        BranchPort _branchPort,
        ERC20hTokenBranchFactory _branchHTokenFactory,
        CoreBranchRouter _branchCoreRouter,
        BranchBridgeAgentFactory _branchBridgeAgentFactory
    ) internal returns (BranchBridgeAgent _branchCoreBridgeAgent, address _branchLocalWrappedNativeToken) {
        _branchHTokenFactory.initialize(_branchWrappedNativeToken, address(_branchCoreRouter));
        _branchPort.initialize(address(_branchCoreRouter), address(_branchBridgeAgentFactory));

        _branchBridgeAgentFactory.initialize(address(_coreRootBridgeAgent));

        _branchCoreBridgeAgent = BranchBridgeAgent(payable(_branchPort.bridgeAgents(0)));
        console2.log(address(_branchCoreBridgeAgent));

        _branchCoreRouter.initialize(address(_branchCoreBridgeAgent));

        _branchLocalWrappedNativeToken = address(_branchHTokenFactory.hTokens(0));
    }

    function _addNewBranchChainsToRoot() internal {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        avaxGlobalToken = _addNewBranchChainToRoot(
            hTokenRootFactory,
            rootPort,
            avaxCoreBridgeAgent,
            avaxChainId,
            "Avalanche",
            "AVAX",
            18,
            avaxLocalWrappedNativeToken,
            avaxWrappedNativeToken
        );

        ftmGlobalToken = _addNewBranchChainToRoot(
            hTokenRootFactory,
            rootPort,
            ftmCoreBridgeAgent,
            ftmChainId,
            "Fantom Opera",
            "FTM",
            18,
            ftmLocalWrappedNativeToken,
            ftmWrappedNativeToken
        );
    }

    function _addNewBranchChainToRoot(
        ERC20hTokenRootFactory _hTokenRootFactory,
        RootPort _rootPort,
        BranchBridgeAgent _coreCranchBridgeAgent,
        uint16 _branchChainId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _branchLocalWrappedNativeToken,
        address _branchWrappedNativeToken
    ) internal returns (address branchGlobalToken) {
        uint256 hTokenIndex = _hTokenRootFactory.getHTokens().length;

        _rootPort.addNewChain(
            address(_coreCranchBridgeAgent),
            _branchChainId,
            _name,
            _symbol,
            _decimals,
            _branchLocalWrappedNativeToken,
            _branchWrappedNativeToken
        );

        branchGlobalToken = address(_hTokenRootFactory.hTokens(hTokenIndex));
    }

    function check_addNewBranchChainsToRoot() internal view {
        check_addNewLocalToken(
            rootPort, avaxChainId, avaxGlobalToken, avaxLocalWrappedNativeToken, avaxWrappedNativeToken
        );

        check_addNewLocalToken(rootPort, ftmChainId, ftmGlobalToken, ftmLocalWrappedNativeToken, ftmWrappedNativeToken);
    }

    function check_addNewLocalToken(
        RootPort _rootPort,
        uint16 _branchChainId,
        address _rootGlobalToken,
        address _branchLocalToken,
        address _branchUnderlyingToken
    ) internal view {
        require(_rootPort.isGlobalAddress(_rootGlobalToken), "Should be Global Token");

        require(
            _rootPort.getGlobalTokenFromLocal(_branchLocalToken, _branchChainId) == _rootGlobalToken,
            "Global Token should be connected to Local"
        );

        require(
            _rootPort.getLocalTokenFromGlobal(_rootGlobalToken, _branchChainId) == _branchLocalToken,
            "Local Token should be connected to Global"
        );
        require(
            _rootPort.getUnderlyingTokenFromLocal(_branchLocalToken, _branchChainId) == _branchUnderlyingToken,
            "Underlying Token should be connected to Local"
        );
    }

    function _approveNewBranchesInRoot() internal {
        rootPort.initializeCore(
            address(coreRootBridgeAgent), address(arbitrumCoreBranchBridgeAgent), address(arbitrumPort)
        );

        multicallRootBridgeAgent.approveBranchBridgeAgent(rootChainId);

        multicallRootBridgeAgent.approveBranchBridgeAgent(avaxChainId);

        multicallRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);
    }

    function _addNewBranchesToRootAgents() internal {
        // Start the recorder necessary for packet tracking
        console2.log("Initializing Fork Test Environment...");
        vm.recordLogs();

        console2.log("Adding new Branch Bridge Agents to Root Bridge Agents...");

        vm.deal(address(this), 100 ether);

        console2.log("Avax...");

        coreRootRouter.addBranchToBridgeAgent{value: 10 ether}(
            address(multicallRootBridgeAgent),
            address(avaxBranchBridgeAgentFactory),
            address(avaxMulticallRouter),
            address(this),
            avaxChainId,
            [GasParams(6_000_000, 10 ether), GasParams(1_000_000, 0)]
        );
        console2.log("Switching to AVAX...");
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        console2.log("DONE AVAX!");
        console2.log("Switching back to ROOT...");
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        console2.log("DONE ROOT!");

        vm.deal(address(this), 100 ether);

        coreRootRouter.addBranchToBridgeAgent{value: 10 ether}(
            address(multicallRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(ftmMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        console2.log("GOING FTM");
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        console2.log("DONE FTM");
        console2.log("GOING ROOT");
        this.switchToLzChain{gas: 1 ether}(rootChainId);
        console2.log("DONE ROOT");

        coreRootRouter.addBranchToBridgeAgent(
            address(multicallRootBridgeAgent),
            address(arbitrumBranchBridgeAgentFactory),
            address(arbitrumMulticallRouter),
            address(this),
            rootChainId,
            [GasParams(0, 0), GasParams(0, 0)]
        );
    }

    function _initNewBranchRouters() internal {
        console2.log("Initializing new Branch Routers...");

        arbitrumMulticallBranchBridgeAgent = ArbitrumBranchBridgeAgent(payable(arbitrumPort.bridgeAgents(1)));
        arbitrumMulticallRouter.initialize(address(arbitrumMulticallBranchBridgeAgent));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        avaxMulticallBridgeAgent = BranchBridgeAgent(payable(avaxPort.bridgeAgents(1)));
        avaxMulticallRouter.initialize(address(avaxMulticallBridgeAgent));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        ftmMulticallBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(1)));
        ftmMulticallRouter.initialize(address(ftmMulticallBridgeAgent));
    }

    function _deployUnderlyingTokensAndMocks() internal {
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);
        // avaxMockAssethToken = new MockERC20("hTOKEN-AVAX", "LOCAL hTOKEN FOR TOKEN IN AVAX", 18);
        avaxMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        // ftmMockAssethToken = new MockERC20("hTOKEN-FTM", "LOCAL hTOKEN FOR TOKEN IN FMT", 18);
        ftmMockAssetToken = new MockERC20("underlying token", "UNDER", 18);

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        //arbitrumMockAssethToken is global
        arbitrumMockToken = new MockERC20("underlying token", "UNDER", 18);
    }

    fallback() external payable {}

    receive() external payable {}

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

    //////////////////////////////////////
    //           Bridge Agents          //
    //////////////////////////////////////

    function testAddBridgeAgentSimple() public {
        //Get some gas
        vm.deal(address(this), 2 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Create Branch Router in FTM
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        BaseBranchRouter ftmTestRouter = new BaseBranchRouter();
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        //Allow new branch from root
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 2 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        console2.log("new branch bridge agent", ftmPort.bridgeAgents(2));

        BranchBridgeAgent ftmTestBranchBridgeAgent = BranchBridgeAgent(payable(ftmPort.bridgeAgents(2)));

        ftmTestRouter.initialize(address(ftmTestBranchBridgeAgent));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(testRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == address(ftmTestBranchBridgeAgent));
    }

    function testAddBridgeAgentArbitrum() public {
        //Get some gas
        vm.deal(address(this), 2 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Create Branch Router in FTM
        BaseBranchRouter arbTestRouter = new BaseBranchRouter();

        //Allow new branch from root
        testRootBridgeAgent.approveBranchBridgeAgent(rootChainId);

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 2 ether}(
            address(testRootBridgeAgent),
            address(arbitrumBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            rootChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        console2.log("new branch bridge agent", arbitrumPort.bridgeAgents(2));

        BranchBridgeAgent arbTestBranchBridgeAgent = BranchBridgeAgent(payable(arbitrumPort.bridgeAgents(2)));

        arbTestRouter.initialize(address(arbTestBranchBridgeAgent));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(testRootBridgeAgent.getBranchBridgeAgent(rootChainId) == address(arbTestBranchBridgeAgent));
    }

    function testAddBridgeAgentAlreadyAdded() public {
        testAddBridgeAgentSimple();

        //Get some gas
        vm.deal(address(this), 1 ether);

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        vm.expectRevert(abi.encodeWithSignature("AlreadyAddedBridgeAgent()"));

        //Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);
    }

    function testAddBridgeAgentTwoTimes() public {
        testAddBridgeAgentSimple();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter = new MulticallRootRouter(
            rootChainId,
            address(rootPort),
            multicallAddress
        );

        RootBridgeAgent testRootBridgeAgent = RootBridgeAgent(payable(rootPort.bridgeAgents(2)));

        vm.expectRevert(abi.encodeWithSignature("InvalidChainId()"));

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    function testAddBridgeAgentNotApproved() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        vm.expectRevert(abi.encodeWithSignature("UnauthorizedChainId()"));

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    function testAddBridgeAgentNotManager() public {
        //Get some gas
        vm.deal(address(89), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        vm.startPrank(address(89));

        vm.expectRevert(abi.encodeWithSignature("UnauthorizedCallerNotManager()"));
        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(ftmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(0.05 ether, 0.05 ether), GasParams(0.02 ether, 0)]
        );
    }

    address newFtmBranchBridgeAgent;

    function testAddBridgeAgentNewFactory() public {
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            newRootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 1 ether}(
            address(testRootBridgeAgent),
            address(newFtmBranchBridgeAgentFactory),
            address(testMulticallRouter),
            address(this),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        newFtmBranchBridgeAgent = ftmPort.bridgeAgents(2);

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            testRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == newFtmBranchBridgeAgent,
            "Branch Bridge Agent should be created"
        );
    }

    function testAddBridgeAgentWrongBranchFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 0.05 ether}(
            address(testRootBridgeAgent),
            address(32),
            address(testMulticallRouter),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    function testAddBridgeAgentWrongRootFactory() public {
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        //Create Root Bridge Agent
        MulticallRootRouter testMulticallRouter;
        testMulticallRouter = testMulticallRouter._deploy(rootChainId, rootPort, multicallAddress);

        // Create Bridge Agent
        RootBridgeAgent testRootBridgeAgent =
            rootBridgeAgentFactory._createRootBridgeAgent(address(testMulticallRouter));

        //Initialize Router
        testMulticallRouter._init(testRootBridgeAgent);

        //Allow new branch
        testRootBridgeAgent.approveBranchBridgeAgent(ftmChainId);

        // Get wrong factory
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        address branchBridgeAgentFactory = address(ftmPort.bridgeAgentFactories(1));
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        //Create Branch Bridge Agent
        coreRootRouter.addBranchToBridgeAgent{value: 1 ether}(
            address(testRootBridgeAgent),
            branchBridgeAgentFactory,
            address(testMulticallRouter),
            address(ftmCoreRouter),
            ftmChainId,
            [GasParams(6_000_000, 15 ether), GasParams(1_000_000, 0)]
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        require(
            RootBridgeAgent(testRootBridgeAgent).getBranchBridgeAgent(ftmChainId) == address(0),
            "Branch Bridge Agent should not be created"
        );
    }

    function testRemoveBridgeAgent() public {
        vm.deal(address(this), 1 ether);

        coreRootRouter.removeBranchBridgeAgent{value: 1 ether}(
            address(ftmMulticallBridgeAgent), address(this), ftmChainId, GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isBridgeAgent(address(ftmMulticallBridgeAgent)), "Should be disabled");
    }

    CoreRootRouter newCoreRootRouter;
    RootBridgeAgent newCoreRootBridgeAgent;
    ERC20hTokenRootFactory newHTokenRootFactory;

    CoreBranchRouter newFtmCoreBranchRouter;
    BranchBridgeAgent newFtmCoreBranchBridgeAgent;
    ERC20hTokenBranchFactory newFtmHTokenFactory;

    function testSetBranchRouter() public {
        testRemoveBridgeAgent();

        switchToLzChain(rootChainId);

        vm.deal(address(this), 1000 ether);

        // Deploy new root core

        newHTokenRootFactory = new ERC20hTokenRootFactory(rootChainId, address(rootPort));

        newCoreRootRouter = new CoreRootRouter(rootChainId, address(rootPort));

        newCoreRootBridgeAgent =
            RootBridgeAgent(payable(rootBridgeAgentFactory.createBridgeAgent(address(newCoreRootRouter))));

        // Init new root core

        newCoreRootRouter.initialize(address(newCoreRootBridgeAgent), address(newHTokenRootFactory));

        newHTokenRootFactory.initialize(address(newCoreRootRouter));

        switchToLzChain(ftmChainId);

        // Deploy new Branch Core

        newFtmHTokenFactory = new ERC20hTokenBranchFactory(rootChainId, address(ftmPort), "Fantom", "FTM");

        newFtmCoreBranchRouter = new CoreBranchRouter(address(newFtmHTokenFactory));

        newFtmCoreBranchBridgeAgent = new BranchBridgeAgent(rootChainId,
        ftmChainId,
        address(newCoreRootBridgeAgent),
        lzEndpointAddressFtm,
        address(newFtmCoreBranchRouter),
        address(ftmPort));

        // Init new branch core

        newFtmCoreBranchRouter.initialize(address(newFtmCoreBranchBridgeAgent));

        newFtmHTokenFactory.initialize(address(ftmWrappedNativeToken), address(newFtmCoreBranchRouter));

        switchToLzChain(rootChainId);

        rootPort.setCoreBranchRouter{value: 1000 ether}(
            address(this),
            address(newFtmCoreBranchRouter),
            address(newFtmCoreBranchBridgeAgent),
            ftmChainId,
            GasParams(200_000, 0)
        );

        switchToLzChain(ftmChainId);

        require(ftmPort.coreBranchRouterAddress() == address(newFtmCoreBranchRouter));
        require(ftmPort.isBridgeAgent(address(newFtmCoreBranchBridgeAgent)));

        ftmCoreRouter = newFtmCoreBranchRouter;
        ftmCoreBridgeAgent = newFtmCoreBranchBridgeAgent;
    }

    function testSetCoreRootRouter() public {
        testSetBranchRouter();

        // @dev Once all branches have been migrated we are ready to set the new root router

        switchToLzChain(rootChainId);

        // newCoreRootRouter = new CoreRootRouter(rootChainId, address(rootPort));

        // newCoreRootBridgeAgent =
        //     RootBridgeAgent(payable(rootBridgeAgentFactory.createBridgeAgent(address(newCoreRootRouter))));

        rootPort.setCoreRootRouter(address(newCoreRootRouter), address(newCoreRootBridgeAgent));

        require(rootPort.coreRootRouterAddress() == address(newCoreRootRouter));
        require(rootPort.coreRootBridgeAgentAddress() == address(newCoreRootBridgeAgent));

        coreRootRouter = newCoreRootRouter;
        coreRootBridgeAgent = newCoreRootBridgeAgent;
    }

    function testSyncNewCoreBranchRouter() public {
        testSetCoreRootRouter();

        // @dev after setting the new root core we can sync each new branch one by one

        rootPort.syncNewCoreBranchRouter(
            address(newFtmCoreBranchRouter), address(newFtmCoreBranchBridgeAgent), ftmChainId
        );

        require(newCoreRootBridgeAgent.getBranchBridgeAgent(ftmChainId) == address(newFtmCoreBranchBridgeAgent));
    }

    MockERC20 newFtmMockUnderlyingToken;
    address newFtmMockAssetLocalToken;
    address newFtmMockGlobalToken;

    function testAddLocalTokenNewCore() public {
        testSyncNewCoreBranchRouter();

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        vm.deal(address(this), 10 ether);

        newFtmMockUnderlyingToken = new MockERC20("UnderTester", "UTST", 6);

        ftmCoreRouter.addLocalToken{value: 10 ether}(address(newFtmMockUnderlyingToken), GasParams(2_000_000, 0));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        newFtmMockAssetLocalToken = rootPort.getLocalTokenFromUnderlying(address(newFtmMockUnderlyingToken), ftmChainId);

        newFtmMockGlobalToken = rootPort.getGlobalTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId);

        console2.log("New Global: ", newFtmMockGlobalToken);
        console2.log("New Local: ", newFtmMockAssetLocalToken);

        require(
            rootPort.getGlobalTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId) == newFtmMockGlobalToken,
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newFtmMockGlobalToken, ftmChainId) == newFtmMockAssetLocalToken,
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(newFtmMockAssetLocalToken, ftmChainId)
                == address(newFtmMockUnderlyingToken),
            "Token should be added"
        );
    }

    //////////////////////////////////////
    //        Bridge Agent Factory     //
    //////////////////////////////////////

    RootBridgeAgentFactory newRootBridgeAgentFactory;

    BranchBridgeAgentFactory newFtmBranchBridgeAgentFactory;

    function testAddBridgeAgentFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory = newRootBridgeAgentFactory._deploy(rootChainId, lzEndpointAddress, rootPort);

        // Enable new Factory in Root
        rootPort.addBridgeAgentFactory(address(newRootBridgeAgentFactory));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        // Enable new Factory in Branch
        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Factory not enabled");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testAddBridgeAgentFactoryNotRootFactory() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory = newRootBridgeAgentFactory._deploy(rootChainId, lzEndpointAddress, rootPort);

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        vm.expectRevert(abi.encodeWithSignature("UnrecognizedBridgeAgentFactory()"));

        // Add new Factory to Branch
        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory),
            address(newFtmBranchBridgeAgentFactory),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );
    }

    RootBridgeAgentFactory newRootBridgeAgentFactory_2;

    BranchBridgeAgentFactory newFtmBranchBridgeAgentFactory_2;

    function testAddTwoBridgeAgentFactories() public {
        // Add first factory
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        // Add new Root Bridge Agent Factory
        newRootBridgeAgentFactory_2 = newRootBridgeAgentFactory_2._deploy(rootChainId, lzEndpointAddress, rootPort);

        // Enable new Factory in Root
        rootPort.addBridgeAgentFactory(address(newRootBridgeAgentFactory_2));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        // Add new Branch Bridge Agent Factory
        newFtmBranchBridgeAgentFactory_2 = new BranchBridgeAgentFactory(
            ftmChainId,
            rootChainId,
            address(newRootBridgeAgentFactory_2),
            lzEndpointAddressFtm,
            address(ftmCoreRouter),
            address(ftmPort),
            owner
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(newRootBridgeAgentFactory_2),
            address(newFtmBranchBridgeAgentFactory_2),
            address(this),
            ftmChainId,
            GasParams(200_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory)), "Factory not enabled");
        require(ftmPort.isBridgeAgentFactory(address(newFtmBranchBridgeAgentFactory_2)), "Factory not enabled");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testRemoveBridgeAgentFactory() public {
        //Add Factory
        testAddBridgeAgentFactory();

        //Get some gas
        vm.deal(address(this), 1 ether);

        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        address factoryToRemove = address(ftmPort.bridgeAgentFactories(1));
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        coreRootRouter.toggleBranchBridgeAgentFactory{value: 1 ether}(
            address(rootBridgeAgentFactory), factoryToRemove, address(this), ftmChainId, GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isBridgeAgentFactory(ftmPort.bridgeAgentFactories(1)), "Should be disabled");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    //////////////////////////////////////
    //           Port Strategies        //
    //////////////////////////////////////
    MockERC20 mockFtmPortToken;

    function testAddStrategyToken() public {
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        mockFtmPortToken = new MockERC20("Token of the Port", "PORT TKN", 18);
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        //Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.manageStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 7000, address(this), ftmChainId, GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should be added");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testAddStrategyTokenInvalidMinReserve() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        // vm.expectRevert(abi.encodeWithSignature("InvalidMinimumReservesRatio()"));
        coreRootRouter.manageStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 300, address(this), ftmChainId, GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should note be added");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testRemoveStrategyToken() public {
        //Add Token
        testAddStrategyToken();

        //Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.manageStrategyToken{value: 1 ether}(
            address(mockFtmPortToken), 0, address(this), ftmChainId, GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isStrategyToken(address(mockFtmPortToken)), "Should be removed");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    address mockFtmPortStrategyAddress;

    function testAddPortStrategy() public {
        // Add strategy token
        testAddStrategyToken();

        // Deploy Mock Strategy
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);
        mockFtmPortStrategyAddress = address(new MockPortStartegy());
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);

        // Get some gas
        vm.deal(address(this), 1 ether);

        coreRootRouter.managePortStrategy{value: 1 ether}(
            mockFtmPortStrategyAddress,
            address(mockFtmPortToken),
            250 ether,
            false,
            address(this),
            ftmChainId,
            GasParams(300_000, 0)
        );

        // Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(ftmPort.isPortStrategy(mockFtmPortStrategyAddress, address(mockFtmPortToken)), "Should be added");

        // Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testAddPortStrategyNotToken() public {
        //Get some gas
        vm.deal(address(this), 1 ether);

        //UnrecognizedStrategyToken();
        coreRootRouter.managePortStrategy{value: 1 ether}(
            mockFtmPortStrategyAddress,
            address(mockFtmPortToken),
            300,
            false,
            address(this),
            ftmChainId,
            GasParams(300_000, 0)
        );

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);

        require(!ftmPort.isPortStrategy(mockFtmPortStrategyAddress, address(mockFtmPortToken)), "Should not be added");

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
    }

    function testManage() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        //Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore - 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore + 250 ether,
            "Should be transfered"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod out"
        );
    }

    function testManageTwoDayLimits() public {
        // Add Strategy token and Port strategy
        testManage();

        //Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Warp 1 day
        vm.warp(block.timestamp + 1 days);

        // Add token balance to port (new deposits)
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore - 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore + 250 ether,
            "Should be transfered"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 500 ether,
            "Should be 500 ether"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should be 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod out"
        );
    }

    function testManageExceedsMinimumReserves() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        //Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Prank into strategy
        vm.startPrank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert(abi.encodeWithSignature("InsufficientReserves()"));

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 400 ether);
    }

    function testManageExceedsDailyLimit() public {
        // Add Strategy token and Port strategy
        testAddPortStrategy();

        //Switch Chain and Execute Incoming Packets
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Add token balance to port
        mockFtmPortToken.mint(address(ftmPort), 1000 ether);

        // Prank into strategy
        vm.startPrank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert();

        // Request management of assets
        ftmPort.manage(address(mockFtmPortToken), 300 ether);
    }

    function testReplenishAsStrategy() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.replenishReserves(address(mockFtmPortToken), 250 ether);

        // Veriy if assets have been transfered
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore + 250 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore - 250 ether,
            "Should be returned"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should remain 250 ether"
        );

        require(
            ftmPort.strategyDailyLimitRemaining(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 0,
            "Should be zerod"
        );
    }

    function testReplenishAsUser() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Fake some port withdrawals
        // vm.prank(address(ftmPort));
        MockERC20(mockFtmPortToken).burn(address(ftmPort), 500 ether);

        // Get port balance before manage
        uint256 portBalanceBefore = mockFtmPortToken.balanceOf(address(ftmPort));

        // Get Strategy balance before manage
        uint256 strategyBalanceBefore = mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress);

        // Request management of assets
        ftmPort.replenishReserves(mockFtmPortStrategyAddress, address(mockFtmPortToken));

        // Veriy if assets have been transfered up to the minimum reserves
        require(mockFtmPortToken.balanceOf(address(ftmPort)) == portBalanceBefore + 100 ether, "Should be transfered");

        require(
            mockFtmPortToken.balanceOf(mockFtmPortStrategyAddress) == strategyBalanceBefore - 100 ether,
            "Should be returned"
        );

        require(
            ftmPort.getPortStrategyTokenDebt(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 150 ether,
            "Should be decremented"
        );

        require(
            ftmPort.strategyDailyLimitAmount(mockFtmPortStrategyAddress, address(mockFtmPortToken)) == 250 ether,
            "Should remain 250 ether"
        );
    }

    function testReplenishAsStrategyNotEnoughDebtToRepay() public {
        // Add Strategy token and Port strategy
        testManage();

        // Switch to brnach
        switchToLzChainWithoutExecutePendingOrPacketUpdate(ftmChainId);

        // Prank into strategy
        vm.prank(mockFtmPortStrategyAddress);

        // Expect revert
        vm.expectRevert();

        // Request management of assets
        ftmPort.replenishReserves(address(mockFtmPortToken), 300 ether);
    }

    //////////////////////////////////////
    //          TOKEN MANAGEMENT        //
    //////////////////////////////////////

    address public newAvaxAssetGlobalAddress;

    function testAddLocalToken() public {
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        vm.deal(address(this), 10 ether);

        avaxCoreRouter.addLocalToken{value: 10 ether}(address(avaxMockAssetToken), GasParams(2_000_000, 0));

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        avaxMockAssethToken = rootPort.getLocalTokenFromUnderlying(address(avaxMockAssetToken), avaxChainId);

        newAvaxAssetGlobalAddress = rootPort.getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId);

        console2.log("New Global: ", newAvaxAssetGlobalAddress);
        console2.log("New Local: ", avaxMockAssethToken);

        require(
            rootPort.getGlobalTokenFromLocal(avaxMockAssethToken, avaxChainId) == newAvaxAssetGlobalAddress,
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, avaxChainId) == avaxMockAssethToken,
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(avaxMockAssethToken, avaxChainId) == address(avaxMockAssetToken),
            "Token should be added"
        );
    }

    address public newFtmAssetGlobalAddress;

    address public newAvaxAssetFtmLocalToken;

    function testAddGlobalTokenFork() public {
        //Add Local Token from Avax
        testAddLocalToken();

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(avaxChainId);

        vm.deal(address(this), 1000 ether);

        GasParams[3] memory gasParams =
            [GasParams(15_000_000, 0.1 ether), GasParams(2_000_000, 3 ether), GasParams(200_000, 0)];

        avaxCoreRouter.addGlobalToken{value: 1000 ether}(newAvaxAssetGlobalAddress, ftmChainId, gasParams);

        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(ftmChainId);
        //Switch Chain and Execute Incoming Packets
        switchToLzChain(rootChainId);

        newAvaxAssetFtmLocalToken = rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId);

        require(newAvaxAssetFtmLocalToken != address(0), "Failed is zero");

        console2.log("New Local: ", newAvaxAssetFtmLocalToken);

        require(
            rootPort.getLocalTokenFromGlobal(newAvaxAssetGlobalAddress, ftmChainId) == newAvaxAssetFtmLocalToken,
            "Token should be added"
        );

        require(
            rootPort.getUnderlyingTokenFromLocal(newAvaxAssetFtmLocalToken, ftmChainId) == address(0),
            "Underlying should not be added"
        );
    }

    address public mockApp = address(0xDAFA);

    address public newArbitrumAssetGlobalAddress;

    function testAddLocalTokenArbitrum() public {
        //Set up
        testAddGlobalTokenFork();

        //Get some gas.
        vm.deal(address(this), 1 ether);

        //Add new localToken
        arbitrumCoreBranchRouter.addLocalToken{value: 0.0005 ether}(
            address(arbitrumMockToken), GasParams(0.5 ether, 0.5 ether)
        );

        newArbitrumAssetGlobalAddress = rootPort.getLocalTokenFromUnderlying(address(arbitrumMockToken), rootChainId);

        console2.log("New: ", newArbitrumAssetGlobalAddress);

        require(
            rootPort.getGlobalTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            rootPort.getLocalTokenFromGlobal(newArbitrumAssetGlobalAddress, rootChainId)
                == address(newArbitrumAssetGlobalAddress),
            "Token should be added"
        );
        require(
            rootPort.getUnderlyingTokenFromLocal(address(newArbitrumAssetGlobalAddress), rootChainId)
                == address(arbitrumMockToken),
            "Token should be added"
        );
    }

    //////////////////////////////////////
    //          TOKEN TRANSFERS         //
    //////////////////////////////////////

    function testCallOutWithDepositArbtirum() public {
        //Set up
        testAddLocalTokenArbitrum();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newArbitrumAssetGlobalAddress;
            amountOut = 100 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = rootChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId);

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 1 ether);

        //Mint Underlying Token.
        arbitrumMockToken.mint(address(this), 100 ether);

        //Approve spend by router
        arbitrumMockToken.approve(address(arbitrumPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumMockToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        arbitrumMulticallBranchBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(address(this)), packedData, depositInput, GasParams(0.5 ether, 0.5 ether), true
        );

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(arbitrumMulticallBranchBridgeAgent),
            uint32(1),
            address(this),
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumMockToken),
            100 ether,
            100 ether
        );

        console2.log("LocalPort Balance:", MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)));
        require(
            MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)) == 50 ether, "LocalPort should have 50 tokens"
        );

        console2.log("User Balance:", MockERC20(arbitrumMockToken).balanceOf(address(this)));
        require(MockERC20(arbitrumMockToken).balanceOf(address(this)) == 50 ether, "User should have 50 tokens");

        console2.log("User Global Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)));
        require(
            MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(this)) == 50 ether,
            "User should have 50 global tokens"
        );
    }

    function testFuzzCallOutWithDepositArbtirum(
        address _user,
        uint256 _amount,
        uint256 _deposit,
        uint256 _amountOut,
        uint256 _depositOut
    ) public {
        // Input restrictions
        _amount %= type(uint128).max;

        vm.assume(
            _user != address(0) && _user != address(arbitrumPort) && _user != address(rootPort)
                && _amount > _deposit && _amount >= _amountOut && _amount - _amountOut >= _depositOut
                && _depositOut < _amountOut
        );

        //Set up
        testAddLocalTokenArbitrum();

        //Prepare data
        bytes memory packedData;

        {
            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newArbitrumAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 0 ether)
            });

            //Output Params
            OutputParams memory outputParams =
                OutputParams(_user, newArbitrumAssetGlobalAddress, _amountOut, _depositOut);

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, rootChainId);

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(_user, 1 ether);

        if (_amount - _deposit > 0) {
            //assure there is enough balance for mock action
            vm.startPrank(address(rootPort));
            ERC20hTokenRoot(newArbitrumAssetGlobalAddress).mint(_user, _amount - _deposit, rootChainId);
            vm.stopPrank();
            arbitrumMockToken.mint(address(arbitrumPort), _amount - _deposit);
        }

        //Mint Underlying Token.
        if (_deposit > 0) arbitrumMockToken.mint(_user, _deposit);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(newArbitrumAssetGlobalAddress),
            token: address(arbitrumMockToken),
            amount: _amount,
            deposit: _deposit
        });

        console2.log("BALANCE BEFORE:");
        console2.log("arbitrumMockToken Balance:", MockERC20(arbitrumMockToken).balanceOf(_user));
        console2.log(
            "newArbitrumAssetGlobalAddress Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(_user)
        );

        //Call Deposit function
        vm.startPrank(_user);
        arbitrumMockToken.approve(address(arbitrumPort), _deposit);
        ERC20hTokenRoot(newArbitrumAssetGlobalAddress).approve(address(rootPort), _amount - _deposit);
        arbitrumMulticallBranchBridgeAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(_user), packedData, depositInput, GasParams(0.5 ether, 0.5 ether), false
        );
        vm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(arbitrumMulticallBranchBridgeAgent),
            uint32(1),
            _user,
            address(newArbitrumAssetGlobalAddress),
            address(arbitrumMockToken),
            _amount,
            _deposit
        );

        console2.log("DATA");
        console2.log(_amount);
        console2.log(_deposit);
        console2.log(_amountOut);
        console2.log(_depositOut);

        address userAccount = address(rootPort.getUserAccount(_user));

        console2.log("LocalPort Balance:", MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)));
        console2.log("Expected:", _amount - _deposit + _deposit - _depositOut);
        require(
            MockERC20(arbitrumMockToken).balanceOf(address(arbitrumPort)) == _amount - _deposit + _deposit - _depositOut,
            "LocalPort tokens"
        );

        console2.log("RootPort Balance:", MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)));
        // console2.log("Expected:", 0); SINCE ORIGIN == DESTINATION == ARBITRUM
        require(MockERC20(newArbitrumAssetGlobalAddress).balanceOf(address(rootPort)) == 0, "RootPort tokens");

        console2.log("User Balance:", MockERC20(arbitrumMockToken).balanceOf(_user));
        console2.log("Expected:", _depositOut);
        require(MockERC20(arbitrumMockToken).balanceOf(_user) == _depositOut, "User tokens");

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

    uint32 prevNonceRoot;
    uint32 prevNonceBranch;

    function testCallOutWithDepositSuccess() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(500_000, 0));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 100 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            payable(address(this)), packedData, depositInput, GasParams(800_000, 0.01 ether), false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        console2.log("GOING ROOT AFTER BRIDGE REQUEST FROM AVAX");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(this),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositNotEnoughGasForRootRetryMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(500_000, 0));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 100 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            payable(address(this)), packedData, depositInput, GasParams(600_000, 0.01 ether), false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        console2.log("GOING ROOT AFTER BRIDGE REQUEST FROM AVAX");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(this),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositWrongCalldataForRootRetryMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 990 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(500_000, 0));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 100 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            payable(address(this)), packedData, depositInput, GasParams(1_250_000, 0.01 ether), false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        console2.log("GOING ROOT AFTER BRIDGE REQUEST FROM AVAX");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(this),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );
    }

    function testCallOutWithDepositNotEnoughGasForRootFallbackMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(500_000, 0));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 100 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            payable(address(this)), packedData, depositInput, GasParams(800_000, 0.01 ether), true
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        console2.log("GOING ROOT AFTER BRIDGE REQUEST FROM AVAX");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(this),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToChainWithoutExecutePendingOrPacketUpdate(rootChainId);
    }

    function testCallOutWithDepositWrongCalldataForRootFallbackMode() public {
        //Set up
        testAddLocalTokenArbitrum();

        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);
        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 990 ether;
            depositOut = 50 ether;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(500_000, 0));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        //Get some gas.
        vm.deal(address(this), 100 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(avaxMockAssethToken),
            token: address(avaxMockAssetToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        //Call Deposit function
        avaxMulticallBridgeAgent.callOutSignedAndBridge{value: 100 ether}(
            payable(address(this)), packedData, depositInput, GasParams(1_250_000, 0.01 ether), true
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce() - 1, "Branch should be updated");

        console2.log("GOING ROOT AFTER BRIDGE REQUEST FROM AVAX");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        // Test If Deposit was successful
        testCreateDepositSingle(
            address(avaxMulticallBridgeAgent),
            uint32(prevNonceBranch),
            address(this),
            address(avaxMockAssethToken),
            address(avaxMockAssetToken),
            100 ether,
            100 ether
        );

        switchToLzChain(avaxChainId);

        // Check if status failed
        avaxMulticallBridgeAgent.getDepositEntry(prevNonceBranch).status = 1;
    }

    //////////////////////////////////////
    //    RETRY, RETRIEVE AND REDEEM    //
    //////////////////////////////////////

    function testRetrieveDeposit() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootFallbackMode();

        switchToLzChain(avaxChainId);

        //Get some ether.
        vm.deal(address(this), 10 ether);

        //Call Deposit function
        console2.log("retrieving");
        avaxMulticallBridgeAgent.retrieveDeposit{value: 10 ether}(prevNonceRoot, GasParams(1_000_000, 0.01 ether));

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).status == 0, "Deposit status should be success."
        );

        console2.log("Going ROOT to retrieve Deposit");
        switchToLzChain(rootChainId);
        console2.log("Triggered Fallback");

        console2.log("Returning to FTM");
        switchToLzChain(avaxChainId);
        console2.log("Done ROOT");

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).status == 1,
            "Deposit status should be ready for redemption."
        );
    }

    function testRedeemDepositAfterRetrieve() public {
        //Set up
        testRetrieveDeposit();

        //Get some ether.
        vm.deal(address(this), 10 ether);

        uint256 balanceBefore = avaxMockAssetToken.balanceOf(address(this));

        //Call Deposit function
        console2.log("redeeming");
        avaxMulticallBridgeAgent.redeemDeposit(prevNonceRoot);

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).owner == address(0),
            "Deposit status should have ceased to exist"
        );

        require(
            avaxMockAssetToken.balanceOf(address(this)) == balanceBefore + 100 ether, "Balance should be increased."
        );
    }

    function testRedeemDepositAfterFallback() public {
        //Set up
        testCallOutWithDepositWrongCalldataForRootFallbackMode();

        //Get some ether.
        vm.deal(address(this), 10 ether);

        uint256 balanceBefore = avaxMockAssetToken.balanceOf(address(this));

        //Call Deposit function
        console2.log("redeeming");
        avaxMulticallBridgeAgent.redeemDeposit(prevNonceRoot);

        require(
            avaxMulticallBridgeAgent.getDepositEntry(prevNonceRoot).owner == address(0),
            "Deposit status should have ceased to exist"
        );

        require(
            avaxMockAssetToken.balanceOf(address(this)) == balanceBefore + 100 ether, "Balance should be increased."
        );
    }

    function testRetryDeposit() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootRetryMode();

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some gas 5 AVAX.
        vm.deal(address(this), 5 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retryDeposit{value: 5 ether}(
            true, prevNonceBranch - 1, packedData, GasParams(2_000_000, 0.02 ether), false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce() - 1, "Root should be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(this)) == 99 ether, "Tokens should be received");
    }

    function testRetryDepositNotEnoughGasForSettlement() public {
        //Set up
        testCallOutWithDepositNotEnoughGasForRootRetryMode();

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(20_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some gas 5 AVAX.
        vm.deal(address(this), 5 ether);

        //Mint Underlying Token.
        avaxMockAssetToken.mint(address(this), 100 ether);

        //Approve spend by router
        avaxMockAssetToken.approve(address(avaxPort), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retryDeposit{value: 5 ether}(
            true, prevNonceBranch - 1, packedData, GasParams(2_000_000, 0.02 ether), false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        console2.log("going root - retry deposit");

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce() - 1, "Root should be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(this)) == 0, "Tokens should be received");
    }

    function testRetrySettlement() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some gas 5 AVAX.
        vm.deal(address(this), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "", [GasParams(1_000_000, 0.1 ether), GasParams(200_000, 0)], false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        switchToLzChain(rootChainId);

        console2.log("going root - retry settlement");

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        // check this address balance
        require(MockERC20(newAvaxAssetFtmLocalToken).balanceOf(address(this)) == 99 ether, "Tokens should be received");
    }

    function _forceFallback() internal pure returns (bytes memory) {
        revert("fallback pls");
    }

    function testRetrySettlementTriggerFallback() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some gas 5 AVAX.
        vm.deal(address(this), 100 ether);

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "jkladsjkldsajklads", [GasParams(1_000_000, 0.1 ether), GasParams(300_000, 0)], true
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        console2.log("going root - retry settlement");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        console2.log("Going root after settlement fallback");

        switchToLzChain(rootChainId);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 1,
            "Settlement status should be failed after fallback."
        );
    }

    function testRedeemSettlement() public {
        //Set up
        testRetrySettlementTriggerFallback();

        //Get some ether.
        vm.deal(address(this), 1 ether);

        //Call Deposit function
        multicallRootBridgeAgent.redeemSettlement(prevNonceRoot - 1);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).owner == address(0),
            "Settlement should have vanished."
        );
    }

    function testRetrySettlementNoFallback() public {
        //Set up
        testRetryDepositNotEnoughGasForSettlement();

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        prevNonceBranch = avaxMulticallBridgeAgent.depositNonce();

        //Switch to avax
        switchToLzChainWithoutExecutePendingOrPacketUpdate(rootChainId);
        prevNonceRoot = multicallRootBridgeAgent.settlementNonce();

        //Prepare data
        address outputToken;
        uint256 amountOut;
        uint256 depositOut;
        bytes memory packedData;

        {
            outputToken = newAvaxAssetGlobalAddress;
            amountOut = 99 ether;
            depositOut = 0;

            Multicall2.Call[] memory calls = new Multicall2.Call[](1);

            //Mock action
            calls[0] = Multicall2.Call({
                target: newAvaxAssetGlobalAddress,
                callData: abi.encodeWithSelector(bytes4(0xa9059cbb), mockApp, 1 ether)
            });

            //Output Params
            OutputParams memory outputParams = OutputParams(address(this), outputToken, amountOut, depositOut);

            //dstChainId
            uint16 dstChainId = ftmChainId;

            //RLP Encode Calldata
            bytes memory data = abi.encode(calls, outputParams, dstChainId, GasParams(800_000, 1 ether));

            //Pack FuncId
            packedData = abi.encodePacked(bytes1(0x02), data);
        }

        switchToLzChainWithoutExecutePendingOrPacketUpdate(avaxChainId);

        //Get some gas 5 AVAX.
        vm.deal(address(this), 100 ether);

        //     retrySettlement(
        //     uint32 _settlementNonce,
        //     bytes calldata _params,
        //     GasParams[2] calldata _gParams,
        //     bool _hasFallbackToggled
        // )

        //Call Deposit function
        avaxMulticallBridgeAgent.retrySettlement{value: 100 ether}(
            prevNonceBranch - 1, "jkladsjkldsajklads", [GasParams(1_000_000, 0.1 ether), GasParams(300_000, 0)], false
        );

        require(prevNonceBranch == avaxMulticallBridgeAgent.depositNonce(), "Branch should not be udpated");

        console2.log("going root - retry settlement");

        switchToLzChain(rootChainId);

        require(prevNonceRoot == multicallRootBridgeAgent.settlementNonce(), "Root should not be updated");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        switchToLzChain(ftmChainId);

        console2.log("Going root after settlement failure");

        switchToLzChain(rootChainId);

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 0,
            "Settlement status should be stay unexecuted after failure."
        );
    }

    function testRetrieveSettlement() public {
        //Set up
        testRetrySettlementNoFallback();

        //Get some ether.
        vm.deal(address(this), 1 ether);

        //Call Deposit function
        console2.log("retrieving");
        multicallRootBridgeAgent.retrieveSettlement{value: 1 ether}(prevNonceRoot - 1, GasParams(1_000_000, 0.1 ether));

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot).status == 0,
            "Settlement status should be success."
        );

        console2.log("Going FTM to retrieve settlement");
        switchToLzChain(ftmChainId);
        console2.log("Triggered Fallback");

        console2.log("Returning ROOT");
        switchToLzChain(rootChainId);
        console2.log("Done ROOT");

        require(
            multicallRootBridgeAgent.getSettlementEntry(prevNonceRoot - 1).status == 1,
            "Settlement status should be ready for redemption."
        );
    }

    //////////////////////////////////////////////////////////////////////////   HELPERS   ///////////////////////////////////////////////////////////////////

    function testCreateDepositSingle(
        // address _branchPort,
        address _bridgeAgent,
        uint32 _depositNonce,
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit
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
        Deposit memory deposit = BranchBridgeAgent(payable(_bridgeAgent)).getDepositEntry(_depositNonce);

        console2.log(deposit.hTokens[0], hTokens[0]);
        console2.log(deposit.tokens[0], tokens[0]);
        console2.log("owner", deposit.owner);
        console2.log("user", _user);

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
}

contract MockPortStartegy {
    function withdraw(address port, address token, uint256 amount) public {
        MockERC20(token).transfer(port, amount);
    }
}
