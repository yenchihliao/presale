// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

contract Presale is
    Initializable,
    UUPSUpgradeable,
    ERC721AQueryableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    string public uri;
    uint256 public supplyLimit;
    uint256 public batchMintLimit;
    uint256 public tokenPrice;
    address public paymentContract;

    event BatchMinted(uint256 quantity, uint256 startIndex);
    event WithdrawnFromToken(address token, address to, uint256 amount);
    event Withdrawn(address to, uint256 amount);

    error ExceedBatchMintLimit();
    error ExceedTokenSupplyLimit();
    error InValidPaymentContract();

    function initialize(
        string memory newName,
        string memory newSymbol,
        address newAdmin,
        uint256 _tokenPrice
    ) public initializerERC721A initializer {
        __ERC721A_init(newName, newSymbol);
        __ERC721AQueryable_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        tokenPrice = _tokenPrice;

        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function emergencyPause() public onlyRole(DEFAULT_ADMIN_ROLE) {
      _pause();
    }

    function emergencyUnpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
      _unpause();
    }

    function setPaymentContract(address _paymentContract)
        external
        onlyRole(SETTER_ROLE)
    {
        if (
            _paymentContract == address(0) ||
                !_paymentContract.isContract()
        ) {
            revert InValidPaymentContract();
        }
        paymentContract = _paymentContract;
    }
    function setURI(string calldata _uri)
        public
        onlyRole(SETTER_ROLE)
    {
        uri = _uri;
    }

    function setSupplyLimit(uint256 _supplyLimit)
        public
        onlyRole(SETTER_ROLE)
    {
        supplyLimit = _supplyLimit;
    }

    function setBatchMintLimit(uint256 _batchMintLimit)
        public
        onlyRole(SETTER_ROLE)
    {
        batchMintLimit = _batchMintLimit;
    }

    function setTokenPrice(uint256 _tokenPrice)
        public
        onlyRole(SETTER_ROLE)
    {
        tokenPrice = _tokenPrice;
    }

    // @dev: user function
    function mint() external nonReentrant {
        // _checkToken(uuid, userAddress, deadline, level, uri, signature);
        uint256 amount = _mint(1);
        IERC20Upgradeable(paymentContract)
            .safeTransferFrom(_msgSender(), address(this), amount);
    }

    // @dev admin function
    function batchMint(
        uint256 quantity
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        _mint(quantity);
    }

    function withdrawFromToken(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(WITHDRAWER_ROLE) {
        emit WithdrawnFromToken(token, to, amount);
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
    function withdraw(
        address payable to,
        uint256 amount
    ) external onlyRole(WITHDRAWER_ROLE) {
        emit Withdrawn(to, amount);
        to.transfer(amount);
    }

    function tokenListOfOwner(
        address owner,
        uint256 page,
        uint256 pageSize
    ) external view returns (uint256[] memory) {
        uint256 startIndex = (page - 1) * pageSize;
        uint256 endIndex = page * pageSize;
        uint256 balance = balanceOf(owner);
        if (startIndex >= balance) {
            return new uint256[](0);
        }
        if (balance < endIndex) {
            endIndex = balance;
        }

        return this.tokensOfOwnerIn(owner, startIndex, endIndex);
    }

    function _mint(uint256 quantity)
        internal
        returns (uint256)
    {
        uint256 originalSupply = totalSupply();
        if(quantity > batchMintLimit) revert ExceedBatchMintLimit();
        if(originalSupply + quantity > supplyLimit) revert ExceedTokenSupplyLimit();
        _safeMint(msg.sender, quantity);
        emit BatchMinted(quantity, originalSupply);

        return tokenPrice * quantity;
    }
}

