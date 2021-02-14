-- https://www.monetdb.org/Documentation/ServerAdministration/TableStatistics

ANALYZE sys.specs;  -- gather stats and fill sys.statistics table

SELECT columns.name, 1 - cast(statistics.nils as real) / cast(statistics.count as real) AS support
FROM columns
INNER JOIN tables ON columns.table_id = tables.id
INNER JOIN statistics ON columns.id = statistics.column_id
WHERE tables.name = 'specs'
ORDER BY support;

-- the above query serves as a basis - with slight alterations, we can obtain many support-based results