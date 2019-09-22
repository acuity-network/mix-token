pragma solidity ^0.5.11;


interface MixTokenInterface {
    function transfer(address to, uint value) external returns (bool success);
    function transferFrom(address from, address to, uint value) external returns (bool success);
    function authorize(address account) external;
    function unauthorize(address account) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function getAccountCount() external view returns (uint);
    function getAccounts() external view returns (address[] memory);
    function getAccountBalances() external view returns (address[] memory accounts, uint[] memory balances);
}
