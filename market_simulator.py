import random


def create_order(order_id):
    """Create one mock BUY or SELL market order."""

    if order_id <= 0:
        raise ValueError("order_id must be greater than zero")

    return {
        "order_id": order_id,
        "side": random.choice(["BUY", "SELL"]),
        "price": round(random.uniform(100.00, 200.00), 2),
        "quantity": random.randint(1, 100),
    }


def display_order(order):
    """Display a mock order clearly in the terminal."""

    print(f"Order ID : {order['order_id']}")
    print(f"Side     : {order['side']}")
    print(f"Price    : {order['price']}")
    print(f"Quantity : {order['quantity']}")
    print()


def main():
    for order_id in range(1, 6):
        order = create_order(order_id)
        display_order(order)


if __name__ == "__main__":
    main()