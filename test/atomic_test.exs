defmodule ExRocket.Atomic.Test do
  use ExRocket.Case, async: true

  describe "atomic" do
    test "put_get", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "key", "value")
      {:ok, "value"} = ExRocket.get(db, "key")
      :ok = ExRocket.put(db, "key", "value1")
      {:ok, "value1"} = ExRocket.get(db, "key")
      :ok = ExRocket.put(db, "key", "value2")
      {:ok, "value2"} = ExRocket.get(db, "key")
      :undefined = ExRocket.get(db, "unknown")
      {:ok, "default"} = ExRocket.get(db, "unknown", "default")
    end

    test "put_get_bin", context do
      key = :erlang.term_to_binary({:test, :key})
      val = :erlang.term_to_binary({:test, :val})
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, key, val)
      {:ok, ^val} = ExRocket.get(db, key)
    end

    test "delete", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "key", "value")
      {:ok, "value"} = ExRocket.get(db, "key")
      :ok = ExRocket.delete(db, "key")
      :undefined = ExRocket.get(db, "key")
    end

    test "write_batch", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, 4} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:delete, "k0"},
          {:put, "k3", "v3"}
        ])

      :undefined = ExRocket.get(db, "k0")
      {:ok, "v1"} = ExRocket.get(db, "k1")
      {:ok, "v2"} = ExRocket.get(db, "k2")
      {:ok, "v3"} = ExRocket.get(db, "k3")
    end

    test "delete_range", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      :ok = ExRocket.delete_range(db, "k2", "k4")
      {:ok, "v1"} = ExRocket.get(db, "k1")
      :undefined = ExRocket.get(db, "k2")
      :undefined = ExRocket.get(db, "k3")
      {:ok, "v4"} = ExRocket.get(db, "k4")
      {:ok, "v5"} = ExRocket.get(db, "k5")
    end

    test "multi_get", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 3} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"}
        ])

      {:ok,
       [
         :undefined,
         {:ok, "v1"},
         {:ok, "v2"},
         {:ok, "v3"},
         :undefined,
         :undefined
       ]} =
        ExRocket.multi_get(db, [
          "k0",
          "k1",
          "k2",
          "k3",
          "k4",
          "k5"
        ])
    end

    test "key_may_exist", context do
      {:ok, db} = ExRocket.open(context.db_path)
      {:ok, false} = ExRocket.key_may_exist(db, "k1")
      :ok = ExRocket.put(db, "k1", "v1")
      {:ok, true} = ExRocket.key_may_exist(db, "k1")
    end

    test "write_batch_with_merge", context do
      {:ok, db} =
        ExRocket.open(context.db_path, %{
          create_if_missing: true,
          merge_operator: "counter_merge_operator"
        })

      # Initial counter value
      :ok = ExRocket.put(db, "counter", "10")

      # Batch with merge operations
      {:ok, 4} =
        ExRocket.write_batch(db, [
          {:put, "key1", "value1"},
          {:merge, "counter", "5"},
          {:merge, "counter", "3"},
          {:delete, "old_key"}
        ])

      # Verify results
      {:ok, "value1"} = ExRocket.get(db, "key1")
      # 10 + 5 + 3 = 18
      {:ok, "18"} = ExRocket.get(db, "counter")
      :undefined = ExRocket.get(db, "old_key")
    end

    test "write_batch_with_merge_cf", context do
      {:ok, db} =
        ExRocket.open(context.db_path, %{
          create_if_missing: true,
          merge_operator: "counter_merge_operator"
        })

      # Create column family with merge operator
      :ok = ExRocket.create_cf(db, "counters", %{merge_operator: "counter_merge_operator"})

      # Initial values
      :ok = ExRocket.put_cf(db, "counters", "total", "100")

      # Batch with column family merge operations
      {:ok, 3} =
        ExRocket.write_batch(db, [
          {:put_cf, "counters", "users", "50"},
          {:merge_cf, "counters", "total", "25"},
          {:merge_cf, "counters", "total", "15"}
        ])

      # Verify results
      {:ok, "50"} = ExRocket.get_cf(db, "counters", "users")
      # 100 + 25 + 15 = 140
      {:ok, "140"} = ExRocket.get_cf(db, "counters", "total")
    end
  end
end
