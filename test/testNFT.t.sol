// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Oxy} from "../src/OxNft.sol";
import {Test} from "forge-std/Test.sol";

error NTNFT__CanOnlyMintOnce();
error NTNFT__NotNFTOwner();
error NTNFT__NftNotTransferrable();

contract testNFT is Test {
    Oxy public oxy;
    address owner = address(1);

    function setUp() external {
        oxy = new Oxy(owner);
    }

    function test_WhenAOwnerCallsPause_and_UnPause() external {
        // it should pause all token and voting actions.
        vm.startPrank(owner);
        oxy.pause();
        vm.stopPrank();

        vm.startPrank(owner);
        oxy.unpause();
        vm.stopPrank();
    }

    function test_RevertWhen_ANon_ownerCallsPause() external {
        vm.startPrank(address(2));
        vm.expectRevert();
        oxy.pause();
        vm.stopPrank();
    }

    modifier givenTheContractIsPaused() {
        vm.startPrank(owner);
        oxy.pause();
        _;
    }

    function test_WhenAUserCallsSafeMint() external {
        vm.startPrank(address(2));
        oxy.safeMint();
        vm.stopPrank();
    }

    function test_RevertWhenAUserCallsSafeMintTwice() external {
        // it should revert with NTNFTCanOnlyMintOnce error
        vm.startPrank(address(2));
        oxy.safeMint();
        vm.expectRevert(NTNFT__CanOnlyMintOnce.selector);
        oxy.safeMint();
        vm.stopPrank();
    }

    function test_RevertWhen_AUserCallsSafeMintInPausedState()
        external
        givenTheContractIsPaused
    {
        vm.startPrank(address(3));
        vm.expectRevert();
        oxy.safeMint();
        vm.stopPrank();
    }

    function test_WhenAUserBurnTheirNft() external {
        assertEq(oxy.getTokenId(), 0);
        vm.startPrank(address(2));
        oxy.safeMint();
        assertEq(oxy.getTokenId(), 1);
        oxy.burn(0);
        vm.stopPrank();
    }

    function testFail_WhenTokenIdIsNotPresent() external {
        vm.startPrank(address(2));
        uint256 prevTokenId = oxy.getTokenId();
        oxy.safeMint();
        oxy.burn(prevTokenId);
        oxy.safeMint();
        oxy.burn(prevTokenId);
        vm.stopPrank();
    }

    function test_WhenANon_ownerCallsBurn() external {
        // it should revert with NTNFTNotNFTOwner error
        vm.startPrank(address(1));
        uint256 prevTokenId = oxy.getTokenId();
        oxy.safeMint();
        vm.startPrank(address(2));
        vm.expectRevert(NTNFT__NotNFTOwner.selector);
        oxy.burn(prevTokenId);
        vm.stopPrank();
    }

    function test_RevertWhen_TheOwnerCallsBurnInPaused()
        external
        givenTheContractIsPaused
    {
        vm.startPrank(address(3));
        vm.expectRevert();
        oxy.burn(0);
        vm.stopPrank();
    }

    function test_RevertWhen_NftOwnerCallTransfer() external {
        vm.startPrank(address(0xabc));
        oxy.safeMint();
        vm.expectRevert(NTNFT__NftNotTransferrable.selector);
        oxy.transferFrom(address(0xabc), address(4), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_NftOwnerCallApproval() external {
        vm.startPrank(address(0xbcd));
        oxy.safeMint();
        vm.expectRevert(NTNFT__NftNotTransferrable.selector);
        oxy.isApprovedForAll(address(0xbcd), address(2));
        vm.stopPrank();
    }
}
