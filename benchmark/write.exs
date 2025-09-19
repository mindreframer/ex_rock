db_path = Path.join(System.tmp_dir!(), "test_db_#{UUID.uuid4()}")
ExRocket.destroy(db_path)
{:ok, db} = ExRocket.open(db_path)

Benchee.run(
  %{
    "write" => fn ->
      d = UUID.uuid4()
      ExRocket.put(db, d, d)
    end,
  },
  parallel: 2,
  warmup: 5,
  time: 10,
  memory_time: 5
)
