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
end