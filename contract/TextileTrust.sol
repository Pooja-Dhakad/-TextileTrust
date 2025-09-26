// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TextileTrust
 * @dev A blockchain-based supply chain transparency system for the textile industry
 * @author TextileTrust Team
 */
contract TextileTrust {
    
    // Struct to represent a textile product in the supply chain
    struct TextileProduct {
        uint256 productId;
        string productName;
        string materialType;
        address manufacturer;
        address currentOwner;
        uint256 timestamp;
        string[] certifications;
        bool isAuthentic;
        string origin;
        uint256 price;
    }
    
    // Struct to represent a supply chain step
    struct SupplyChainStep {
        address participant;
        string role; // "manufacturer", "supplier", "distributor", "retailer"
        uint256 timestamp;
        string location;
        string action;
        string notes;
    }
    
    // State variables
    mapping(uint256 => TextileProduct) public products;
    mapping(uint256 => SupplyChainStep[]) public productHistory;
    mapping(address => bool) public authorizedParticipants;
    mapping(address => string) public participantRoles;
    
    uint256 private nextProductId;
    address public owner;
    
    // Events
    event ProductRegistered(uint256 indexed productId, string productName, address indexed manufacturer);
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to);
    event SupplyChainStepAdded(uint256 indexed productId, address indexed participant, string action);
    event ParticipantAuthorized(address indexed participant, string role);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedParticipants[msg.sender], "Not an authorized participant");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId < nextProductId, "Product does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        nextProductId = 1;
        
        // Owner is automatically authorized
        authorizedParticipants[owner] = true;
        participantRoles[owner] = "admin";
    }
    
    /**
     * @dev Core Function 1: Register a new textile product in the supply chain
     * @param _productName Name of the textile product
     * @param _materialType Type of material used (cotton, silk, polyester, etc.)
     * @param _origin Origin country/region of the product
     * @param _price Price of the product in wei
     * @param _certifications Array of certifications (organic, fair-trade, etc.)
     */
    function registerProduct(
        string memory _productName,
        string memory _materialType,
        string memory _origin,
        uint256 _price,
        string[] memory _certifications
    ) external onlyAuthorized returns (uint256) {
        
        uint256 productId = nextProductId++;
        
        products[productId] = TextileProduct({
            productId: productId,
            productName: _productName,
            materialType: _materialType,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            timestamp: block.timestamp,
            certifications: _certifications,
            isAuthentic: true,
            origin: _origin,
            price: _price
        });
        
        // Add initial supply chain step
        productHistory[productId].push(SupplyChainStep({
            participant: msg.sender,
            role: participantRoles[msg.sender],
            timestamp: block.timestamp,
            location: _origin,
            action: "Product Manufactured",
            notes: "Initial product registration"
        }));
        
        emit ProductRegistered(productId, _productName, msg.sender);
        emit SupplyChainStepAdded(productId, msg.sender, "Product Manufactured");
        
        return productId;
    }
    
    /**
     * @dev Core Function 2: Transfer product ownership and add supply chain step
     * @param _productId ID of the product to transfer
     * @param _to Address of the new owner
     * @param _location Current location of the product
     * @param _action Description of the action being performed
     * @param _notes Additional notes about the transfer
     */
    function transferProduct(
        uint256 _productId,
        address _to,
        string memory _location,
        string memory _action,
        string memory _notes
    ) external onlyAuthorized productExists(_productId) {
        
        require(products[_productId].currentOwner == msg.sender, "Only current owner can transfer");
        require(authorizedParticipants[_to], "Recipient must be authorized");
        require(_to != msg.sender, "Cannot transfer to yourself");
        
        // Update product ownership
        address previousOwner = products[_productId].currentOwner;
        products[_productId].currentOwner = _to;
        
        // Add supply chain step
        productHistory[_productId].push(SupplyChainStep({
            participant: msg.sender,
            role: participantRoles[msg.sender],
            timestamp: block.timestamp,
            location: _location,
            action: _action,
            notes: _notes
        }));
        
        emit ProductTransferred(_productId, previousOwner, _to);
        emit SupplyChainStepAdded(_productId, msg.sender, _action);
    }
    
    /**
     * @dev Core Function 3: Verify product authenticity and get complete supply chain history
     * @param _productId ID of the product to verify
     * @return product The product details
     * @return history The complete supply chain history
     */
    function verifyProduct(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (TextileProduct memory product, SupplyChainStep[] memory history) 
    {
        return (products[_productId], productHistory[_productId]);
    }
    
    /**
     * @dev Authorize a new participant in the supply chain
     * @param _participant Address of the participant to authorize
     * @param _role Role of the participant (manufacturer, supplier, distributor, retailer)
     */
    function authorizeParticipant(address _participant, string memory _role) external onlyOwner {
        require(!authorizedParticipants[_participant], "Participant already authorized");
        require(_participant != address(0), "Invalid participant address");
        
        authorizedParticipants[_participant] = true;
        participantRoles[_participant] = _role;
        
        emit ParticipantAuthorized(_participant, _role);
    }
    
    /**
     * @dev Get product details by ID
     * @param _productId ID of the product
     * @return TextileProduct struct containing product details
     */
    function getProduct(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (TextileProduct memory) 
    {
        return products[_productId];
    }
    
    /**
     * @dev Get supply chain history for a product
     * @param _productId ID of the product
     * @return Array of SupplyChainStep structs
     */
    function getProductHistory(uint256 _productId) 
        external 
        view 
        productExists(_productId) 
        returns (SupplyChainStep[] memory) 
    {
        return productHistory[_productId];
    }
    
    /**
     * @dev Get total number of registered products
     * @return Total number of products
     */
    function getTotalProducts() external view returns (uint256) {
        return nextProductId - 1;
    }
    
    /**
     * @dev Check if an address is an authorized participant
     * @param _participant Address to check
     * @return Boolean indicating if the address is authorized
     */
    function isAuthorized(address _participant) external view returns (bool) {
        return authorizedParticipants[_participant];
    }
}
