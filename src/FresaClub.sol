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
        uint private fresaStoreCount;
        uint private fresaProductCount;
        uint private fresaSaleCount;

        address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

        struct StoreFront {
            bool store_active; // whether or not this store is currently trading on the fresa platform.
            address payable owner;
            string store_name; // The trading name of the storefront.
            string store_image; // A Profile picture for the storefront.
            string store_description; // A short description of the storefront.
            string store_lat; // The latitude of the storefront
            string store_long; // The Longitude of the storefront.
        }

        mapping(address => StoreFront) internal storeFronts;
        mapping(uint => address) internal storeFrontsIndex;

        // modifier to check if store exists
        modifier readStoreFrontExists(address _storeFront) {
            require (storeFronts[_storeFront].owner == _storeFront, 
                "No Fresa Storefront was found at this address."    
            );
            _;
        }
        modifier readStoreFrontExistsByIndex(uint _index){
            address _add = storeFrontsIndex[_index];
            require (storeFronts[_add].owner == _add, 
                "No Fresa Storefront was found at this address."    
            );
            _;
        }

        function writeStoreFront(
            string memory _storeName, 
            string memory _storeImage,  
            string memory _storeDescription, 
            string memory _storeLat, 
            string memory _storeLong, 
            bool _storeActive 
        ) public {
            if (storeFronts[msg.sender].owner != msg.sender){
                storeFrontsIndex[fresaStoreCount] = msg.sender;
                fresaStoreCount++;
            }

            require (bytes(_storeName).length > 0 && bytes(_storeImage).length > 0 && bytes(_storeDescription).length > 0,
                "A Fresa storefront can not be created without a name, description & image."    
            );
            storeFronts[msg.sender] = StoreFront(
                _storeActive,
                payable(msg.sender),
                _storeName,
                _storeImage,
                _storeDescription,
                _storeLat,
                _storeLong
            );
        }

        function readStoreFrontAtIndex(uint _index) public view readStoreFrontExistsByIndex(_index) returns(
            address payable,
            string memory storeName, 
            string memory storeImage, 
            string memory storeDescription, 
            string memory storeLat, 
            string memory storeLong,
            bool _storeActive,
            uint _totalProducts
        ){
            address _sfbi = storeFrontsIndex[_index];
            StoreFront memory _sf = storeFronts[_sfbi];
            return (
                _sf.owner, 
                _sf.store_name, 
                _sf.store_image, 
                _sf.store_description,
                _sf.store_lat,
                _sf.store_long,
                _sf.store_active,
                readProductCount(_sf.owner)
            );
        }

        function readStoreFront(address _storeFront) public view readStoreFrontExists(msg.sender) returns (
            address payable,
            string memory storeName, 
            string memory storeImage, 
            string memory storeDescription, 
            string memory storeLat, 
            string memory storeLong,
            bool _storeActive,
            uint _totalProducts
        ) {
            StoreFront memory _sf = storeFronts[_storeFront];
            return (
                _sf.owner, 
                _sf.store_name, 
                _sf.store_image, 
                _sf.store_description,
                _sf.store_lat,
                _sf.store_long,
                _sf.store_active,
                readProductCount(_sf.owner)
            );
        }

        struct Product {
            address payable owner;
            bool active;
            string name;
            string image;
            string description;     
            uint price;
            uint qty;
            uint sold;
            uint index;
        }


        mapping(address => mapping(uint => Product)) internal products;
        mapping(address => uint) internal productCount;
 
        function writeProduct( 
            string memory _name,
            string memory _image,
            string memory _description, 
            uint _price,
            uint _qty,
            bool _active
        ) public readStoreFrontExists(msg.sender) {
            require (bytes(_name).length > 0 && bytes(_image).length > 0 && bytes(_description).length > 0 && _price > 0,
                "A name, description, image and valid price is required to add a product to your storefront."
            );
            uint _sold;
            uint _productCount = readProductCount(msg.sender);
            products[msg.sender][_productCount] = Product(
                payable(msg.sender),
                _active,
                _name,
                _image,
                _description,
                _price,
                _qty,
                _sold,
                _productCount // Where this image will sit in the dataset.
            );
            productCount[msg.sender] = _productCount + 1;
            fresaProductCount++;
        }

        function editProduct(
            uint _index,
            string memory _name,
            string memory _image,
            string memory _description, 
            uint _price,
            uint _qty,
            bool _active
        ) public readProductExists(msg.sender, _index) {
            Product memory _temp = products[msg.sender][_index];
            products[msg.sender][_index] = Product(
                payable(msg.sender),
                _active,
                _name,
                _image,
                _description,
                _price,
                _qty,
                _temp.sold,
                _index
            );
        }

        function readProduct(address _storeFront, uint _productIndex) public view readProductExists(_storeFront, _productIndex) 
        returns (
            address payable,
            string memory productName,
            string memory productImage,  
            string memory productDescription, 
            uint productPrice,
            uint productSold,
            uint productQty,
            bool productActive
        ) {
            Product memory _p = products[_storeFront][_productIndex];
            return (
                _p.owner, 
                _p.name, 
                _p.image, 
                _p.description, 
                _p.price,
                _p.sold,
                _p.qty,
                _p.active
            );
        }

        // function readProductExists(address _storefront, uint _index) public view returns(bool productExists){
        //     return (products[_storefront][_index].owner == _storefront);
        // }
        modifier readProductExists(address _storefront, uint _index) {
            require (products[_storefront][_index].owner == _storefront, 
                "No product found in storefront of given address with index provided."
            );
            _;
        }

        function readProductStock(address _storefront, uint _index) private view returns(uint _stockCount){
            return (products[_storefront][_index].qty);
        }

        function validateItemPrice(address _storeFront, uint _index, uint _price) private view returns(bool _validate){
            return (products[_storeFront][_index].price == _price);
        }

        function readProductCount(address _storeFront) public view readStoreFrontExists(msg.sender) returns(uint storeProductCount){
                return productCount[_storeFront];
        }

        struct OrderItem {
            string ProductName;
            uint Quantity;
            uint CusdValue;
            address Storefront;
            uint index;
        }

        struct Order {
            address payable Storefront;
            uint OrderID;
            uint TotalItems;
            uint TotalValue;
            uint Timestamp;
            address CustomerAddress;
        }

        // Vendor -> Order ID
        mapping(address => mapping(uint => Order)) internal orders;

        // Vendor -> Order Items
        mapping(address => mapping(uint => mapping(uint => OrderItem))) internal orderItems;

        // Vendor -> Order Count
        mapping(address => uint) internal orderCount;
        
        function writeOrder(address payable _storefront, OrderItem[] memory _items) public payable{
            // Create Order Items.
            uint _totalValue;
            uint _orderCount = orderCount[_storefront];

            if(_items.length == 0) revert("You have no items in your order, consider adding some before checking out?");

            // Loop through order items and check each item is valid.
            for(uint i; i<_items.length; ++i){
                if(validateOrderItem(_items[i])){
                    _totalValue += _items[i].CusdValue;
                    orderItems[_storefront][_orderCount][i] = OrderItem(
                        _items[i].ProductName,
                        _items[i].Quantity,
                        _items[i].CusdValue,
                        _items[i].Storefront,
                        _items[i].index
                    );
                    uint _stock = products[_storefront][_items[i].index].qty;
                    uint _sold = products[_storefront][_items[i].index].sold;
                    products[_storefront][_items[i].index].qty = _stock - _items[i].Quantity;
                    products[_storefront][_items[i].index].sold = _sold + _items[i].Quantity;
                }else{
                    revert("A item in your order failed validity checks, please check your order and try again.");
                }
            } 
            
            orders[_storefront][_orderCount] = Order(
                _storefront,
                _orderCount,
                _items.length,
                _totalValue,
                block.timestamp,
                msg.sender
            );

            // Increment Order Counts.
            fresaSaleCount++;
            orderCount[_storefront] = _orderCount + 1;

            require(
                IERC20Token(cUsdTokenAddress).transferFrom(
                    msg.sender,
                    _storefront,
                    _totalValue
                ),
                "Transfer for order has failed, please check your Cusd balance and try again."
            );
        }

        function readOrder(address _customer, uint _orderid) public view returns(
            uint OrderId,
            uint TotalItems,
            uint TotalValue,    
            uint Timestamp,
            address customerAddress
        ){
            return(
                orders[_customer][_orderid].OrderID,
                orders[_customer][_orderid].TotalItems,
                orders[_customer][_orderid].TotalValue,
                orders[_customer][_orderid].Timestamp,
                orders[_customer][_orderid].CustomerAddress
            );
        }


        function readOrderItems(address _customer, uint _orderid, uint _itemid) public view returns(
            string memory _productName,
            uint _Quantity,
            uint _CusdValue,
            address _StoreFront,
            uint _productIndex 
        ){
            return(
                orderItems[_customer][_orderid][_itemid].ProductName,
                orderItems[_customer][_orderid][_itemid].Quantity,
                orderItems[_customer][_orderid][_itemid].CusdValue,
                orderItems[_customer][_orderid][_itemid].Storefront,
                orderItems[_customer][_orderid][_itemid].index
            );
        }

        function validateOrderItem(OrderItem memory _orderItem) private view returns(bool _valid){
            // Validate Product Exists
            // if(!readProductExists(_orderItem.Storefront, _orderItem.index)) return false;
            require (!(products[_orderItem.Storefront][_orderItem.index].owner == _orderItem.Storefront));

            // Validate Product In Stock
            if(readProductStock(_orderItem.Storefront, _orderItem.index) < _orderItem.Quantity) return false;

            // Validate Vendor Active
            if(!storeFronts[_orderItem.Storefront].store_active) return false;

            // Validate Product Price
            if(!validateItemPrice(_orderItem.Storefront, _orderItem.index, _orderItem.CusdValue)) return false;

            return true;
        }

        // Fresa Network Stats.
        function readFresaStoreCount() public view returns(uint NetworkStoreCount){
            return fresaStoreCount;
        }

        function readFresaProductCount() public view returns(uint NetworkProductCount){
            return fresaProductCount;
        }

        function readFresaSaleCount() public view returns(uint NetworkSaleCount){
            return fresaSaleCount;
        }
    }
