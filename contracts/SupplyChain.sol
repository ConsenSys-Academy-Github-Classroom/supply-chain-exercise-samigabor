// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
  // Uncomment the following code block. it is needed to run tests
  /* function fetchItem(uint _sku) public view */ 
  /*   returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) */ 
  /* { */
  /*   name = items[_sku].name; */
  /*   sku = items[_sku].sku; */
  /*   price = items[_sku].price; */
  /*   state = uint(items[_sku].state); */
  /*   seller = items[_sku].seller; */
  /*   buyer = items[_sku].buyer; */
  /*   return (name, sku, price, state, seller, buyer); */
  /* } */
    address public owner;

    uint public skuCount;

    mapping(uint => Item) public items;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }

    /*
     * Events
     */

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

    /*
     * Modifiers
     */

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    modifier forSale(uint sku) {
        require(
            items[sku].state == State.ForSale && items[sku].price > 0,
            "Item not for sale."
        );
        _;
    }

    modifier sold(uint sku) {
        require(items[sku].state == State.Sold, "Item not sold.");
        _;
    }

    modifier shipped(uint sku) {
        require(items[sku].state == State.Shipped, "Item not shipped.");
        _;
    }

    modifier received(uint sku) {
        require(items[sku].state == State.Received, "Item not received.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addItem(string memory _name, uint _price)
        public
        returns (bool)
    {
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount = skuCount + 1;
        emit LogForSale(skuCount);
        return true;
    }

    function buyItem(uint sku)
        public
        payable
        forSale(sku)
        paidEnough(items[sku].price)
        checkValue(sku)
    {
        items[sku].buyer = msg.sender;
        address(items[sku].seller).transfer(items[sku].price);
        items[sku].state = State.Sold;
        emit LogSold(sku);
    }

    function shipItem(uint sku)
        public
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    function receiveItem(uint sku)
        public
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

}
