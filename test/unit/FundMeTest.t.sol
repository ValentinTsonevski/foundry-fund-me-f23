// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 10e18 or 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //giving user some fake money
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
     uint256 version = fundMe.getVersion();
     assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughtETH() public {
        vm.expectRevert(); //the next line should revert
        // assert transaction fails/revert
        fundMe.fund(); //send 0
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 ammountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(ammountFunded,SEND_VALUE);
    }

   function testAddFunderToArrayOfFunders() public funded {
    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
   } 

   modifier funded() {
    vm.prank(USER); // the next transaction will be sent by USER
    fundMe.fund{value: SEND_VALUE}();
    _;
   }

   function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert(); // expection fundMe.withdraw() to revert /// ignores other vm.'s
    vm.prank(USER);
    fundMe.withdraw();
   }

   function testWithdrawWithSingleFunder() public funded {
    //arange
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

   //act 
   vm.prank(fundMe.getOwner());
   fundMe.withdraw();

  //assert
  uint256 endingOwnerBalance = fundMe.getOwner().balance;
  uint256 endingFundMeBalance = address(fundMe).balance;
  assertEq(endingFundMeBalance,0);
  assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance);
   }

   function testWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 1;

    for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
     hoax(address(i), SEND_VALUE);
     fundMe.fund{value: SEND_VALUE}();
    }
    // arrange
     uint256 endingOwnerBalance = fundMe.getOwner().balance;
     uint256 endingFundMeBalance = address(fundMe).balance;

    
     //act
     vm.prank(fundMe.getOwner());
     fundMe.withdraw();  

     //assert
     uint256 startingOwnerBalance = fundMe.getOwner().balance;
     uint256 startingFundMeBalance = address(fundMe).balance;
    
     assert(address(fundMe).balance == 0);
     assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
   }

}
