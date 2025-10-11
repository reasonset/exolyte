defmodule Exolyte.DB do
  use GenServer
  @db_path "priv/cubdb"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, db} = CubDB.start_link(data_dir: @db_path)
    {:ok, db}
  end

  def get_db do
    GenServer.call(__MODULE__, :get_db)
  end

  def handle_call(:get_db, _from, db), do: {:reply, db, db}
end
