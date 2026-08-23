import unittest
from market_simulator import create_order
class TestCreaterOrder(unittest.TestCase):
    def test_order_id_is_preserved(self):
        order=create_order(1)

        self.assertEqual(order["order_id"],1)
    def test_order_has_valid_side(self):
        order=create_order(2)

        self.assertIn(order["side"],["BUY","SELL"])
    def test_order_price_is_in_expected_range(self):
        order=create_order(3)

        self.assertGreaterEqual(order["price"],100.00)
        self.assertLessEqual(order["price"],200.00)

    def test_order_quantity_is_in_expected_range(self):
        order=create_order(4)

        self.assertGreaterEqual(order["quantity"],1)
        self.assertLessEqual(order["quantity"],100)

