defmodule ExRocket.Checkpoint.Test do
  use ExRocket.Case, async: true

  describe "checkpoint" do
    test "create_checkpoint", context do
      path = context.db_path
      cp_path = path <> "_cp"
      ExRocket.destroy(path)
      ExRocket.destroy(cp_path)

      {:ok, db} = ExRocket.open(path)
      :ok = ExRocket.put(db, "k0", "v0")
      :ok = ExRocket.create_checkpoint(db, cp_path)

      {:ok, backup_db} = ExRocket.open(cp_path)
      {:ok, "v0"} = ExRocket.get(backup_db, "k0")
    end
  end
end
