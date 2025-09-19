# ExRocket

[![Tests](https://github.com/mindreframer/ex_rocket/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/mindreframer/ex_rocket/actions/workflows/elixir.yml)
[![Build precompiled NIFs](https://github.com/mindreframer/ex_rocket/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/mindreframer/ex_rocket/actions/workflows/release.yml)

## About

ExRocket is NIF for Elixir which uses Rust binding for [RocksDB](https://github.com/facebook/rocksdb). Its key features are safety, performance and a minimal codebase. The keys and data are kept binary and this doesn’t impose any restrictions on storage format. So far the project is suitable for being used in third-party solutions.
ExRocket is a logical continuation of [Rocker](https://github.com/Vonmo/rocker) - NIF for Erlang

## Installation
The package can be installed by adding `ex_rocket` to your list of dependencies in `mix.exs`:
```
def deps do
  [{:ex_rocket, "~> 0.3"}]
end
```

## Versions
| ExRocket   | RocksDB | rust-rocksdb | 
| -------- | ------- | ------- |
| 0.3.x  | 10.4.2    | 0.24.x |


## Supported OS
* Linux
* Windows
* MacOS

## Features
* kv operations
* column families support
* batch write
* support of flexible storage setup
* range iterator
* delete range
* multi get
* snapshots
* checkpoints (Online backups)
* backup api
* merge operators (counter, erlang term, bitset)

## Main requirements for a driver
* Reliability
* Performance
* Minimal codebase
* Safety
* Functionality

## Performance
In a set of tests you can find a performance test. It demonstrates about 135k write RPS and 2.1M read RPS on my machine. In real conditions we might expect something about 50k write RPS and 400k read RPS with average amount of data being about 1 kB per key and the total number of keys exceeding 1 billion.

## Build Information
ExRocket requires
* Erlang >= 24.
* Rust >= 1.76.
* Clang >= 15.


## Release
- bump the version in `mix.exs`
- bump the version in `native/rocker/Cargo.toml`
- tag a release `git tag v0.3.0`
- push the tag: `git push mindrefamer v0.3.0`
- wait for the compiled libs to be uploaded (takes around 15 minutes if all goes well)
- run `mix rustler_precompiled.download ExRocket --all` to download all libs + generate `checksum-Elixir.ExRocket.exs`
- now you can publish: `mix hex.publish`


## Status
Passed all the functional and performance tests.

## License
ExRocket's license is [Apache License Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)
