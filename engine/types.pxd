from libc.stdint cimport uint64_t, uint32_t, int64_t


cdef enum Side:
    BUY = 0
    SELL = 1


cdef enum OrderType:
    LIMIT = 0
    MARKET = 1


cdef struct Order:
    uint64_t order_id
    uint64_t sequence

    int64_t price
    uint64_t quantity
    uint64_t remaining

    uint32_t side
    uint32_t order_type

    int64_t prev
    int64_t next

    bint active