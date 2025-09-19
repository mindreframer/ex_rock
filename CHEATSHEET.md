# ExRock Cheatsheet

A comprehensive reference for all ExRock features and functions.

## Database Operations

### Opening/Closing Databases
```elixir
# Open database (creates if missing)
{:ok, db} = ExRock.open("path/to/db", %{create_if_missing: true})

# Open for read-only
{:ok, db} = ExRock.open_for_read_only("path/to/db")

# Open with column families
{:ok, db} = ExRock.open_cf("path/to/db", ["cf1", "cf2"])

# Open column families read-only
{:ok, db} = ExRock.open_cf_for_read_only("path/to/db", ["cf1"])
```

### Database Management
```elixir
# Get database path
{:ok, path} = ExRock.get_db_path(db)

# Destroy database
:ok = ExRock.destroy("path/to/db")

# Repair database
:ok = ExRock.repair("path/to/db")

# Get latest sequence number
{:ok, seq} = ExRock.latest_sequence_number(db)
```

## Basic Key-Value Operations

### Standard Operations
```elixir
# Put key-value
:ok = ExRock.put(db, "key", "value")

# Get value
{:ok, "value"} = ExRock.get(db, "key")
:undefined = ExRock.get(db, "missing_key")

# Get with default
{:ok, "default"} = ExRock.get(db, "missing_key", "default")

# Delete key
:ok = ExRock.delete(db, "key")
```

### Binary Operations (ETF Serialization)
```elixir
# Get and automatically deserialize Erlang terms
{:ok, term} = ExRock.getb(db, "key")  # Calls :erlang.binary_to_term/1

# Merge with automatic ETF serialization
:ok = ExRock.mergeb(db, "key", {:int_add, 5})  # Calls :erlang.term_to_binary/1
```

## Column Family Operations

### Managing Column Families
```elixir
# Create column family
:ok = ExRock.create_cf(db, "my_cf")

# Create with options
:ok = ExRock.create_cf(db, "my_cf", %{merge_operator: "counter_merge_operator"})

# List all column families
{:ok, ["default", "my_cf"]} = ExRock.list_cf("path/to/db")

# Drop column family
:ok = ExRock.drop_cf(db, "my_cf")
```

### Column Family Operations
```elixir
# Put in column family
:ok = ExRock.put_cf(db, "my_cf", "key", "value")

# Get from column family
{:ok, "value"} = ExRock.get_cf(db, "my_cf", "key")
{:ok, "default"} = ExRock.get_cf(db, "my_cf", "key", "default")

# Binary get from column family (ETF deserialization)
{:ok, term} = ExRock.get_cfb(db, "my_cf", "key")

# Delete from column family
:ok = ExRock.delete_cf(db, "my_cf", "key")
```

## Merge Operations

### Setup Merge Operators
```elixir
# Counter merge operator
{:ok, db} = ExRock.open("path/to/db", %{
  create_if_missing: true,
  merge_operator: "counter_merge_operator"
})

# Erlang term merge operator
{:ok, db} = ExRock.open("path/to/db", %{
  create_if_missing: true,
  merge_operator: "erlang_merge_operator"
})

# Bitset merge operator
{:ok, db} = ExRock.open("path/to/db", %{
  create_if_missing: true,
  merge_operator: "bitset_merge_operator"
})
```

### Counter Merge Operations
```elixir
# String-based integer arithmetic
:ok = ExRock.merge(db, "counter", "10")    # counter = 10
:ok = ExRock.merge(db, "counter", "5")     # counter = 15
:ok = ExRock.merge(db, "counter", "-3")    # counter = 12
{:ok, "12"} = ExRock.get(db, "counter")
```

### Erlang Term Merge Operations

#### Integer Operations
```elixir
# Using binary encoding
operand = :erlang.term_to_binary({:int_add, 5})
:ok = ExRock.merge(db, "int_counter", operand)

# Using binary helper
:ok = ExRock.mergeb(db, "int_counter", {:int_add, 5})
```

#### List Operations
```elixir
# List append
:ok = ExRock.mergeb(db, "my_list", {:list_append, [:d, :e]})

# List prepend (add to beginning)
:ok = ExRock.mergeb(db, "my_list", {:list_prepend, [:start, :beginning]})

# List subtract (remove elements)
:ok = ExRock.mergeb(db, "my_list", {:list_subtract, [:b]})

# Set element at position
:ok = ExRock.mergeb(db, "my_list", {:list_set, 1, :new_value})

# Delete element at position
:ok = ExRock.mergeb(db, "my_list", {:list_delete, 0})

# Delete range of elements
:ok = ExRock.mergeb(db, "my_list", {:list_delete, 1, 3})

# Insert elements at position
:ok = ExRock.mergeb(db, "my_list", {:list_insert, 1, [:x, :y]})
```

#### Binary Operations
```elixir
# Binary append
:ok = ExRock.mergeb(db, "my_binary", {:binary_append, " world"})

# Binary erase (position, count)
:ok = ExRock.mergeb(db, "my_binary", {:binary_erase, 5, 6})

# Binary insert (position, data)
:ok = ExRock.mergeb(db, "my_binary", {:binary_insert, 5, " there"})

# Binary replace (position, count, new_data)
:ok = ExRock.mergeb(db, "my_binary", {:binary_replace, 6, 5, "everyone"})
```

### Bitset Merge Operations
```elixir
# Set bits
:ok = ExRock.merge(db, "bitset", "+0")     # Set bit 0
:ok = ExRock.merge(db, "bitset", "+5")     # Set bit 5
:ok = ExRock.merge(db, "bitset", "+12")    # Set bit 12

# Clear bits
:ok = ExRock.merge(db, "bitset", "-5")     # Clear bit 5

# Clear entire bitset
:ok = ExRock.merge(db, "bitset", "")       # Clear all bits
```

### Column Family Merge Operations
```elixir
# Standard merge in column family
:ok = ExRock.merge_cf(db, "my_cf", "key", "operand")

# Binary merge in column family (ETF serialization)
:ok = ExRock.merge_cfb(db, "my_cf", "key", {:int_add, 10})
```

## Batch Operations

```elixir
# Write batch operations - all operations are atomic
ops = [
  {:put, "key1", "value1"},
  {:put, "key2", "value2"},
  {:delete, "key3"},
  {:merge, "counter", "5"},                    # NEW: Merge operations supported!
  {:put_cf, "my_cf", "cf_key", "cf_value"},
  {:delete_cf, "my_cf", "old_key"},
  {:merge_cf, "my_cf", "cf_counter", "10"}     # NEW: Column family merge too!
]
{:ok, 7} = ExRock.write_batch(db, ops)  # Returns {:ok, count} on success

# Example: Counter batch operations
{:ok, db} = ExRock.open("my_db", %{
  create_if_missing: true,
  merge_operator: "counter_merge_operator"
})

:ok = ExRock.put(db, "total", "100")

{:ok, 3} = ExRock.write_batch(db, [
  {:merge, "total", "25"},        # total becomes 125
  {:merge, "total", "15"},        # total becomes 140
  {:put, "status", "updated"}     # set status
])

{:ok, "140"} = ExRock.get(db, "total")
{:ok, "updated"} = ExRock.get(db, "status")

# Example: ETF merge in batch (requires erlang_merge_operator)
{:ok, db} = ExRock.open("my_db", %{
  merge_operator: "erlang_merge_operator"
})

# Use binary encoded operands
operand1 = :erlang.term_to_binary({:int_add, 5})
operand2 = :erlang.term_to_binary({:list_append, [:x, :y]})

{:ok, 2} = ExRock.write_batch(db, [
  {:merge, "counter", operand1},
  {:merge, "my_list", operand2}
])
```

## Iterator Operations

### Basic Iterators
```elixir
# Create iterator (forward/reverse)
{:ok, iter} = ExRock.iterator(db, :start)     # Start from beginning
{:ok, iter} = ExRock.iterator(db, :end)       # Start from end

# Iterate through keys
{:ok, "key1", "value1"} = ExRock.next(iter)
{:ok, "key2", "value2"} = ExRock.next(iter)
:end_of_table = ExRock.next(iter)
```

### Range Iterators
```elixir
# Iterator with range
{:ok, iter} = ExRock.iterator_range(db, :start, "from_key", "to_key")

# With read options
{:ok, iter} = ExRock.iterator_range(db, :start, "from_key", "to_key", %{
  iterate_upper_bound: "upper_key"
})
```

### Prefix Iterators
```elixir
# Iterate keys with prefix
{:ok, iter} = ExRock.prefix_iterator(db, "prefix_")
```

### Column Family Iterators
```elixir
# Iterator for column family
{:ok, iter} = ExRock.iterator_cf(db, "my_cf", :start)

# Prefix iterator for column family
{:ok, iter} = ExRock.prefix_iterator_cf(db, "my_cf", "prefix_")
```

## Range Operations

```elixir
# Delete range of keys
:ok = ExRock.delete_range(db, "from_key", "to_key")

# Delete range in column family
:ok = ExRock.delete_range_cf(db, "my_cf", "from_key", "to_key")
```

## Multi-get Operations

```elixir
# Get multiple keys at once
keys = ["key1", "key2", "key3"]
{:ok, [
  {:ok, "value1"},
  :undefined,
  {:ok, "value3"}
]} = ExRock.multi_get(db, keys)

# Multi-get from column families
cf_keys = [
  {"cf1", "key1"},
  {"cf2", "key2"}
]
{:ok, results} = ExRock.multi_get_cf(db, cf_keys)
```

## Key Existence Check

```elixir
# Fast check if key might exist (bloom filter)
true = ExRock.key_may_exist(db, "key")
false = ExRock.key_may_exist(db, "definitely_missing")

# Check in column family
true = ExRock.key_may_exist_cf(db, "my_cf", "key")
```

## Snapshot Operations

### Creating and Using Snapshots
```elixir
# Create snapshot
{:ok, snap} = ExRock.snapshot(db)

# Get from snapshot
{:ok, "value"} = ExRock.snapshot_get(snap, "key")
{:ok, "default"} = ExRock.snapshot_get(snap, "key", "default")

# Get from snapshot column family
{:ok, "value"} = ExRock.snapshot_get_cf(snap, "my_cf", "key")
{:ok, "default"} = ExRock.snapshot_get_cf(snap, "my_cf", "key", "default")
```

### Snapshot Multi-get
```elixir
# Multi-get from snapshot
{:ok, results} = ExRock.snapshot_multi_get(snap, ["key1", "key2"])

# Multi-get from snapshot column families
{:ok, results} = ExRock.snapshot_multi_get_cf(snap, [{"cf1", "key1"}])
```

### Snapshot Iterators
```elixir
# Iterator from snapshot
{:ok, iter} = ExRock.snapshot_iterator(snap, :start)

# Iterator from snapshot column family
{:ok, iter} = ExRock.snapshot_iterator_cf(snap, "my_cf", :start)
```

## Backup and Checkpoint Operations

### Checkpoints (Online Backups)
```elixir
# Create checkpoint
:ok = ExRock.create_checkpoint(db, "/path/to/checkpoint")
```

### Backup Operations
```elixir
# Create backup
:ok = ExRock.create_backup(db, "/path/to/backup")

# Get backup info
{:ok, backup_info} = ExRock.get_backup_info("/path/to/backup")

# Purge old backups (keep only N most recent)
:ok = ExRock.purge_old_backups("/path/to/backup", 5)

# Restore from latest backup
:ok = ExRock.restore_from_backup("/path/to/backup", "/path/to/restore")

# Restore from specific backup ID
:ok = ExRock.restore_from_backup("/path/to/backup", "/path/to/restore", 3)
```

## Common Patterns

### Database Options
```elixir
options = %{
  create_if_missing: true,
  merge_operator: "erlang_merge_operator",
  max_open_files: 1000,
  write_buffer_size: 64 * 1024 * 1024,  # 64MB
  target_file_size_base: 64 * 1024 * 1024,
  max_bytes_for_level_base: 256 * 1024 * 1024
}

{:ok, db} = ExRock.open("path/to/db", options)
```

### Error Handling
```elixir
case ExRock.get(db, "key") do
  {:ok, value} ->
    IO.puts("Found: #{value}")
  :undefined ->
    IO.puts("Key not found")
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
```

### ETF Serialization Best Practices
```elixir
# Store complex Elixir terms
term = %{users: ["alice", "bob"], count: 42}
binary_term = :erlang.term_to_binary(term)
:ok = ExRock.put(db, "complex_data", binary_term)

# Retrieve and deserialize
{:ok, restored_term} = ExRock.getb(db, "complex_data")
# restored_term == %{users: ["alice", "bob"], count: 42}

# Or use merge operations with automatic serialization
:ok = ExRock.mergeb(db, "settings", {:list_append, [:new_setting]})
```

## Utilities

```elixir
# Check ExRock version/code
{:ok, :vsn1} = ExRock.lxcode()
```

---

*For more detailed information about specific features, see the test files in `test/` directory.*