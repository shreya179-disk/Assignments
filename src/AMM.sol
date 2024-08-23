// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AMM  is  ReentrancyGuard,Ownable{
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint public reserveA;
    uint public reserveB;

    uint public feePercent;
    mapping(address => uint256) public accumulatedFees;

    struct UserLiquidity{
        uint amountA;
        uint amountB;
    }

    mapping( address => UserLiquidity) public userLiquidity;

    constructor(IERC20 _tokenA, IERC20 _tokenB, address initialOwner,  uint _feePercent) Ownable(initialOwner) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        setFeePercent(_feePercent);
    }

    function setFeePercent(uint _feePercent) public onlyOwner{
        require (_feePercent <= 100, "fee is too high");
        feePercent = _feePercent;
    }

    function addLiquidity(uint amountA, uint amountB) external nonReentrant{
        require(amountA > 0 && amountB > 0, "Amount added should be greater than zero");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;
        
        userLiquidity[msg.sender].amountA += amountA;
        userLiquidity[msg.sender].amountB += amountB;
    
    }

    function removeLiquidty(uint amount)  external nonReentrant{
        require(amount > 0, "amount must be greater than zero");
        require(amount <= userLiquidity[msg.sender].amountA  && amount <= userLiquidity[msg.sender].amountB, "Insufficient funds");
        require(amount < reserveA && amount < reserveB, "Insufficient reserves");
        
        uint amountA = (amount * reserveA)/reserveB;
        uint amountB = (amount * reserveB)/reserveA;

        reserveA -= amountA;
        reserveB -= amountB;

        userLiquidity[msg.sender].amountA -= amountA;
        userLiquidity[msg.sender].amountB -= amountB;
       
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

    }
    

    function getReserveA() external view returns (uint256) {
        return reserveA;
    }

    function getReserveB() external view returns (uint256) {
        return reserveB;
    }

    function getAmountOut(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }
    
    function withdrawFees(address token) external onlyOwner nonReentrant {
        require(token == address(tokenA) || token == address(tokenB), "Invalid token address");

        uint256 feestokenA = accumulatedFees[address(tokenA)];
        uint256 feestokenB = accumulatedFees[address(tokenB)];

        require(feestokenA > 0 || feestokenB > 0 , "No fees to withdraw");

        if (feestokenA > 0) {
            accumulatedFees[address(tokenA)] = 0;
            tokenA.transfer(msg.sender, feestokenA);
        }
        if (feestokenB > 0) {
            accumulatedFees[address(tokenB)] = 0;
            IERC20(token).transfer(msg.sender, feestokenB);
        }
    
    }

    function getAccumulatedFees(address token) external view onlyOwner returns (uint256) {
        return accumulatedFees[token];
    }

    function swap(address inputToken, uint256 inputAmount, uint256 minOutputAmount) external nonReentrant {
    require(inputAmount > 0, "Input amount must be greater than zero");
    require(inputToken == address(tokenA) || inputToken == address(tokenB), "Invalid token address");

    (IERC20 input, IERC20 output, uint256 reserveInput, uint256 reserveOutput) = inputToken == address(tokenA)
        ? (tokenA, tokenB, reserveA, reserveB)
        : (tokenB, tokenA, reserveB, reserveA);

    input.transferFrom(msg.sender, address(this), inputAmount);

    uint256 inputAmountWithFee = inputAmount * (10000 - feePercent) / 10000;
    uint256 outputAmount = getAmountOut(inputAmountWithFee, reserveInput, reserveOutput);

    require(outputAmount >= minOutputAmount, "Slippage too high");

    accumulatedFees[address(input)] += inputAmount - inputAmountWithFee;

    reserveInput += inputAmountWithFee;
    reserveOutput -= outputAmount;

    if (inputToken == address(tokenA)) {
        reserveA = reserveInput;
        reserveB = reserveOutput;
    } else {
        reserveB = reserveInput;
        reserveA = reserveOutput;
    }

    output.transfer(msg.sender, outputAmount);
    }
   
    
}