defmodule ExRocket.Iterator.Test do
  use ExRocket.Case, async: true

  describe "iterator" do
    test "create_iterator", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, start_ref} = ExRocket.iterator(db, {:start})
      assert is_reference(start_ref)

      {:ok, end_ref} = ExRocket.iterator(db, {:end})
      assert is_reference(end_ref)

      {:ok, from_ref1} = ExRocket.iterator(db, {:from, "k0", :forward})
      assert is_reference(from_ref1)

      {:ok, from_ref2} = ExRocket.iterator(db, {:from, "k0", :reverse})
      assert is_reference(from_ref2)

      {:ok, from_ref3} = ExRocket.iterator(db, {:from, "k1", :forward})
      assert is_reference(from_ref3)

      {:ok, from_ref4} = ExRocket.iterator(db, {:from, "k1", :reverse})
      assert is_reference(from_ref4)
      {:ok, "k0", _} = ExRocket.next(from_ref4)
    end

    test "next_start", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")
      :ok = ExRocket.put(db, "k1", "v1")
      :ok = ExRocket.put(db, "k2", "v2")

      {:ok, iter} = ExRocket.iterator(db, {:start})
      {:ok, "k0", "v0"} = ExRocket.next(iter)
      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "next_end", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")
      :ok = ExRocket.put(db, "k1", "v1")
      :ok = ExRocket.put(db, "k2", "v2")

      {:ok, iter} = ExRocket.iterator(db, {:end})
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k0", "v0"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "next_from_forward", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")
      :ok = ExRocket.put(db, "k1", "v1")
      :ok = ExRocket.put(db, "k2", "v2")

      {:ok, iter} = ExRocket.iterator(db, {:from, "k1", :forward})
      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "next_from_reverse", context do
      {:ok, db} = ExRocket.open(context.db_path)
      :ok = ExRocket.put(db, "k0", "v0")
      :ok = ExRocket.put(db, "k1", "v1")
      :ok = ExRocket.put(db, "k2", "v2")

      {:ok, iter} = ExRocket.iterator(db, {:from, "k1", :reverse})
      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k0", "v0"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "prefix_iterator", context do
      {:ok, db} =
        ExRocket.open(context.db_path, %{
          set_prefix_extractor_prefix_length: 3,
          create_if_missing: true
        })

      :ok = ExRocket.put(db, "aaa1", "va1")
      :ok = ExRocket.put(db, "bbb1", "vb1")
      :ok = ExRocket.put(db, "aaa2", "va2")
      {:ok, iter} = ExRocket.prefix_iterator(db, "aaa")
      true = is_reference(iter)
      {:ok, "aaa1", "va1"} = ExRocket.next(iter)
      {:ok, "aaa2", "va2"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)

      {:ok, iter2} = ExRocket.prefix_iterator(db, "bbb")
      true = is_reference(iter2)
      {:ok, "bbb1", "vb1"} = ExRocket.next(iter2)
      :end_of_iterator = ExRocket.next(iter2)
    end

    test "iterator_range_start", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:start}, "k2", "k4")
      true = is_reference(iter)

      {:ok, "k2", "v2"} = ExRocket.next(iter)
      {:ok, "k3", "v3"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_end", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:end}, "k2", "k4")
      true = is_reference(iter)

      {:ok, "k3", "v3"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_from", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:from, "k3", :forward}, "k2", "k5")
      true = is_reference(iter)

      {:ok, "k3", "v3"} = ExRocket.next(iter)
      {:ok, "k4", "v4"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_from_reverse", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:from, "k3", :reverse}, "k2", "k5")
      true = is_reference(iter)

      {:ok, "k3", "v3"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_undefined_left_border", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:start}, :undefined, "k4")
      true = is_reference(iter)

      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      {:ok, "k3", "v3"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_undefined_right_border", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:start}, "k2", :undefined)
      true = is_reference(iter)

      {:ok, "k2", "v2"} = ExRocket.next(iter)
      {:ok, "k3", "v3"} = ExRocket.next(iter)
      {:ok, "k4", "v4"} = ExRocket.next(iter)
      {:ok, "k5", "v5"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end

    test "iterator_range_undefined_both_borders", context do
      {:ok, db} = ExRocket.open(context.db_path)

      {:ok, 5} =
        ExRocket.write_batch(db, [
          {:put, "k1", "v1"},
          {:put, "k2", "v2"},
          {:put, "k3", "v3"},
          {:put, "k4", "v4"},
          {:put, "k5", "v5"}
        ])

      {:ok, iter} = ExRocket.iterator_range(db, {:start}, :undefined, :undefined)
      true = is_reference(iter)

      {:ok, "k1", "v1"} = ExRocket.next(iter)
      {:ok, "k2", "v2"} = ExRocket.next(iter)
      {:ok, "k3", "v3"} = ExRocket.next(iter)
      {:ok, "k4", "v4"} = ExRocket.next(iter)
      {:ok, "k5", "v5"} = ExRocket.next(iter)
      :end_of_iterator = ExRocket.next(iter)
    end
  end
end
