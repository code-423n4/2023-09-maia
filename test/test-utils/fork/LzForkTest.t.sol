// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {LibString} from "solady/utils/LibString.sol";

import {Test, Vm} from "forge-std/Test.sol";

import {console2} from "forge-std/console2.sol";

import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

abstract contract LzForkTest is Test {
    using SafeCastLib for uint256;
    using LibString for string;

    /////////////////////////////////
    //         Fork Chains         //
    /////////////////////////////////

    // Relevant information for a fork chain
    struct ForkChain {
        uint256 chainId;
        uint16 lzChainId;
        address lzEndpoint;
    }

    // forkChains is a list of all fork layer zero ChainIds
    uint16[] public lzChainIds;

    // chainIdToLzChainId is a mapping of production chainIds to layer zero ChainIds
    mapping(uint256 chainId => uint16 lzChainId) public chainIdToLzChainId;

    // forkChainMap is a mapping of layer zero ChainIds to fork chain state
    mapping(uint16 lzChainId => ForkChain chainInfo) public forkChains;

    // forkChainIds is a list of all fork chainIds
    mapping(uint16 lzChainId => uint256 chainId) public forkChainIds;

    /////////////////////////////////
    //          Packets            //
    /////////////////////////////////

    // Packet event hash constant
    bytes32 constant PACKET_EVENT_HASH = keccak256("Packet(bytes)");

    // RelayerParams event hash constant
    bytes32 constant RELAYER_PARAMS_EVENT_HASH = keccak256("RelayerParams(bytes,uint16)");

    // Execution status of a packet
    enum ExecutionStatus {
        None,
        Pending,
        Executed
    }

    // Relevant information for a fork chain
    struct Packet {
        uint64 nonce;
        uint16 originLzChainId;
        address originUA;
        uint16 destinationLzChainId;
        address destinationUA;
        bytes payload;
        bytes data;
    }

    // Relayer parameter emitted along packet
    struct RelayerParams {
        bytes adapterParams;
        uint16 outboundProofType;
    }

    // Relayer Adapter Params
    struct AdapterParams {
        uint16 version;
        RelayerParams relayerParams;
    }

    // Packet data emitted from a given chain
    mapping(uint16 srcChainId => Packet[] outgoingPackets) public packetsFromChain;

    // Packet data emitted to a given chain
    mapping(uint16 dstChainId => Packet[] incomingPackets) public packetsToChain;

    // Packet execution status
    mapping(bytes32 packetHash => ExecutionStatus status) public packetExecutionStatus;

    // Packet adapter params mapping
    mapping(bytes32 packetHash => AdapterParams adapterParams) public packetAdapterParams;

    /////////////////////////////////
    //           Views             //
    /////////////////////////////////

    /// @notice getNextPacket returns the next packet from a layer zero chain.
    /// @param lzChainId the layer zero chain id of the packet
    function getNextPacket(uint16 lzChainId) public view returns (Packet memory) {
        return packetsFromChain[lzChainId][0];
    }

    /// @notice getIncomingPackets returns the incoming packets for a layer zero chain.
    /// @param lzChainId the layer zero chain id of the packet
    function getIncomingPackets(uint16 lzChainId) public view returns (Packet[] memory) {
        return packetsToChain[lzChainId];
    }

    /// @notice getOutgoingPackets returns the outgoing packets for a layer zero chain.
    /// @param lzChainId the layer zero chain id of the packet
    function getOutgoingPackets(uint16 lzChainId) public view returns (Packet[] memory) {
        return packetsFromChain[lzChainId];
    }

    /////////////////////////////////
    //           SetUp             //
    /////////////////////////////////

    /// @notice setUp is called by the test runner before each test, setting up different fork chains.
    function setUp() public virtual {
        // Set up default fork chains
        setUpDefaultLzChains();

        // Start the recorder necessary for packet tracking
        vm.recordLogs();
    }

    /////////////////////////////////
    //       Set Up Helpers        //
    /////////////////////////////////

    /// @notice setUpDefaultLzChains sets up the default fork chains for testing.
    function setUpDefaultLzChains() internal virtual {
        // Access variables from .env file via vm.envString("varname")
        // Change RPCs using your .env file
        // Override setUp() if you don't want to set up Default Layer Zero Chains

        console2.log("Setting up default fork chains...");

        // addChain(
        //     ForkChain(1, 101, 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675),
        //     string.concat(vm.envString("MAINNET_RPC_URL"), vm.envString("INFURA_API_KEY"))
        // );

        addChain(
            ForkChain(43114, 106, 0x3c2269811836af69497E5F486A85D7316753cf62),
            string.concat(vm.envString("AVAX_RPC_URL"), vm.envString("INFURA_API_KEY")),
            35265612
        );

        // addChain(
        //     ForkChain(137, 109, 0x3c2269811836af69497E5F486A85D7316753cf62),
        //     string.concat(vm.envString("POLYGON_RPC_URL"), vm.envString("INFURA_API_KEY"))
        // );

        addChain(
            ForkChain(42161, 110, 0x3c2269811836af69497E5F486A85D7316753cf62),
            string.concat(vm.envString("ARBITRUM_RPC_URL"), vm.envString("INFURA_API_KEY")),
            131673916
        );

        // addChain(
        //     ForkChain(10, 111, 0x3c2269811836af69497E5F486A85D7316753cf62),
        //     string.concat(vm.envString("OPTIMISM_RPC_URL"), vm.envString("INFURA_API_KEY"))
        // );

        // addChain(
        //     ForkChain(42220, 125, 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9),
        //     string.concat(vm.envString("CELO_RPC_URL"), vm.envString("INFURA_API_KEY"))
        // );

        // addChain(ForkChain(56, 102, 0x3c2269811836af69497E5F486A85D7316753cf62), vm.envString("BNB_RPC_URL"));

        addChain(
            ForkChain(250, 112, 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7), vm.envString("FANTOM_RPC_URL"), 68247546
        );

        // addChain(ForkChain(53935, 115, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("DFK_RPC_URL")));

        // addChain(
        //     ForkChain(1666600001, 116, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("HARMONY_RPC_URL"))
        // );

        // addChain(ForkChain(1284, 126, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("MOONBEAM_RPC_URL")));

        // addChain(ForkChain(122, 127, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("FUSE_RPC_URL")));

        // addChain(ForkChain(100, 145, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("GNOSIS_RPC_URL")));

        // addChain(ForkChain(8217, 150, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("KLAYTN_RPC_URL")));

        // addChain(ForkChain(1088, 151, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("METIS_RPC_URL")));

        // addChain(ForkChain(66, 155, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("OKT_RPC_URL")));

        // addChain(
        //     ForkChain(1101, 158, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("POLYGONZKEVM_RPC_URL"))
        // );

        // addChain(ForkChain(7700, 159, 0x9740FF91F1985D8d2B71494aE1A2f723bb3Ed9E4), (vm.envString("CANTO_RPC_URL")));

        // addChain(ForkChain(324, 165, 0x9b896c0e23220469C7AE69cb4BbAE391eAa4C8da), (vm.envString("ZKSYNCERA_RPC_URL")));

        // addChain(ForkChain(1285, 167, 0x7004396C99D5690da76A7C59057C5f3A53e01704), (vm.envString("MOONRIVER_RPC_URL")));

        // addChain(ForkChain(1559, 173, 0x2D61DCDD36F10b22176E0433B86F74567d529aAa), (vm.envString("TENET_RPC_URL")));

        // addChain(
        //     ForkChain(42170, 175, 0x4EE2F9B7cf3A68966c370F3eb2C16613d3235245), (vm.envString("ARBITRUMNOVA_RPC_URL"))
        // );

        // addChain(ForkChain(82, 176, 0xa3a8e19253Ab400acDac1cB0eA36B88664D8DedF), (vm.envString("METERIO_RPC_URL")));

        // addChain(
        //     ForkChain(11155111, 161, 0x7cacBe439EaD55fa1c22790330b12835c6884a91), (vm.envString("SEPOLIA_RPC_URL"))
        // );
    }

    /// @notice addChain adds a new fork chain to the forkChains list.
    /// @param newChain the new chain to add.
    /// @param chainURL the chain's RPC URL.
    function addChain(ForkChain memory newChain, string memory chainURL) public {
        //Verify Addition
        if (bytes(chainURL).length == 0) return;
        //Create Fork Chain
        uint256 forkChainId = vm.createFork(chainURL);
        //Save new lzChainId
        lzChainIds.push(newChain.lzChainId);
        //Add chain Id conversion
        chainIdToLzChainId[newChain.chainId] = newChain.lzChainId;
        //Save new forkChain
        forkChains[newChain.lzChainId] = newChain;
        //Save new forkChainId
        forkChainIds[newChain.lzChainId] = forkChainId;
    }

    /// @notice addChain adds a new fork chain at a given blockNumber to the forkChains list.
    /// @param newChain the new chain to add.
    /// @param chainURL the chain's RPC URL.
    /// @param blockNumber the block number to fork at.
    function addChain(ForkChain memory newChain, string memory chainURL, uint256 blockNumber) public {
        //Verify Addition
        if (bytes(chainURL).length == 0) return;
        //Create Fork Chain
        uint256 forkChainId = vm.createFork(chainURL, blockNumber);
        //Save new lzChainId
        lzChainIds.push(newChain.lzChainId);
        //Add chain Id conversion
        chainIdToLzChainId[newChain.chainId] = newChain.lzChainId;
        //Save new forkChain
        forkChains[newChain.lzChainId] = newChain;
        //Save new forkChainId
        forkChainIds[newChain.lzChainId] = forkChainId;
    }

    /////////////////////////////////
    //        Chain Helpers        //
    /////////////////////////////////

    /// @notice switchToChain switches the current chain to the given chain, executing pending Lz packets and updating Lz packets state.
    /// @param chainId the chain to switch to.
    function switchToChain(uint256 chainId) public {
        vm.selectFork(forkChainIds[chainIdToLzChainId[chainId]]);
        vm.pauseGasMetering();
        updatePackets();
        vm.resumeGasMetering();
        executePackets(chainIdToLzChainId[chainId]);
    }

    /// @notice switchToChainWithoutExecutePending switches the current chain to the given chain without executing pending packets.
    /// @param chainId the chain to switch to.
    function switchToChainWithoutExecutePending(uint256 chainId) public {
        vm.selectFork(forkChainIds[chainIdToLzChainId[chainId]]);
        updatePackets();
    }

    /// @notice switchToChainWithoutPacketUpdate switches the current chain to the given chain without updating layer zero packets.
    /// @param chainId the chain to switch to.
    function switchToChainWithoutPacketUpdate(uint256 chainId) public {
        vm.selectFork(forkChainIds[chainIdToLzChainId[chainId]]);
        executePackets(chainIdToLzChainId[chainId]);
    }

    /// @notice switchToChainWithoutExecutePendingOrPacketUpdate switches the current chain to the given chain without executing pending packets or updating layer zero packets.
    /// @param chainId the chain to switch to.
    function switchToChainWithoutExecutePendingOrPacketUpdate(uint256 chainId) public {
        vm.selectFork(forkChainIds[chainIdToLzChainId[chainId]]);
    }

    /////////////////////////////////
    //       Lz Chain Helpers      //
    /////////////////////////////////

    /// @notice switchToLzChain switches the current chain to the given chain.
    /// @param lzChainId the chain to switch to.
    function switchToLzChain(uint16 lzChainId) public {
        vm.selectFork(forkChainIds[lzChainId]);
        updatePackets();
        vm.resumeGasMetering();
        executePackets(lzChainId);
    }

    /// @notice switchToLzChainWithoutExecutePending switches the current chain to the given chain without executing pending packets.
    /// @param lzChainId the chain to switch to.
    function switchToLzChainWithoutExecutePending(uint16 lzChainId) public {
        vm.selectFork(forkChainIds[lzChainId]);
        updatePackets();
    }

    /// @notice switchToLzChainWithoutPacketUpdate switches the current chain to the given chain without updating layer zero packets.
    /// @param lzChainId the chain to switch to.
    function switchToLzChainWithoutPacketUpdate(uint16 lzChainId) public {
        vm.selectFork(forkChainIds[lzChainId]);
        executePackets(lzChainId);
    }

    /// @notice switchToLzChainWithoutExecutePendingOrPacketUpdate switches the current chain to the given chain without executing pending packets or updating layer zero packets.
    /// @param lzChainId the chain to switch to.
    function switchToLzChainWithoutExecutePendingOrPacketUpdate(uint16 lzChainId) public {
        vm.selectFork(forkChainIds[lzChainId]);
    }

    /////////////////////////////////
    //      Update Lz Packets      //
    /////////////////////////////////

    /// @notice updatePackets updates Lz packets
    function updatePackets() public {
        Vm.Log[] memory entries = vm.getRecordedLogs();

        console2.log("Events caugth:", entries.length);

        for (uint256 i = 0; i < entries.length; i++) {
            // Look for 'RelayerParams' events
            if (entries[i].topics[0] == RELAYER_PARAMS_EVENT_HASH) {
                console2.log("Current entry", i);

                //// 1. Decode Adapter Params

                // Adapter Params Vars
                RelayerParams memory relayerParams;
                uint16 relayerAdapterParamsVersion;

                // Get Adapter Params
                (bytes memory adapterParams, uint16 outboundProofType) = abi.decode(entries[i].data, (bytes, uint16));

                relayerParams = RelayerParams(adapterParams, outboundProofType);

                console2.log("RelayerParams event found", adapterParams.length);

                //// 2. Increment to next event 'Packet'
                i += 2;

                console2.log("Found a Packet!");

                //// 3. Decode new packet instance
                (Packet memory packet, uint16 originLzChainId, uint16 destinationLzChainId) =
                    decodePacket(entries[i].data);

                console2.log("Packet Payload:");
                console2.logBytes(packet.payload);

                //// 4. Get packet hash
                bytes32 packetHash = encodePacket(packet);

                //// 5. Check if packet has already been registered
                if (packetExecutionStatus[packetHash] != ExecutionStatus.None) {
                    continue;
                }

                //// 6. Update Packet storage

                // Update Packet Execution Status
                packetExecutionStatus[packetHash] = ExecutionStatus.Pending;

                // Update Outgoing Packets
                packetsFromChain[originLzChainId].push(packet);

                // Update Incoming Packets
                packetsToChain[destinationLzChainId].push(packet);

                // Attach Packet to Adapter Params
                packetAdapterParams[packetHash] = AdapterParams(relayerAdapterParamsVersion, relayerParams);

                console2.log("Added new Packet to storage");
            }
        }
    }

    /// @notice updateAll updates all packets
    function updateAll(bytes memory, Packet memory) internal pure returns (bool) {
        return false;
    }

    /// @notice updateOrigin updates packets from a layer zero chain
    /// @param data the data to be passed to the updateOrigin function
    /// @param packet the packet to be updated
    function updateOrigin(bytes memory data, Packet memory packet) internal pure returns (bool) {
        return abi.decode(data, (uint16)) == packet.originLzChainId;
    }

    /// @notice updateDestination updates packets to a layer zero chain
    /// @param data the data to be passed to the updateDestination function
    /// @param packet the packet to be updated
    function updateDestination(bytes memory data, Packet memory packet) internal pure returns (bool) {
        return abi.decode(data, (uint16)) == packet.destinationLzChainId;
    }

    /////////////////////////////////
    //      Execute Lz Packets     //
    /////////////////////////////////

    /// @notice executePackets executes all pending packets for a layer zero chain.
    function executePackets(uint16 lzChainId) public {
        // Get incoming packets
        Packet[] storage incoming = packetsToChain[lzChainId];

        // Read packets
        for (uint256 i = 0; i < incoming.length; i++) {
            // Get packet
            Packet memory packet = incoming[i];

            // Execute packet
            executePacket(packet);

            // Update packet execution status
            packetExecutionStatus[encodePacket(packet)] = ExecutionStatus.Executed;
        }
    }

    /// @notice executeNextPacket executes the next pending packet for a layer zero chain.
    function executeNextPacket(uint16 lzChainId) public {
        // Get next incoming packet
        Packet memory incoming = packetsToChain[lzChainId][0];

        // Execute packet
        executePacket(incoming);
    }

    /// @notice executePacket executes a packet for a layer zero chain.
    function executePacket(Packet memory packet) public {
        // Get packet hash
        bytes32 packetHash = encodePacket(packet);

        // Check if packet has already been executed
        if (packetExecutionStatus[packetHash] == ExecutionStatus.Executed) {
            return;
        }

        // Get Receiving Endpoint in destination chain
        address receivingEndpoint = forkChains[packet.destinationLzChainId].lzEndpoint;

        //Get Application Config for destination User Application
        address receivingLibrary = ILayerZeroEndpoint(receivingEndpoint).getReceiveLibraryAddress(packet.destinationUA);

        //Get adapter params for packet
        AdapterParams memory adapterParams = packetAdapterParams[packetHash];

        //Get gas limit and execute relayer adapter params
        uint256 gasLimit = handleAdapterParams(adapterParams);

        // Acquire gas, Prank into Library and Mock LayerZeroEndpoint.receivePayload call
        vm.deal(receivingLibrary, gasLimit * tx.gasprice);
        vm.prank(receivingLibrary);
        ILayerZeroEndpoint(receivingEndpoint).receivePayload(
            packet.originLzChainId,
            abi.encodePacked(packet.destinationUA, packet.originUA),
            packet.destinationUA,
            packet.nonce,
            gasLimit,
            packet.payload
        );
    }

    /////////////////////////////////
    //          Lz Handlers        //
    /////////////////////////////////

    function handleAdapterParams(AdapterParams memory params) internal returns (uint256 gasLimit) {
        // Save adapter params to memory
        bytes memory adapterParams = params.relayerParams.adapterParams;

        // Check if adapter params are empty
        if (adapterParams.length > 0) {
            // Get adapter Params Version
            uint16 version;
            assembly ("memory-safe") {
                // Load 32 bytes from encodedPacket + mask out remaining 32 - 2 = 30 bytes
                version := shr(240, mload(add(adapterParams, 32)))
            }

            console2.log("Send Library Version: ", version);

            // Serve request according to relayerVersion
            if (version == 1) {
                assembly ("memory-safe") {
                    // Load 32 bytes from adapterParams offsetting the first 2 bytes
                    gasLimit := mload(add(adapterParams, 34))
                }
                console2.log("Gas Limit: ", gasLimit);
            } else if (version == 2) {
                uint256 nativeForDst;
                address addressOnDst;
                assembly ("memory-safe") {
                    // Load 32 bytes from adapterParams offsetting the first 2 bytes
                    gasLimit := mload(add(adapterParams, 34))

                    // Load 32 bytes from adapterParams offsetting the first 34 bytes
                    nativeForDst := mload(add(adapterParams, 66))

                    // Load 32 bytes from adapterParams + mask out remaining 32 - 20 = 12 bytes offsetting the first 66 bytes
                    addressOnDst :=
                        and(
                            mload(add(adapterParams, 86)),
                            0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                        )
                }
                // Send gas airdrop
                console2.log("Gas Limit: ", gasLimit);
                console2.log("Native Receiver on Destination: ", addressOnDst);
                console2.log("Native Amount for Destination: ", nativeForDst);

                console2.log("Sending native token airdrop...");
                deal(address(this), nativeForDst * tx.gasprice);
                addressOnDst.call{value: nativeForDst * tx.gasprice}("");
            }
        } else {
            gasLimit = 200_000;
        }
    }

    /////////////////////////////////
    //          Lz Helpers         //
    /////////////////////////////////

    /// @notice encodePacket creates a 32 byte long keccak256 hash of Packet
    function encodePacket(Packet memory packet) public pure returns (bytes32) {
        return keccak256(abi.encode(packet));
    }

    /// @notice encodePacket creates a 32 byte long keccak256 hash of Packet
    function encodePacket(
        uint64 nonce,
        uint16 originLzChainId,
        address originUA,
        uint16 destinationLzChainId,
        address destinationUA,
        bytes memory payload,
        bytes memory data
    ) public pure returns (bytes32) {
        return
            encodePacket(Packet(nonce, originLzChainId, originUA, destinationLzChainId, destinationUA, payload, data));
    }

    /// @notice decodePacket decodes the encoded packet into a Packet struct
    /// @dev Packet is encodePacked as follows:
    ///       _____________________________________________________________________________________
    ///      | nonce | originLzChainId | originUA | destinationLzChainId | destinationUA | payload |
    ///      |_______|_________________|__________|______________________|_______________|_________|
    ///      |  8    |        2        |    20    |           2          |      20       |   var   |
    ///      |_______|_________________|__________|______________________|_______________|_________|
    function decodePacket(bytes memory encodedPacket)
        internal
        pure
        returns (Packet memory packet, uint16 originLzChainId, uint16 destinationLzChainId)
    {
        //Auxiliary Decoding Vars
        uint256 offset;

        // Packet Vars
        uint64 nonce;
        address originUA;
        address destinationUA;

        encodedPacket = abi.decode(encodedPacket, (bytes));

        assembly ("memory-safe") {
            // Read memory offset
            offset := add(mload(encodedPacket), 32)
            if gt(offset, 63) { offset := 32 }

            // Ignore first 64 bytes of word and byte length. Load first 32 bytes from encodedPacket + mask out remaining 32 - 8 = 24 bytes
            nonce := shr(192, mload(add(encodedPacket, offset)))

            // Ignore first 64 bytes of word and byte length. Load 32 bytes from encodedPacket + mask out remaining 32 - 2 = 30 bytes
            originLzChainId :=
                shr(
                    176,
                    and(
                        mload(add(encodedPacket, offset)),
                        0x0000000000000000ffff00000000000000000000000000000000000000000000
                    )
                )

            // Ignore first 64 bytes of word and byte length. Load 32 bytes from encodedPacket + mask out remaining 32 - 20 = 12 bytes
            originUA :=
                shr(
                    16,
                    and(
                        mload(add(encodedPacket, offset)),
                        0x00000000000000000000ffffffffffffffffffffffffffffffffffffffff0000
                    )
                )

            // Ignore first 64 bytes of word and byte length. Load 32 bytes from encodedPacket + mask out remaining 32 - 2 = 30 bytes
            destinationLzChainId :=
                and(mload(add(encodedPacket, offset)), 0x000000000000000000000000000000000000000000000000000000000000ffff)

            // Ignore first 64 bytes of word and byte length and an additional 20 since 32 + 20 = 52 (header length in bytes). Load 32 bytes from encodedPacket + mask out remaining 32 - 20 = 12 bytes
            destinationUA :=
                and(
                    mload(add(encodedPacket, add(offset, 20))),
                    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                ) // Mask out 32 - 20 bytes
        }

        if (encodedPacket.length > 52) {
            bytes memory payload = bytes(string(encodedPacket).slice(52));

            packet =
                Packet(nonce, originLzChainId, originUA, destinationLzChainId, destinationUA, payload, encodedPacket);
        } else {
            packet = Packet(nonce, originLzChainId, originUA, destinationLzChainId, destinationUA, "", encodedPacket);
        }
    }

    /// @notice plantPacket adds to storage a packet from a layer zero chain.
    /// @param packet the packet to be planted
    function plantPacket(Packet memory packet) public {
        // Get packet hash
        bytes32 packetHash = encodePacket(packet);

        // Check if packet has already been registered
        if (packetExecutionStatus[packetHash] != ExecutionStatus.None) {
            return;
        }

        // Update Packet Execution Status
        packetExecutionStatus[packetHash] = ExecutionStatus.Pending;

        // Update Outgoing Packets
        packetsFromChain[packet.originLzChainId].push(packet);

        // Update Incoming Packets
        packetsToChain[packet.destinationLzChainId].push(packet);
    }

    /// @notice plantPacket adds to storage a packet from a layer zero chain.
    /// @param nonce the nonce of the packet
    /// @param originLzChainId the origin layer zero chain id of the packet
    /// @param originUA the origin user address of the packet
    /// @param destinationLzChainId the destination layer zero chain id of the packet
    /// @param destinationUA the destination user address of the packet
    /// @param payload the payload of the packet
    /// @param data the whole data of the packet
    function plantPacket(
        uint64 nonce,
        uint16 originLzChainId,
        address originUA,
        uint16 destinationLzChainId,
        address destinationUA,
        bytes memory payload,
        bytes memory data
    ) public {
        plantPacket(Packet(nonce, originLzChainId, originUA, destinationLzChainId, destinationUA, payload, data));
    }

    /// @notice setPacketExecutionStatus sets the execution status of a packet.
    /// @param packet the packet to be updated
    /// @param status the execution status to be set
    function setPacketExecutionStatus(Packet memory packet, ExecutionStatus status) public {
        packetExecutionStatus[encodePacket(packet)] = status;
    }

    /// @notice setPacketExecutionStatus sets the execution status of a packet.
    /// @param nonce the nonce of the packet
    /// @param originLzChainId the origin layer zero chain id of the packet
    /// @param originUA the origin user address of the packet
    /// @param destinationLzChainId the destination layer zero chain id of the packet
    /// @param destinationUA the destination user address of the packet
    /// @param payload the payload of the packet
    /// @param data the whole data of the packet
    /// @param status the execution status to be set
    function setPacketExecutionStatus(
        uint64 nonce,
        uint16 originLzChainId,
        address originUA,
        uint16 destinationLzChainId,
        address destinationUA,
        bytes memory payload,
        bytes memory data,
        ExecutionStatus status
    ) public {
        setPacketExecutionStatus(
            Packet(nonce, originLzChainId, originUA, destinationLzChainId, destinationUA, payload, data), status
        );
    }
}
