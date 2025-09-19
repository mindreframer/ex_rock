defmodule ExRocket.Backup.Test do
  use ExRocket.Case

  describe "backup" do
    test "create_backup", context do
      path = context.db_path
      backup_path = path <> "_backup"
      ExRocket.destroy(path)
      ExRocket.destroy(backup_path)

      {:ok, db} = ExRocket.open(path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, [{:backup, 1, _, _, _}]} = ExRocket.create_backup(db, backup_path)

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}]} =
        ExRocket.get_backup_info(backup_path)
    end

    test "purge_old_backups", context do
      path = context.db_path
      backup_path = path <> "_backup"
      ExRocket.destroy(path)
      ExRocket.destroy(backup_path)

      {:ok, db} = ExRocket.open(path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, [{:backup, 1, _, _, _}]} = ExRocket.create_backup(db, backup_path)

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}, {:backup, 3, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      {:ok,
       [
         {:backup, 1, _, _, _},
         {:backup, 2, _, _, _},
         {:backup, 3, _, _, _},
         {:backup, 4, _, _, _}
       ]} = ExRocket.create_backup(db, backup_path)

      {:ok, [{:backup, 3, _, _, _}, {:backup, 4, _, _, _}]} =
        ExRocket.purge_old_backups(backup_path, 2)
    end

    test "restore_latest_backup", context do
      path = context.db_path
      backup_path = path <> "_backup"
      restore_path = path <> "_restore"
      ExRocket.destroy(path)
      ExRocket.destroy(backup_path)
      ExRocket.destroy(restore_path)

      {:ok, db} = ExRocket.open(path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, [{:backup, 1, _, _, _}]} = ExRocket.create_backup(db, backup_path)
      :ok = ExRocket.put(db, "k0", "v1")

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      :ok = ExRocket.restore_from_backup(backup_path, restore_path)

      {:ok, restored} = ExRocket.open(restore_path)
      {:ok, "v1"} = ExRocket.get(restored, "k0")
    end

    test "restore_backup", context do
      path = context.db_path
      backup_path = path <> "_backup"
      restore_path = path <> "_restore"
      ExRocket.destroy(path)
      ExRocket.destroy(backup_path)
      ExRocket.destroy(restore_path)

      {:ok, db} = ExRocket.open(path)
      :ok = ExRocket.put(db, "k0", "v0")

      {:ok, [{:backup, 1, _, _, _}]} = ExRocket.create_backup(db, backup_path)
      :ok = ExRocket.put(db, "k0", "v1")

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      :ok = ExRocket.put(db, "k0", "v2")

      {:ok, [{:backup, 1, _, _, _}, {:backup, 2, _, _, _}, {:backup, 3, _, _, _}]} =
        ExRocket.create_backup(db, backup_path)

      :ok = ExRocket.restore_from_backup(backup_path, restore_path, 2)

      {:ok, restored} = ExRocket.open(restore_path)
      {:ok, "v1"} = ExRocket.get(restored, "k0")
    end
  end
end
