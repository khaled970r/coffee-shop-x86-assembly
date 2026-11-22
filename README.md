# Coffee Shop Ordering System – x86 Assembly

An interactive point-of-sale program for a small coffee shop, written in 32-bit x86 assembly (NASM) using Linux system calls only, with no C library.

## Features

- Menu of six items with prices stored in cents (integer arithmetic only)
- Add items to an order, with a running subtotal
- Checkout with **8% tax** calculation and formatted dollar amounts
- Cancel the current order or exit
- Input validation for menu choices
- Hand-written integer-to-string conversion for printing prices

## Build & Run (Linux)

```bash
nasm -f elf32 coffee_shop.asm -o coffee_shop.o
ld -m elf_i386 coffee_shop.o -o coffee_shop
./coffee_shop
```

## Concepts Demonstrated

Linux `int 0x80` syscalls (`read` / `write` / `exit`) · registers and memory addressing · data/bss sections · loops and branching · integer arithmetic and number formatting
