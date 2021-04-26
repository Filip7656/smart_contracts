
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './QueueImpl.sol';
import 'https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol';

import './IERC20.sol';

contract CurrencyPair   {
    address admin;
    address tokenA;
    address tokenB;
    IERC20 tokenAI;
    IERC20 tokenBI;
    uint decimals = 10**6;
    IUniswapV2Pair uniswapTokenPair;
    Queue public buyers;
    Queue public sellers;
    uint lastQuoteTimestamp;
    mapping (address => uint) public balanceOf;
    mapping (address => uint) public reserves;
    mapping (address => mapping(address => uint)) public tokenPendingWithdrawals;
    
    constructor() {
        admin = msg.sender;
    }
      
    function initialize(address _tokenA, address _tokenB, address uniswapToken) external {
        require(msg.sender == admin, 'FORBIDDEN'); // sufficient check
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenAI = IERC20(tokenA);
        tokenBI = IERC20(tokenB);
        uniswapTokenPair = IUniswapV2Pair(uniswapToken);
        buyers = new Queue();
        sellers = new Queue();
    }
    
    function getRate() public view returns(uint rate) {
      (uint reserver0, uint reserver1, uint timestamp ) = getUniswapReserver();
      rate = (reserver0*decimals)/reserver1;
    }
    
    function getUniswapReserver() public view returns(uint reserve0, uint reserve1, uint timestamp) {
      ( reserve0,  reserve1,  timestamp )= uniswapTokenPair.getReserves();
    }
    
    function addSellerWithAmount(address token, uint amount) public payable {
        sellers.enqueue(msg.sender);
        balanceOf[msg.sender] += amount;
        reserves[token] += amount;
        uint tokenAllowance = IERC20(token).allowance(msg.sender, address(this));
        require(tokenAllowance > msg.value, "TO SMALL ALLOWANCE");
        IERC20(token).transferFrom(msg.sender,address(this),amount);
    }
 
    function addBuyer(address token, uint amount) public payable{
        buyers.enqueue(msg.sender);
        balanceOf[msg.sender] += msg.value;
        reserves[token] += msg.value;
        uint balance = IERC20(token).balanceOf(address(this));
        require(balance > amount, "Not enough liquidity");
        
        uint tokenAllowance = IERC20(token).allowance(msg.sender, address(this));
        require(tokenAllowance > msg.value, "TO SMALL ALLOWANCE");
        IERC20(token).transferFrom(msg.sender,address(this),amount);
    }
    
    // buying tokenX with tokenY 
    // suppose we have buyer wanting to exchange 200 TokenA to X TokenB
    // so we need to transfer 200 TokenA to Seller account and from Seller account tranfer 200*rate TokenB
    // 
    function buyTokenA(address token) public payable {
        uint currentRate = getRate();
        uint amountToTransfer = 0;
        if(token == tokenB){
             amountToTransfer = (msg.value / currentRate) * decimals;
             require(reserves[tokenA] > amountToTransfer, "NOT sufficient reserves TOKEN A");
        }
        else {
             amountToTransfer = (msg.value * currentRate) / decimals;
             require(reserves[tokenB] > amountToTransfer, "NOT sufficient reserves TOKEN B");
        }
       
        address seller = sellers.dequeue();
        if(balanceOf[seller] > amountToTransfer){
            balanceOf[seller] -= amountToTransfer;
            tokenPendingWithdrawals[token][msg.sender] += amountToTransfer;
            tokenPendingWithdrawals[tokenB][seller] += msg.value;
        }
        else{
            
        }
    }
    
    function getRateForAmount(address token, uint amount) public view returns (uint rate){
        uint currentRate = getRate();
        if(token == tokenB){
              rate = (amount * decimals) / currentRate ;
        }else {
             rate = (amount * currentRate) / decimals;
        }
    }
  
    function withdraw(address token) public {
          uint amount = tokenPendingWithdrawals[token][msg.sender];
          tokenPendingWithdrawals[token][msg.sender] = 0;
          IERC20(token).transfer(msg.sender,amount);
   }
}

