defmodule ExRock.MergeTest do
  use ExRock.Case, async: false

  describe "counter merge operator" do
    test "counter merge basic functionality", context do
      path = context.db_path

      # Open database with counter merge operator
      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "counter_merge_operator"
      })

      # Test merging with no existing value
      assert :ok == ExRock.merge(db, "counter", "1")
      assert {:ok, "1"} == ExRock.get(db, "counter")

      # Test merging with existing value
      assert :ok == ExRock.merge(db, "counter", "2")
      assert {:ok, "3"} == ExRock.get(db, "counter")

      # Test merging with negative value
      assert :ok == ExRock.merge(db, "counter", "-1")
      assert {:ok, "2"} == ExRock.get(db, "counter")

      # Test multiple merges
      assert :ok == ExRock.merge(db, "counter", "5")
      assert :ok == ExRock.merge(db, "counter", "3")
      assert {:ok, "10"} == ExRock.get(db, "counter")

      # Test with new key
      assert :ok == ExRock.merge(db, "new_counter", "42")
      assert {:ok, "42"} == ExRock.get(db, "new_counter")
    end

    test "counter merge with put operation", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "counter_merge_operator"
      })

      # Put initial value
      assert :ok == ExRock.put(db, "counter", "10")
      assert {:ok, "10"} == ExRock.get(db, "counter")

      # Merge with existing put value
      assert :ok == ExRock.merge(db, "counter", "5")
      assert {:ok, "15"} == ExRock.get(db, "counter")

      # Put over merged value
      assert :ok == ExRock.put(db, "counter", "0")
      assert {:ok, "0"} == ExRock.get(db, "counter")

      # Merge again
      assert :ok == ExRock.merge(db, "counter", "7")
      assert {:ok, "7"} == ExRock.get(db, "counter")
    end

    test "counter merge error handling", context do
      path = context.db_path

      # Test without merge operator - should fail
      {:ok, db} = ExRock.open(path, %{create_if_missing: true})

      # This should return an error since no merge operator is configured
      case ExRock.merge(db, "counter", "1") do
        {:error, _reason} -> :ok
        :ok -> flunk("Expected merge to fail without merge operator")
      end
    end
  end

  describe "erlang merge operator" do
    test "basic functionality (simple string merge)", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # For now, the erlang merge operator falls back to counter behavior for simple strings
      assert :ok == ExRock.merge(db, "simple_counter", "5")
      {:ok, result1} = ExRock.get(db, "simple_counter")
      assert "5" == result1

      # Test merging with existing value
      assert :ok == ExRock.merge(db, "simple_counter", "3")
      {:ok, result2} = ExRock.get(db, "simple_counter")
      assert "8" == result2
    end

    test "int_add operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Test merging with no existing value
      operand1 = :erlang.term_to_binary({:int_add, 5})
      assert :ok == ExRock.merge(db, "int_counter", operand1)
      {:ok, result1} = ExRock.get(db, "int_counter")
      assert 5 == :erlang.binary_to_term(result1)

      # Test merging with existing value
      operand2 = :erlang.term_to_binary({:int_add, 3})
      assert :ok == ExRock.merge(db, "int_counter", operand2)
      {:ok, result2} = ExRock.get(db, "int_counter")
      assert 8 == :erlang.binary_to_term(result2)

      # Test negative values
      operand3 = :erlang.term_to_binary({:int_add, -2})
      assert :ok == ExRock.merge(db, "int_counter", operand3)
      {:ok, result3} = ExRock.get(db, "int_counter")
      assert 6 == :erlang.binary_to_term(result3)
    end

    test "list_append operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :b])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Append to existing list
      operand1 = :erlang.term_to_binary({:list_append, [:c, :d]})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :b, :c, :d] == :erlang.binary_to_term(result1)

      # Append more elements
      operand2 = :erlang.term_to_binary({:list_append, [:e]})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:a, :b, :c, :d, :e] == :erlang.binary_to_term(result2)
    end

    test "binary_append operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial binary
      initial_binary = :erlang.term_to_binary("hello")
      assert :ok == ExRock.put(db, "my_binary", initial_binary)

      # Append to existing binary
      operand1 = :erlang.term_to_binary({:binary_append, " world"})
      assert :ok == ExRock.merge(db, "my_binary", operand1)
      {:ok, result1} = ExRock.get(db, "my_binary")
      assert "hello world" == :erlang.binary_to_term(result1)

      # Append more text
      operand2 = :erlang.term_to_binary({:binary_append, "!"})
      assert :ok == ExRock.merge(db, "my_binary", operand2)
      {:ok, result2} = ExRock.get(db, "my_binary")
      assert "hello world!" == :erlang.binary_to_term(result2)
    end

    test "list_subtract operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :b, :c, :d, :e])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Subtract elements
      operand1 = :erlang.term_to_binary({:list_subtract, [:b, :d]})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :c, :e] == :erlang.binary_to_term(result1)

      # Subtract more elements
      operand2 = :erlang.term_to_binary({:list_subtract, [:a, :e]})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:c] == :erlang.binary_to_term(result2)
    end

    test "list_set operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :b, :c])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Set element at position 1
      operand1 = :erlang.term_to_binary({:list_set, 1, :x})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :x, :c] == :erlang.binary_to_term(result1)

      # Set element at position 0
      operand2 = :erlang.term_to_binary({:list_set, 0, :y})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:y, :x, :c] == :erlang.binary_to_term(result2)
    end

    test "list_delete single position operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :b, :c, :d, :e])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Delete element at position 2
      operand1 = :erlang.term_to_binary({:list_delete, 2})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :b, :d, :e] == :erlang.binary_to_term(result1)

      # Delete element at position 0
      operand2 = :erlang.term_to_binary({:list_delete, 0})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:b, :d, :e] == :erlang.binary_to_term(result2)
    end

    test "list_delete range operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :b, :c, :d, :e, :f])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Delete range from position 1 to 4 (elements :b, :c, :d)
      operand1 = :erlang.term_to_binary({:list_delete, 1, 4})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :e, :f] == :erlang.binary_to_term(result1)

      # Delete range from position 0 to 2 (elements :a, :e)
      operand2 = :erlang.term_to_binary({:list_delete, 0, 2})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:f] == :erlang.binary_to_term(result2)
    end

    test "list_insert operations", context do
      path = context.db_path

      {:ok, db} = ExRock.open(path, %{
        create_if_missing: true,
        merge_operator: "erlang_merge_operator"
      })

      # Start with initial list
      initial_list = :erlang.term_to_binary([:a, :c, :e])
      assert :ok == ExRock.put(db, "my_list", initial_list)

      # Insert elements at position 1
      operand1 = :erlang.term_to_binary({:list_insert, 1, [:b, :x]})
      assert :ok == ExRock.merge(db, "my_list", operand1)
      {:ok, result1} = ExRock.get(db, "my_list")
      assert [:a, :b, :x, :c, :e] == :erlang.binary_to_term(result1)

      # Insert elements at position 0 (beginning)
      operand2 = :erlang.term_to_binary({:list_insert, 0, [:start]})
      assert :ok == ExRock.merge(db, "my_list", operand2)
      {:ok, result2} = ExRock.get(db, "my_list")
      assert [:start, :a, :b, :x, :c, :e] == :erlang.binary_to_term(result2)

      # Insert elements at end
      list_len = length(:erlang.binary_to_term(result2))
      operand3 = :erlang.term_to_binary({:list_insert, list_len, [:end]})
      assert :ok == ExRock.merge(db, "my_list", operand3)
      {:ok, result3} = ExRock.get(db, "my_list")
      assert [:start, :a, :b, :x, :c, :e, :end] == :erlang.binary_to_term(result3)
    end
  end
end