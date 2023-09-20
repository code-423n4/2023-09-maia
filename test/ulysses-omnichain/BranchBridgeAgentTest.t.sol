//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./helpers/ImportHelper.sol";

contract BranchBridgeAgentTest is Test {
    MockERC20 underlyingToken;

    MockERC20 rewardToken;

    ERC20hTokenBranch testToken;

    BaseBranchRouter bRouter;

    BranchBridgeAgent bAgent;

    uint16 rootChainId = uint16(42161);

    uint16 localChainId = uint16(1088);

    address rootBridgeAgentAddress = address(0xBEEF);

    address lzEndpointAddress = address(0xCAFE);

    address localPortAddress;

    address owner = address(this);

    bytes private rootBridgeAgentPath;

    function setUp() public {
        underlyingToken = new MockERC20("underlying token", "UNDER", 18);

        rewardToken = new MockERC20("hermes token", "HERMES", 18);

        localPortAddress = address(new BranchPort(owner));

        testToken = new ERC20hTokenBranch(       "Test Ulysses ",
            "test-u","Hermes underlying token", "hUNDER",18, address(this));

        bRouter = new BaseBranchRouter();

        BranchPort(payable(localPortAddress)).initialize(address(bRouter), address(this));

        bAgent = new BranchBridgeAgent(
            rootChainId,
            localChainId,
            rootBridgeAgentAddress,
            lzEndpointAddress,
            address(bRouter),
            localPortAddress
        );

        bRouter.initialize(address(bAgent));

        BranchPort(payable(localPortAddress)).addBridgeAgent(address(bAgent));

        rootBridgeAgentPath = abi.encodePacked(rootBridgeAgentAddress, address(bAgent));

        vm.mockCall(lzEndpointAddress, "", "");
    }

    receive() external payable {}

    function _getAdapterParams(uint256 _gasLimit, uint256 _remoteBranchExecutionGas)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodePacked(uint16(2), _gasLimit, _remoteBranchExecutionGas, rootBridgeAgentAddress);
    }

    function expectLayerZeroSend(uint256 msgValue, bytes memory data, address refundee, GasParams memory gasParams)
        internal
    {
        vm.expectCall(
            lzEndpointAddress,
            msgValue,
            abi.encodeWithSelector(
                // "send(uint16,bytes,bytes,address,address,bytes)",
                ILayerZeroEndpoint.send.selector,
                rootChainId,
                rootBridgeAgentPath,
                data,
                refundee,
                address(0),
                _getAdapterParams(gasParams.gasLimit, gasParams.remoteBranchExecutionGas)
            )
        );
    }

    function testCallOutNoDeposit() public {
        testFuzzCallOutNoDeposit(address(this));
    }

    function testFuzzCallOutNoDeposit(address _user) public {
        // Input restrictions
        if (_user < address(3)) _user = address(3);

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        uint32 depositNonce = bAgent.depositNonce();

        expectLayerZeroSend(1 ether, abi.encodePacked(bytes1(0x01), depositNonce, "testdata"), _user, gasParams);

        //Call Deposit function
        IBranchRouter(bRouter).callOut{value: 1 ether}("testdata", gasParams);

        // Prank out of user account
        vm.stopPrank();

        assertEq(bAgent.depositNonce(), depositNonce + 1);
    }

    function testCallOutWithDeposit() public {
        testCallOutWithDeposit(address(this), 100 ether);
    }

    function testCallOutWithDeposit(address _user, uint256 _amount) public {
        // Input restrictions
        if (_user < address(3)) _user = address(3);
        else if (_user == localPortAddress) _user = address(uint160(_user) - 10);

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Mint Test tokens.
        underlyingToken.mint(_user, _amount);

        //Approve spend by router
        underlyingToken.approve(address(bRouter), _amount);

        console2.log("Test CallOut Addresses:");
        console2.log(address(testToken), address(underlyingToken));

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(testToken),
            token: address(underlyingToken),
            amount: _amount,
            deposit: _amount
        });

        uint32 depositNonce = bAgent.depositNonce();

        expectLayerZeroSend(
            1 ether,
            abi.encodePacked(
                bytes1(0x02),
                depositNonce,
                depositInput.hToken,
                depositInput.token,
                depositInput.amount,
                depositInput.deposit,
                "testdata"
            ),
            _user,
            gasParams
        );

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridge{value: 1 ether}("testdata", depositInput, gasParams);

        // Prank out of user account
        vm.stopPrank();

        assertEq(bAgent.depositNonce(), depositNonce + 1);

        // Test If Deposit was successful
        testCreateDepositSingle(uint32(1), _user, address(testToken), address(underlyingToken), _amount, _amount);
    }

    address storedFallbackUser;

    function testCallOutSignedAndBridge(address _user, uint256 _amount) public {
        // Input restrictions
        if (_user < address(3)) _user = address(3);
        else if (_user == localPortAddress) _user = address(uint160(_user) - 10);

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Mint Test tokens.
        underlyingToken.mint(_user, _amount);

        //Approve spend by router
        underlyingToken.approve(localPortAddress, _amount);

        console2.log("Test CallOut Addresses:");
        console2.log(address(testToken), address(underlyingToken));

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(testToken),
            token: address(underlyingToken),
            amount: _amount,
            deposit: _amount
        });

        uint32 depositNonce = bAgent.depositNonce();

        expectLayerZeroSend(
            1 ether,
            abi.encodePacked(
                bytes1(0x85),
                _user,
                depositNonce,
                depositInput.hToken,
                depositInput.token,
                depositInput.amount,
                depositInput.deposit,
                "testdata"
            ),
            _user,
            gasParams
        );

        //Call Deposit function
        bAgent.callOutSignedAndBridge{value: 1 ether}(payable(_user), "testdata", depositInput, gasParams, true);

        // Prank out of user account
        vm.stopPrank();

        assertEq(bAgent.depositNonce(), depositNonce + 1);

        // Test If Deposit was successful
        testCreateDepositSingle(uint32(1), _user, address(testToken), address(underlyingToken), _amount, _amount);

        // Store user for usage in other tests
        storedFallbackUser = _user;
    }

    function testCallOutInsufficientAmount() public {
        // Get some gas.
        vm.deal(address(this), 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Mint Test tokens.
        underlyingToken.mint(address(this), 90 ether);

        //Approve spend by router
        underlyingToken.approve(address(bRouter), 100 ether);

        console2.log("Test CallOut TokenAddresses:");
        console2.log(address(testToken), address(underlyingToken));

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(testToken),
            token: address(underlyingToken),
            amount: 100 ether,
            deposit: 100 ether
        });

        vm.expectRevert(abi.encodeWithSignature("TransferFromFailed()"));

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridge{value: 1 ether}(bytes("testdata"), depositInput, gasParams);
    }

    function testCallOutIncorrectAmount() public {
        // Get some gas.
        vm.deal(address(this), 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        //Mint Test tokens.
        underlyingToken.mint(address(this), 100 ether);

        //Approve spend by router
        underlyingToken.approve(address(bRouter), 100 ether);

        console2.logUint(1);
        console2.log(address(testToken), address(underlyingToken));

        // Prepare deposit info
        DepositInput memory depositInput = DepositInput({
            hToken: address(testToken),
            token: address(underlyingToken),
            amount: 90 ether,
            deposit: 100 ether
        });

        vm.expectRevert(stdError.arithmeticError);

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridge{value: 1 ether}(bytes("testdata"), depositInput, gasParams);
    }

    function testFuzzCallOutWithDeposit() public {
        testFuzzCallOutWithDeposit(address(this), 1 ether, 0.5 ether, 18);
    }

    function testFuzzCallOutWithDeposit(address _user, uint256 _amount, uint256 _deposit, uint8 _decimals) public {
        // Input restrictions
        if (_user < address(3)) _user = address(3);
        if (_amount == 0) _amount = 1;
        if (_amount < _deposit) _deposit %= _amount;

        // Get some gas.
        vm.deal(_user, 1 ether);

        // Prank into Port
        vm.startPrank(localPortAddress);

        // Mint Test tokens.
        ERC20hTokenBranch fuzzToken =
            new ERC20hTokenBranch("Test Ulysses ", "test-u","fuzz token", "FUZZ",_decimals, localPortAddress);
        fuzzToken.mint(_user, _amount - _deposit);

        // Mint under tokens.
        ERC20hTokenBranch uunderToken = new ERC20hTokenBranch(
            "Test Ulysses ",
            "test-u",
            "uunder token",
            "UU",
            _decimals,
            localPortAddress
        );
        uunderToken.mint(_user, _deposit);

        vm.stopPrank();

        //Prepare deposit info
        DepositInput memory depositInput =
            DepositInput({hToken: address(fuzzToken), token: address(uunderToken), amount: _amount, deposit: _deposit});

        // Prank into user account
        vm.startPrank(_user);

        // Approve spend by router
        fuzzToken.approve(address(bRouter), _amount);
        uunderToken.approve(address(bRouter), _deposit);

        uint32 depositNonce = bAgent.depositNonce();

        address _userCache = _user;

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        expectLayerZeroSend(
            1 ether,
            abi.encodePacked(
                bytes1(0x02),
                depositNonce,
                depositInput.hToken,
                depositInput.token,
                depositInput.amount,
                depositInput.deposit,
                "testdata"
            ),
            _userCache,
            gasParams
        );

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridge{value: 1 ether}(bytes("testdata"), depositInput, gasParams);

        // Prank out of user account
        vm.stopPrank();

        assertEq(bAgent.depositNonce(), depositNonce + 1);

        // Test If Deposit was successful
        testCreateDepositSingle(uint32(1), _user, address(fuzzToken), address(uunderToken), _amount, _deposit);
    }

    function testFallbackClearDepositRedeemSuccess() public {
        // Create Test Deposit
        testCallOutSignedAndBridge(address(this), 100 ether);

        vm.deal(localPortAddress, 1 ether);

        // Encode Fallback message
        bytes memory fallbackData = abi.encodePacked(bytes1(0x04), uint32(1));

        // Call 'Fallback'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, fallbackData);

        // Call redeemDeposit
        bAgent.redeemDeposit(1);

        // Check deposit state
        require(bAgent.getDepositEntry(1).owner == address(0), "Deposit should be deleted");

        // Check balances
        require(testToken.balanceOf(address(this)) == 0);
        require(underlyingToken.balanceOf(address(this)) == 100 ether);
        require(testToken.balanceOf(localPortAddress) == 0);
        require(underlyingToken.balanceOf(localPortAddress) == 0);
    }

    function testFallbackClearDepositRedeemAlreadyRedeemed() public {
        // Redeem once
        testFallbackClearDepositRedeemSuccess();

        vm.expectRevert(abi.encodeWithSignature("DepositRedeemUnavailable()"));

        // Call redeemDeposit again
        bAgent.redeemDeposit(1);
    }

    function testFallbackClearDepositRedeemDouble() public {
        // Create Test Deposit
        testCallOutSignedAndBridge(address(this), 100 ether);

        // Encode fallback message
        bytes memory fallbackData = abi.encodePacked(bytes1(0x04), uint32(1));

        // Call 'Fallback'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, fallbackData);

        bAgent.redeemDeposit(1);

        vm.startPrank(lzEndpointAddress);

        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, fallbackData);

        vm.expectRevert(abi.encodeWithSignature("DepositRedeemUnavailable()"));

        bAgent.redeemDeposit(1);
    }

    function testFuzzFallbackClearDepositRedeem(address _user, uint256 _amount, uint256 _deposit, uint16 _dstChainId)
        public
    {
        _amount %= type(uint256).max / 1 ether;

        // Input restrictions
        vm.assume(_user != address(0) && _amount > 0 && _deposit <= _amount && _dstChainId > 0);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        vm.startPrank(localPortAddress);

        // Mint Test tokens.
        ERC20hTokenBranch fuzzToken = new ERC20hTokenBranch(
             "Test Ulysses ",
            "test-u",
            "Hermes omni token",
            "hUNDER",
            18,
            localPortAddress
        );
        fuzzToken.mint(_user, _amount - _deposit);
        MockERC20 underToken = new MockERC20("u token", "U", 18);
        underToken.mint(_user, _deposit);

        vm.stopPrank();

        // Perform deposit
        makeTestCallWithDepositSigned(
            _user, address(fuzzToken), address(underToken), _amount, _deposit, gasParams, true
        );

        // Prepare deposit info
        DepositParams memory depositParams = DepositParams({
            hToken: address(fuzzToken),
            token: address(underlyingToken),
            amount: _amount - _deposit,
            deposit: _deposit,
            depositNonce: 1
        });

        // Encode Fallback message
        bytes memory fallbackData = abi.encodePacked(bytes1(0x04), depositParams.depositNonce);

        // Call 'Fallback'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, fallbackData);

        // Call redeemDeposit
        vm.prank(_user);
        bAgent.redeemDeposit(1);

        // Check balances
        require(fuzzToken.balanceOf(address(_user)) == _amount - _deposit);
        require(underToken.balanceOf(address(_user)) == _deposit);
        require(fuzzToken.balanceOf(localPortAddress) == 0);
        require(underToken.balanceOf(localPortAddress) == 0);
    }

    function testRetryDeposit() public {
        // Create Test Deposit
        testCallOutWithDeposit();

        vm.deal(localPortAddress, 1 ether);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        vm.deal(address(this), 1 ether);

        //Call redeemDeposit
        bAgent.retryDeposit{value: 1 ether}(true, 1, "", gasParams, true);

        //TODO Check if still success (?)
    }

    function testRetryDepositFailNotOwner() public {
        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        // Create Test Deposit
        testCallOutWithDeposit();

        vm.deal(localPortAddress, 1 ether);

        vm.deal(localPortAddress, 1 ether);

        vm.deal(address(42), 1 ether);

        vm.startPrank(address(42));

        vm.expectRevert(abi.encodeWithSignature("NotDepositOwner()"));

        //Call redeemDeposit
        bAgent.retryDeposit{value: 1 ether}(true, 1, "", gasParams, true);
    }

    function testRetryDepositFailCanAlwaysRetry() public {
        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        // Create Test Deposit
        testCallOutSignedAndBridge(address(this), 100 ether);

        //Prepare deposit info
        DepositParams memory depositParams = DepositParams({
            hToken: address(testToken),
            token: address(underlyingToken),
            amount: 100 ether,
            deposit: 100 ether,
            depositNonce: 1
        });

        // Encode Fallback message
        bytes memory fallbackData = abi.encodePacked(bytes1(0x04), depositParams.depositNonce);

        // Call 'fallback'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, fallbackData);

        vm.deal(address(this), 1 ether);

        //Call redeemDeposit
        bAgent.retryDeposit{value: 1 ether}(true, 1, "", gasParams, true);
    }

    function testFuzzExecuteWithSettlement(address, uint256 _amount, uint256 _deposit, uint16 _dstChainId) public {
        // Input restrictions
        vm.assume(_amount > 0 && _deposit <= _amount && _dstChainId > 0);

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        address _recipient = address(this);

        vm.deal(localPortAddress, 1 ether);

        vm.startPrank(localPortAddress);

        // Mint Test tokens.
        ERC20hTokenBranch fuzzToken = new ERC20hTokenBranch(
                   "Test Ulysses ",
            "test-u",
            "Hermes omni token",
            "hUNDER",
            18,
            localPortAddress
        );
        fuzzToken.mint(_recipient, _amount - _deposit);

        MockERC20 underToken = new MockERC20("u token", "U", 18);
        underToken.mint(_recipient, _deposit);

        vm.stopPrank();

        console2.log("testFuzzClearToken Data:");
        console2.log(_recipient);
        console2.log(address(fuzzToken));
        console2.log(address(underToken));
        console2.log(_amount);
        console2.log(_deposit);
        console2.log(_dstChainId);

        // Perform deposit
        makeTestCallWithDeposit(_recipient, address(fuzzToken), address(underToken), _amount, _deposit, gasParams);

        // Encode Settlement Data for Clear Token Execution
        bytes memory settlementData = abi.encodePacked(
            bytes1(0x01), _recipient, uint32(1), address(fuzzToken), address(underToken), _amount, _deposit, bytes("")
        );

        // Call 'clearToken'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, settlementData);

        require(fuzzToken.balanceOf(_recipient) == _amount - _deposit);
        require(underToken.balanceOf(_recipient) == _deposit);
        require(fuzzToken.balanceOf(localPortAddress) == 0);
        require(underToken.balanceOf(localPortAddress) == 0);
    }

    address[] public hTokens;
    address[] public tokens;
    uint256[] public amounts;
    uint256[] public deposits;

    function testFuzzExecuteWithSettlementMultiple(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _deposit0,
        uint256 _deposit1,
        uint16 _dstChainId
    ) public {
        _amount0 %= type(uint256).max / 1 ether;
        _amount1 %= type(uint256).max / 1 ether;

        //GasParams
        GasParams memory gasParams = GasParams(0.5 ether, 0.5 ether);

        address _recipient = address(this);

        // Input restrictions
        vm.assume(_amount0 > 0 && _deposit0 <= _amount0 && _amount1 > 0 && _deposit1 <= _amount1 && _dstChainId > 0);

        vm.startPrank(localPortAddress);

        // Mint Test tokens.
        ERC20hTokenBranch fuzzToken0 = new ERC20hTokenBranch(
            "Test Ulysses ",
            "test-u",
            "Hermes omni token 0",
            "hToken0",
            18,
            localPortAddress
        );
        ERC20hTokenBranch fuzzToken1 = new ERC20hTokenBranch(
            "Test Ulysses ",
            "test-u",
            "Hermes omni token 1",
            "hToken1",
            18,
            localPortAddress
        );

        fuzzToken0.mint(_recipient, _amount0 - _deposit0);
        fuzzToken1.mint(_recipient, _amount1 - _deposit1);

        MockERC20 underToken0 = new MockERC20("u0 token", "U0", 18);
        MockERC20 underToken1 = new MockERC20("u1 token", "U1", 18);
        underToken0.mint(_recipient, _deposit0);
        underToken1.mint(_recipient, _deposit1);

        console2.log("testFuzzExecuteWithSettlementMultiple DATA:");
        console2.log(_recipient);
        console2.log(address(fuzzToken0));
        console2.log(address(fuzzToken1));
        console2.log(address(underToken0));
        console2.log(address(underToken1));
        console2.log(_amount0);
        console2.log(_amount1);
        console2.log(_deposit0);
        console2.log(_deposit1);
        console2.log(_dstChainId);

        vm.stopPrank();

        // Cast to Dynamic
        hTokens.push(address(fuzzToken0));
        hTokens.push(address(fuzzToken1));
        tokens.push(address(underToken0));
        tokens.push(address(underToken1));
        amounts.push(_amount0);
        amounts.push(_amount1);
        deposits.push(_deposit0);
        deposits.push(_deposit1);

        // Perform deposit
        makeTestCallWithDepositMultiple(_recipient, hTokens, tokens, amounts, deposits, gasParams);

        // Encode Settlement Data for Clear Token Execution
        bytes memory settlementData = abi.encodePacked(
            bytes1(0x02), _recipient, uint8(2), uint32(1), hTokens, tokens, amounts, deposits, bytes("")
        );

        // Call 'clearToken'
        vm.prank(lzEndpointAddress);
        bAgent.lzReceive(rootChainId, abi.encodePacked(bAgent, rootBridgeAgentAddress), 1, settlementData);

        require(fuzzToken0.balanceOf(localPortAddress) == 0);
        require(fuzzToken1.balanceOf(localPortAddress) == 0);
        require(fuzzToken0.balanceOf(_recipient) == _amount0 - _deposit0);
        require(fuzzToken1.balanceOf(_recipient) == _amount1 - _deposit1);
        require(underToken0.balanceOf(localPortAddress) == 0);
        require(underToken1.balanceOf(localPortAddress) == 0);
        require(underToken0.balanceOf(_recipient) == _deposit0);
        require(underToken1.balanceOf(_recipient) == _deposit1);
    }

    function testCreateDeposit(
        uint32 _depositNonce,
        address _user,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) private view {
        // Get Deposit.
        Deposit memory deposit = bRouter.getDepositEntry(_depositNonce);

        // Check deposit
        require(deposit.owner == _user, "Deposit owner doesn't match");

        require(
            keccak256(abi.encodePacked(deposit.hTokens)) == keccak256(abi.encodePacked(_hTokens)),
            "Deposit local hToken doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.tokens)) == keccak256(abi.encodePacked(_tokens)),
            "Deposit underlying token doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.amounts)) == keccak256(abi.encodePacked(_amounts)),
            "Deposit amount doesn't match"
        );
        require(
            keccak256(abi.encodePacked(deposit.deposits)) == keccak256(abi.encodePacked(_deposits)),
            "Deposit deposit doesn't match"
        );

        require(deposit.status == 0, "Deposit status should be success");

        for (uint256 i = 0; i < _hTokens.length; i++) {
            if (_amounts[i] - _deposits[i] > 0 && _deposits[i] == 0) {
                require(MockERC20(_hTokens[i]).balanceOf(_user) == 0);
            } else if (_amounts[i] - _deposits[i] > 0 && _deposits[i] > 0) {
                require(MockERC20(_hTokens[i]).balanceOf(_user) == 0);
                require(MockERC20(_tokens[i]).balanceOf(_user) == 0);
                require(MockERC20(_tokens[i]).balanceOf(localPortAddress) == _deposits[i]);
            } else {
                require(MockERC20(_tokens[i]).balanceOf(_user) == 0);
                require(MockERC20(_tokens[i]).balanceOf(localPortAddress) == _deposits[i]);
            }
        }
    }

    function testCreateDepositSingle(
        uint32 _depositNonce,
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit
    ) private {
        delete hTokens;
        delete tokens;
        delete amounts;
        delete deposits;
        // Cast to Dynamic TODO clean up
        hTokens = new address[](1);
        hTokens[0] = _hToken;
        tokens = new address[](1);
        tokens[0] = _token;
        amounts = new uint256[](1);
        amounts[0] = _amount;
        deposits = new uint256[](1);
        deposits[0] = _deposit;

        // Get Deposit
        Deposit memory deposit = bRouter.getDepositEntry(_depositNonce);

        // Check deposit
        require(deposit.owner == _user, "Deposit owner doesn't match");

        if (_amount != 0 || _deposit != 0) {
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
        }

        require(deposit.status == 0, "Deposit status should be succesful.");

        console2.log("TEST DEPOSIT");

        console2.logUint(amounts[0]);
        console2.logUint(deposits[0]);

        if (hTokens[0] != address(0) || tokens[0] != address(0)) {
            if (amounts[0] > 0 && deposits[0] == 0) {
                require(MockERC20(hTokens[0]).balanceOf(_user) == 0, "Deposit hToken balance doesn't match");

                require(MockERC20(hTokens[0]).balanceOf(localPortAddress) == 0, "Deposit hToken balance doesn't match");
            } else if (amounts[0] - deposits[0] > 0 && deposits[0] > 0) {
                console2.log(_user);
                console2.log(localPortAddress);

                require(MockERC20(hTokens[0]).balanceOf(_user) == 0, "Deposit hToken balance doesn't match");

                require(MockERC20(tokens[0]).balanceOf(_user) == 0, "Deposit token balance doesn't match");
                require(
                    MockERC20(tokens[0]).balanceOf(localPortAddress) == _deposit, "Deposit token balance doesn't match"
                );
            } else {
                require(MockERC20(tokens[0]).balanceOf(_user) == 0, "Deposit token balance doesn't match");
                require(
                    MockERC20(tokens[0]).balanceOf(localPortAddress) == _deposit, "Deposit token balance doesn't match"
                );
            }
        }
    }

    function makeTestCallWithDeposit(
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit,
        GasParams memory _gasParams
    ) private {
        // Prepare deposit info
        DepositInput memory depositInput =
            DepositInput({hToken: _hToken, token: _token, amount: _amount, deposit: _deposit});

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        // Approve spend by router
        ERC20hTokenBranch(_hToken).approve(address(bRouter), _amount - _deposit);
        MockERC20(_token).approve(address(bRouter), _deposit);

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridge{value: 1 ether}(bytes("testdata"), depositInput, _gasParams);

        // Prank out of user account
        vm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(uint32(1), _user, address(_hToken), address(_token), _amount, _deposit);
    }

    function makeTestCallWithDepositSigned(
        address _user,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit,
        GasParams memory _gasParams,
        bool _hasFallbackToggled
    ) private {
        // Prepare deposit info
        DepositInput memory depositInput =
            DepositInput({hToken: _hToken, token: _token, amount: _amount, deposit: _deposit});

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        // Approve spend by router
        ERC20hTokenBranch(_hToken).approve(localPortAddress, _amount - _deposit);
        MockERC20(_token).approve(localPortAddress, _deposit);

        //Call Deposit function
        bAgent.callOutSignedAndBridge{value: 1 ether}(
            payable(_user), bytes("testdata"), depositInput, _gasParams, _hasFallbackToggled
        );

        // Prank out of user account
        vm.stopPrank();

        // Test If Deposit was successful
        testCreateDepositSingle(uint32(1), _user, address(_hToken), address(_token), _amount, _deposit);
    }

    function makeTestCallWithDepositMultiple(
        address _user,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits,
        GasParams memory _gasParams
    ) private {
        //Prepare deposit info
        DepositMultipleInput memory depositInput =
            DepositMultipleInput({hTokens: _hTokens, tokens: _tokens, amounts: _amounts, deposits: _deposits});

        // Prank into user account
        vm.startPrank(_user);

        // Get some gas.
        vm.deal(_user, 1 ether);

        console2.log(_hTokens[0], _deposits[0]);

        // Approve spend by router
        MockERC20(_hTokens[0]).approve(address(bRouter), _amounts[0] - _deposits[0]);
        MockERC20(_tokens[0]).approve(address(bRouter), _deposits[0]);
        MockERC20(_hTokens[1]).approve(address(bRouter), _amounts[1] - _deposits[1]);
        MockERC20(_tokens[1]).approve(address(bRouter), _deposits[1]);

        //Call Deposit function
        IBranchRouter(bRouter).callOutAndBridgeMultiple{value: 1 ether}(bytes("test"), depositInput, _gasParams);

        // Prank out of user account
        vm.stopPrank();

        // Test If Deposit was successful
        testCreateDeposit(uint32(1), _user, _hTokens, _tokens, _amounts, _deposits);
    }
}
