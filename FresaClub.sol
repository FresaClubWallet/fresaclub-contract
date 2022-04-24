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
        uint private fresaStoreCount = 0;
        uint private fresaProductCount = 0;
        uint private fresaSaleCount = 0;

        address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

        struct StoreFront {
            address payable owner;
            string store_name; // The trading name of the storefront.
            string store_image; // A Profile picture for the storefront.
            string store_description; // A short description of the storefront.
            string store_lat; // The latitude of the storefront
            string store_long; // The Longitude of the storefront.
            bool store_active; // whether or not this store is currently trading on the fresa platform.
        }

        mapping(address => StoreFront) internal storeFronts;

        function writeStoreFront(
            string memory _storeName, 
            string memory _storeImage,  
            string memory _storeDescription, 
            string memory _storeLat, 
            string memory _storeLong, 
            bool _storeActive 
        ) public {
            if(!readStoreFrontExisits(msg.sender))  fresaStoreCount++; 

            if(bytes(_storeName).length > 0 && bytes(_storeImage).length > 0 && bytes(_storeDescription).length > 0){
                storeFronts[msg.sender] = StoreFront(
                    payable(msg.sender),
                    _storeName,
                    _storeImage,
                    _storeDescription,
                    _storeLat,
                    _storeLong,
                    _storeActive
                );
            }else{
                revert("A Fresa storefront can not be created without a name, description & image.");
            }
        }

        function readStoreFrontExisits(address _storeFront) public view returns(bool){
            return (storeFronts[_storeFront].owner == _storeFront);
        }

        function readStoreFront(address _storeFront) public view returns (
            address payable,
            string memory storeName, 
            string memory storeImage, 
            string memory storeDescription, 
            string memory storeLat, 
            string memory storeLong,
            bool _storeActive,
            uint _totalProducts
        ) {
            if(readStoreFrontExisits(_storeFront)){
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
            }else{
                revert("No Fresa Storefront was found at this address.");
            }
        }

        struct Product {
            address payable owner;
            string name;
            string image;
            string description;     
            uint price;
            uint qty;
            uint sold;
            uint index;
            bool active;
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
        ) public {
            if(readStoreFrontExisits(msg.sender) ){
                if(bytes(_name).length > 0 && bytes(_image).length > 0 && bytes(_description).length > 0 && _price > 0){
                    uint _sold = 0;
                    uint _productCount = readProductCount(msg.sender);
                    products[msg.sender][_productCount] = Product(
                        payable(msg.sender),
                        _name,
                        _image,
                        _description,
                        _price,
                        _qty,
                        _sold,
                        _productCount, // Where this image will sit in the dataset.
                        _active
                    );
                    productCount[msg.sender] = _productCount + 1;
                }else{
                    revert("A name, description, image and valid price is required to add a product to your storefront.");
                }
            }else{
                revert("A Storefront is required to add product listings.");
            }
        }

        function editProduct(
            uint _index,
            string memory _name,
            string memory _image,
            string memory _description, 
            uint _price,
            uint _qty,
            bool _active
        ) public{
            if(readProductExists(msg.sender, _index)){
                Product memory _temp = products[msg.sender][_index];
                products[msg.sender][_index] = Product(
                    payable(msg.sender),
                    _name,
                    _image,
                    _description,
                    _price,
                    _qty,
                    _temp.sold,
                    _index,
                    _active
                );  
            }else{
                revert("No product with the given index was found at this Fresa storefront.");
            }
        }

        function readProduct(address _storeFront, uint _productIndex) public view returns (
            address payable,
            string memory productName,
            string memory productImage,  
            string memory productDescription, 
            uint productPrice,
            uint productSold,
            uint productQty,
            bool productActive
        ) {
            if(readProductExists(_storeFront, _productIndex)){
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
            }else{
                revert("No product found in storefront of given address with index provided.");
            }
        }

        function readProductExists(address _storefront, uint _index) public view returns(bool productExists){
            return (products[_storefront][_index].owner == _storefront);
        }

        function readProductStock(address _storefront, uint _index) private view returns(uint _stockCount){
            return (products[_storefront][_index].qty);
        }

        function validateItemPrice(address _storeFront, uint _index, uint _price) private view returns(bool _validate){
            return (products[_storeFront][_index].price == _price);
        }

        function readProductCount(address _storeFront) public view returns(uint storeProductCount){
            if(readStoreFrontExisits(_storeFront) ){
                return productCount[_storeFront];
            }else{
                revert("No fresa storefront found at provided address.");
            }
        }

        struct Favourite{
            address payable owner;
            address storefront;
        }

        mapping(address => mapping(uint => Favourite)) internal favourites;
        mapping(address => uint) internal favouriteCount;

        function writeFavourite(address _storefront) public{
            uint _favCount = readFavouriteCount(payable(msg.sender));

            favourites[msg.sender][_favCount] = Favourite(
                payable(msg.sender),
                _storefront
            );
            favouriteCount[_storefront]++;
        }

        function readFavouriteCount(address payable _storeFront) public view returns(uint FavouriteCount){
            return favouriteCount[_storeFront];
        }

        function readFavourite(uint index) public view returns(
            address storefront
        ){
            return favourites[msg.sender][index].storefront;
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
        
        function writeOrder(address payable _storefront, OrderItem[] memory _items) public{
            // Create Order Items.
            uint _totalValue = 0;
            uint _orderCount = orderCount[_storefront];

            if(_items.length == 0) revert("You have no items in your order, consider adding some before checking out?");

            // Loop through order items and check each item is valid.
            for(uint i=0; i<_items.length; i++){
                if(validateOrderItem(_items[i])){
                    _totalValue += _items[i].CusdValue;
                    orderItems[_storefront][_orderCount][i] = OrderItem(
                        _items[i].ProductName,
                        _items[i].Quantity,
                        _items[i].CusdValue,
                        _items[i].Storefront,
                        _items[i].index
                    );
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

            // Decrease Quantity.
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
            if(!readProductExists(_orderItem.Storefront, _orderItem.index)) return false;

            // Validate Product In Stock
            if(readProductStock(_orderItem.Storefront, _orderItem.index) < _orderItem.Quantity) return false;

            // Validate Vendor Active
            if(!storeFronts[_orderItem.Storefront].store_active) return false;

            // Validate Product Price
            if(!validateItemPrice(_orderItem.Storefront, _orderItem.index, _orderItem.CusdValue)) return false;
        }

        // Fresa Network Stats.
        function readFresaStoreCount() public view returns(uint NetworkStoreCount){
            return fresaStoreCount;
        }

        function readFresaProductCount() public view returns(uint NetworkProductCount){
            return fresaStoreCount;
        }

        function readFresaSaleCount() public view returns(uint NetworkProductCount){
            return fresaSaleCount;
        }
    }