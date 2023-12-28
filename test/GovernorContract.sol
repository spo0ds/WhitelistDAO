// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {OxNft} from "../src/OxNft.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {WhiteList} from "../src/WhiteList.sol";

contract GovernorContractTest is Test {
    OxNft private token;
    TimeLock private timelock;
    GovernorContract private governor;
    WhiteList private whiteList;

    uint256 private constant MIN_DELAY = 3600;

    address[] private proposers;
    address[] private executors;

    address private voter = address(2);

    bytes[] private functionCalls;
    address[] private addressesToCall;
    uint256[] private values;

    function setUp() public {
        token = new OxNft(address(1));
        vm.prank(voter);
        token.safeMint();
        vm.prank(voter);
        token.delegate(voter);

        timelock = new TimeLock(MIN_DELAY, proposers, executors);

        governor = new GovernorContract(token, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));

        vm.prank(address(5));
        whiteList = new WhiteList();
        vm.prank(address(5));
        whiteList.transferOwnership(address(timelock));
    }

    function testCantWhiteListWithoutGovernance() public {
        vm.expectRevert();
        whiteList.whitelistAddress(address(3));
    }

    function testGovernanceWhiteListAddress() public {
        string
            memory description = "Contract is verified as well as it's audited";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "whitelistAddress(address)",
            address(6)
        );
        addressesToCall.push(address(whiteList));
        values.push(0);
        functionCalls.push(encodedFunctionCall);

        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        vm.warp(block.timestamp + 7200 + 1);
        vm.roll(block.number + 7200 + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        string memory reason = "Yes, the contract is indeed verified";
        uint8 voteWay = 1;
        vm.prank(voter);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + 50400 + 1);
        vm.roll(block.number + 50400 + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(whiteList.isAddressWhitelisted(address(6)) == true);
    }

    function testCantWhiteListAddressWithLowVote() public {
        string memory description = "Contract is not verified";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "whitelistAddress(address)",
            address(8)
        );
        addressesToCall.push(address(whiteList));
        values.push(0);
        functionCalls.push(encodedFunctionCall);

        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        vm.warp(block.timestamp + 7200 + 1);
        vm.roll(block.number + 7200 + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        string memory reason = "Yes, the contract is verified";
        uint8 voteWay = 1;

        vm.prank(voter);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        reason = "No, the contract is not verified";
        voteWay = 0;

        for (uint256 i = 0; i < 10; i++) {
            address voterAddress = address(uint160(i + 10)); // Correct way to convert uint256 to address
            vm.prank(voterAddress);
            token.safeMint();
            vm.prank(voterAddress);
            token.delegate(voterAddress);
            vm.prank(voterAddress);
            governor.castVoteWithReason(proposalId, voteWay, reason);
        }

        vm.warp(block.timestamp + 50400 + 1);
        vm.roll(block.number + 50400 + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);

        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        vm.expectRevert();
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(whiteList.isAddressWhitelisted(address(8)) == false);
    }
}
