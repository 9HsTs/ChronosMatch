# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
# cython: cdivision=True

from libc.stdint cimport uint64_t, uint32_t, int64_t
from libc.stdlib cimport calloc, free

from .types cimport (
    Order,
    BUY,
    SELL,
    LIMIT,
    MARKET
)


cdef class MatchingEngine:

    cdef Order* orders
    cdef uint64_t capacity

    cdef uint64_t next_sequence

    # order_id -> internal order index
    cdef dict order_index

    # price -> order queue information
    cdef dict bid_levels
    cdef dict ask_levels

    cdef int64_t best_bid
    cdef int64_t best_ask

    cdef bint has_bid
    cdef bint has_ask

    cdef list trade_buffer


    def __cinit__(self, uint64_t capacity=100000):

        self.capacity = capacity

        self.orders = <Order*>calloc(
            capacity,
            sizeof(Order)
        )

        if self.orders == NULL:
            raise MemoryError(
                "Unable to allocate order pool"
            )

        self.next_sequence = 1

        self.order_index = {}
        self.bid_levels = {}
        self.ask_levels = {}

        self.best_bid = 0
        self.best_ask = 0

        self.has_bid = False
        self.has_ask = False

        self.trade_buffer = []


    def __dealloc__(self):

        if self.orders != NULL:
            free(self.orders)

        self.orders = NULL


    cdef int64_t _allocate_order(self):

        cdef uint64_t i

        for i in range(self.capacity):

            if not self.orders[i].active:
                return <int64_t>i

        raise RuntimeError(
            "Order pool exhausted"
        )


    cdef void _update_best_bid(self):

        cdef object price

        self.has_bid = False

        for price in self.bid_levels:

            if (
                not self.has_bid
                or <int64_t>price > self.best_bid
            ):

                self.best_bid = <int64_t>price
                self.has_bid = True


    cdef void _update_best_ask(self):

        cdef object price

        self.has_ask = False

        for price in self.ask_levels:

            if (
                not self.has_ask
                or <int64_t>price < self.best_ask
            ):

                self.best_ask = <int64_t>price
                self.has_ask = True


    cdef void _update_best_after_insert(
        self,
        int64_t price,
        bint is_buy
    ):

        if is_buy:

            if (
                not self.has_bid
                or price > self.best_bid
            ):
                self.best_bid = price
                self.has_bid = True

        else:

            if (
                not self.has_ask
                or price < self.best_ask
            ):
                self.best_ask = price
                self.has_ask = True


    cdef void _append_order(
        self,
        int64_t index,
        bint is_buy
    ):

        cdef Order* order = &self.orders[index]

        cdef dict levels
        cdef dict level
        cdef int64_t tail

        if is_buy:
            levels = self.bid_levels
        else:
            levels = self.ask_levels


        if order.price not in levels:

            levels[order.price] = {
                "head": index,
                "tail": index,
                "quantity": order.remaining
            }

            order.prev = -1
            order.next = -1

        else:

            level = levels[order.price]

            tail = level["tail"]

            order.prev = tail
            order.next = -1

            self.orders[tail].next = index

            level["tail"] = index
            level["quantity"] += order.remaining


    cdef void _remove_order(
        self,
        int64_t index,
        bint is_buy
    ):

        cdef Order* order = &self.orders[index]

        cdef dict levels
        cdef dict level

        if is_buy:
            levels = self.bid_levels
        else:
            levels = self.ask_levels

        level = levels[order.price]


        if order.prev >= 0:

            self.orders[order.prev].next = order.next

        else:

            level["head"] = order.next


        if order.next >= 0:

            self.orders[order.next].prev = order.prev

        else:

            level["tail"] = order.prev


        level["quantity"] -= order.remaining


        if level["head"] < 0:

            del levels[order.price]

            if is_buy:

                self._update_best_bid()

            else:

                self._update_best_ask()


    cdef void _record_trade(
        self,
        uint64_t buy_order_id,
        uint64_t sell_order_id,
        int64_t price,
        uint64_t quantity
    ):

        self.trade_buffer.append({
            "buy_order_id": buy_order_id,
            "sell_order_id": sell_order_id,
            "price": price,
            "quantity": quantity
        })


    cdef void _match_buy(
        self,
        int64_t incoming_index
    ):

        cdef Order* incoming = &self.orders[incoming_index]

        cdef int64_t resting_index

        cdef dict level

        cdef uint64_t execution_quantity

        cdef int64_t execution_price


        while (
            incoming.remaining > 0
            and self.has_ask
        ):

            # Limit BUY cannot trade above its limit price
            if (
                incoming.order_type == LIMIT
                and incoming.price < self.best_ask
            ):
                break


            level = self.ask_levels[self.best_ask]

            resting_index = level["head"]


            execution_quantity = min(
                incoming.remaining,
                self.orders[resting_index].remaining
            )

            execution_price = (
                self.orders[resting_index].price
            )


            incoming.remaining -= execution_quantity

            self.orders[resting_index].remaining -= (
                execution_quantity
            )

            level["quantity"] -= execution_quantity


            self._record_trade(
                incoming.order_id,
                self.orders[resting_index].order_id,
                execution_price,
                execution_quantity
            )


            if self.orders[resting_index].remaining == 0:

                self._remove_order(
                    resting_index,
                    False
                )

                self.orders[resting_index].active = False

                del self.order_index[
                    self.orders[resting_index].order_id
                ]


    cdef void _match_sell(
        self,
        int64_t incoming_index
    ):

        cdef Order* incoming = &self.orders[incoming_index]

        cdef int64_t resting_index

        cdef dict level

        cdef uint64_t execution_quantity

        cdef int64_t execution_price


        while (
            incoming.remaining > 0
            and self.has_bid
        ):

            # Limit SELL cannot trade below its limit price
            if (
                incoming.order_type == LIMIT
                and incoming.price > self.best_bid
            ):
                break


            level = self.bid_levels[self.best_bid]

            resting_index = level["head"]


            execution_quantity = min(
                incoming.remaining,
                self.orders[resting_index].remaining
            )

            execution_price = (
                self.orders[resting_index].price
            )


            incoming.remaining -= execution_quantity

            self.orders[resting_index].remaining -= (
                execution_quantity
            )

            level["quantity"] -= execution_quantity


            self._record_trade(
                self.orders[resting_index].order_id,
                incoming.order_id,
                execution_price,
                execution_quantity
            )


            if self.orders[resting_index].remaining == 0:

                self._remove_order(
                    resting_index,
                    True
                )

                self.orders[resting_index].active = False

                del self.order_index[
                    self.orders[resting_index].order_id
                ]


    cpdef add_order(
        self,
        uint64_t order_id,
        uint32_t side,
        int64_t price,
        uint64_t quantity,
        uint32_t order_type=LIMIT
    ):

        cdef int64_t index

        if order_id in self.order_index:
            raise ValueError(
                "Duplicate order ID"
            )

        if quantity == 0:
            raise ValueError(
                "Quantity must be greater than zero"
            )

        if side != BUY and side != SELL:
            raise ValueError(
                "Invalid order side"
            )

        if (
            order_type == LIMIT
            and price <= 0
        ):
            raise ValueError(
                "Limit price must be positive"
            )


        index = self._allocate_order()


        self.orders[index].order_id = order_id

        self.orders[index].sequence = (
            self.next_sequence
        )

        self.orders[index].price = price

        self.orders[index].quantity = quantity

        self.orders[index].remaining = quantity

        self.orders[index].side = side

        self.orders[index].order_type = order_type

        self.orders[index].prev = -1

        self.orders[index].next = -1

        self.orders[index].active = True


        self.order_index[order_id] = index

        self.next_sequence += 1


        # Attempt matching

        if side == BUY:

            self._match_buy(index)

        else:

            self._match_sell(index)


        # Remaining quantity becomes resting limit order

        if self.orders[index].remaining > 0:

            if order_type == LIMIT:

                self._append_order(
                    index,
                    side == BUY
                )

                self._update_best_after_insert(
                    price,
                    side == BUY
                )

            else:

                # Market order cannot rest
                self.orders[index].active = False

                del self.order_index[order_id]

        else:

            self.orders[index].active = False

            del self.order_index[order_id]


    cpdef bint cancel_order(
        self,
        uint64_t order_id
    ):

        cdef int64_t index

        if order_id not in self.order_index:
            return False


        index = self.order_index[order_id]


        if not self.orders[index].active:
            return False


        self._remove_order(
            index,
            self.orders[index].side == BUY
        )


        self.orders[index].active = False

        del self.order_index[order_id]

        return True


    cpdef list get_trades(self):

        cdef list result

        result = self.trade_buffer

        self.trade_buffer = []

        return result


    cpdef dict get_book(self):

        return {
            "best_bid":
                self.best_bid
                if self.has_bid
                else None,

            "best_ask":
                self.best_ask
                if self.has_ask
                else None,

            "bids": {
                price: data["quantity"]
                for price, data
                in self.bid_levels.items()
            },

            "asks": {
                price: data["quantity"]
                for price, data
                in self.ask_levels.items()
            }
        }