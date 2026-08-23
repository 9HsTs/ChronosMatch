import asyncio
import time

from market_simulator import create_order


async def generate_market_orders(total_orders, batch_size=1000):
    next_order_id = 1
    generated_orders = 0

    while generated_orders < total_orders:
        current_batch_size = min(
            batch_size,
            total_orders - generated_orders
        )

        for _ in range(current_batch_size):
            yield create_order(next_order_id)
            next_order_id += 1
            generated_orders += 1

        await asyncio.sleep(0)


async def run_benchmark(total_orders):
    start_time = time.perf_counter()
    generated_orders = 0

    async for _ in generate_market_orders(total_orders):
        generated_orders += 1

    elapsed_time = time.perf_counter() - start_time
    orders_per_second = generated_orders / elapsed_time

    print(f"Orders generated: {generated_orders}")
    print(f"Elapsed time: {elapsed_time:.4f} seconds")
    print(f"Orders per second: {orders_per_second:,.0f}")


async def main():
    await run_benchmark(100_000)


if __name__ == "__main__":
    asyncio.run(main())