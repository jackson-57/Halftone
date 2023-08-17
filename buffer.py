pos = 0
count = 100
size = 100

print("reading (start end)")
print(pos, (pos + count) % size)
print()

print("writing (start size)")
# print((pos + count), size - (pos + count))
if pos + count < size:
    print((pos + count) % size, size - (pos + count) % size)
    if (pos + count) < size:
        print(0, pos)
print()
