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
  end
end