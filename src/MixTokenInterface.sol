pragma solidity ^0.5.12;


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
    function getAccountAuthorized(address account, address accountToCheck) external view returns (bool);
    function getAccountCount() external view returns (uint);
    function getAccounts() external view returns (address[] memory);
    function getAccountBalances() external view returns (address[] memory accounts, uint[] memory balances);
    // ERC165
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface MixTokenOwnedInterface {
    function owner() external view returns (address);
    // MixTokenInterface
    function transfer(address to, uint value) external returns (bool success);
    function transferFrom(address from, address to, uint value) external returns (bool success);
    function authorize(address account) external;
    function unauthorize(address account) external;
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function getAccountAuthorized(address account, address accountToCheck) external view returns (bool);
    function getAccountCount() external view returns (uint);
    function getAccounts() external view returns (address[] memory);
    function getAccountBalances() external view returns (address[] memory accounts, uint[] memory balances);
    // ERC165
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract MixTokenInterfaceId {

    function getInterfaceId() external pure returns (bytes4) {
        MixTokenInterface i;
        return i.transfer.selector ^
            i.transferFrom.selector ^
            i.authorize.selector ^
            i.unauthorize.selector ^
            i.symbol.selector ^
            i.name.selector ^
            i.decimals.selector ^
            i.totalSupply.selector ^
            i.balanceOf.selector ^
            i.getAccountAuthorized.selector ^
            i.getAccountCount.selector ^
            i.getAccounts.selector ^
            i.getAccountBalances.selector;
    }

}
