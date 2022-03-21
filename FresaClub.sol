    // SPDX-License-Identifier: MIT  
    pragma solidity >=0.7.0 <0.9.0;

    interface IERC20Token {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    contract Fresaclub {
        // Count of all stores on network.
        uint public storeCount = 0;
        address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

        struct StoreFront {
            address payable owner;
            string store_name;
            string store_image;
            string store_description;
            string store_lat;
            string store_long;
        }

        struct Product {
            address payable owner;
            string name;
            string image;
            string description;     
            uint price;
            uint sold;
            uint index;
            bool active;
        }

        struct Order{
            uint count;
            address customer_addr;
            uint index;
            uint total;
        }

        // Create a mapping to store the storefront information of each address.
        mapping(address => StoreFront) internal storeFronts;
        // Create a mapping to store the products of each address.
        mapping(address => mapping(uint => Product)) internal products;
        // Create a mapping to store the product counts of a given address.
        mapping(address => uint) internal productCount;

        mapping(address => mapping(uint => Order)) internal orders;
        mapping(address => uint) internal orderCount;

        function writeStoreFront(
            string memory _storeName,
            string memory _storeImage,
            string memory _storeDescription,
            string memory _storeLat,
            string memory _storeLong
        ) public {
            if(!readStoreFrontExisits(msg.sender))  storeCount++;

            storeFronts[msg.sender] = StoreFront(
                payable(msg.sender),
                _storeName,
                _storeImage,
                _storeDescription,
                _storeLat,
                _storeLong
            );
        }

        // Add a product the the address mapping and increment product count by one.
        function writeProduct( 
            string memory _name,
            string memory _image,
            string memory _description, 
            uint _price,
            bool _active
        ) public {
            if(readStoreFrontExisits(msg.sender)){
                uint _sold = 0;
                uint _productCount = readProductCount(msg.sender);
                products[msg.sender][_productCount] = Product(
                    payable(msg.sender),
                    _name,
                    _image,
                    _description,
                    _price,
                    _sold,
                    _productCount,
                    _active
                );
                productCount[msg.sender] = _productCount + 1;
            }else{
                revert("A Storefront is required to add product listings.");
            }
        }

        function readStoreFront(address _storeFront) public view returns (
            address payable,
            string memory, 
            string memory, 
            string memory, 
            string memory, 
            string memory,
            uint _totalProducts
        ) {
            address _owner = storeFronts[_storeFront].owner;
            StoreFront memory _sf = storeFronts[_storeFront];
            return (
                _sf.owner, 
                _sf.store_name, 
                _sf.store_image, 
                _sf.store_description,
                _sf.store_lat,
                _sf.store_long,
                readProductCount(_owner)
            );
        }

        function readProduct(address _storeFront, uint _productIndex) public view returns (
            address payable,
            string memory, 
            string memory,  
            string memory, 
            uint,
            bool
        ) {
            Product memory _p = products[_storeFront][_productIndex];
            return (
                _p.owner, 
                _p.name, 
                _p.image, 
                _p.description, 
                _p.price,
                _p.active
            );
        }

        function buyProduct(uint _index, address _addr) public payable  {
            Product memory _p = products[_addr][_index];
            uint _orderCount = orderCount[_p.owner];

            // Add Order to mapping.
            orders[_addr][_orderCount] = Order(
                1,
                msg.sender,
                (_orderCount + 1),
                _p.price
            );

            require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                _p.owner,
                _p.price
            ),
            "Transfer failed."
            );
            _p.sold++;
        }

        function readProductCount(address _storeFront) public view returns(uint){
            return productCount[_storeFront];
        }

        function readStoreFrontExisits(address _storeFront) public view returns(bool){
            return (storeFronts[_storeFront].owner == _storeFront);
        }
        
        function readProductExists(address _storeFront, uint _index) public view returns(bool){
            return (products[_storeFront][_index].owner == _storeFront);
        }
    }