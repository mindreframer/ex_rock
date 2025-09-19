# 0.3.1
- bump rust-rocksdb to 0.24
- bump required rust to 1.85
- added caching to CI


# 0.3.0

- Added comprehensive RocksDB merge operator support
  - Three merge operators: counter, erlang term, and bitset
  - Support for tuple-based operations: `{:int_add, value}`, `{:list_append, list}`, `{:binary_append, data}`, etc.
  - Column family merge operations with `merge_cf/4` and `merge_cfb/4`
- Added binary helper functions for ETF serialization
  - `getb/2` and `get_cfb/3` for automatic term deserialization
  - `mergeb/3` and `merge_cfb/4` for automatic term serialization
- **NEW**: Merge operations support in batch writes
  - Added `{:merge, key, operand}` and `{:merge_cf, cf, key, operand}` to `write_batch/2`
  - Atomic batch operations combining puts, deletes, and merges
- Added comprehensive cheatsheet documentation (`CHEATSHEET.md`)
- Complete test coverage for all merge operations

# 0.2.0

- Allow binary in multi_get
- Improve build scripts
- Delete checksum file from git
- Added licence and changelog
- Bump deps to current versions

# 0.1.0

- Initial release