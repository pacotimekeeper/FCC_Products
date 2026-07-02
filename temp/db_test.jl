using DuckDB

# create a new in-memory database
con = DBInterface.connect(DuckDB.DB, ":memory:")

# 3. Create a simple schema and add dummy rows
DBInterface.execute(con, """
    CREATE TABLE employees (
        id INTEGER,
        name VARCHAR,
        department VARCHAR,
        salary DOUBLE
    );
""")

DBInterface.execute(con, """
    INSERT INTO employees VALUES 
        (1, 'Alice', 'Engineering', 95000.0),
        (2, 'Bob', 'HR', 70000.0),
        (3, 'Charlie', 'Engineering', 105000.0);
""")

stmt = DBInterface.prepare(con, "INSERT INTO employees VALUES (?,?,?,?)")
DBInterface.execute(stmt, [5, "Sherry", "Manager", 30000.0])
close(con)
query = "SELECT * FROM employees"
DBInterface.execute(con, query) |> DataFrame
# 4. Query the database and convert the result to a DataFrame
result = DBInterface.execute(con, "SELECT name, salary FROM employees WHERE department = 'Engineering'")
df = DataFrame(result)

# create a table
DBInterface.execute(con, "CREATE TABLE integers (i INTEGER)")

# insert data by executing a prepared statement
stmt = DBInterface.prepare(con, "INSERT INTO integers VALUES (?)")
DBInterface.execute(stmt, [42])

# query the database
results = DBInterface.execute(con, "SELECT 42 b")
DataFrame(results)
print(results)

## scanning dataframes
using DuckDB
using DataFrames

# create a new in-memory database
con = DBInterface.connect(DuckDB.DB)

# create a DataFrame
df = DataFrame(a = [1, 2, 3], b = [42, 84, 42])

# register it as a view in the database
DuckDB.register_data_frame(con, df, "my_df")

# run a SQL query over the DataFrame
results = DBInterface.execute(con, "SELECT * FROM my_df")
print(results)
DataFrame(results)

for r in results
    println(r)
end