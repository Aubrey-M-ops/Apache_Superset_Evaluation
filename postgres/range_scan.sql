-- Range scan with filters and sorting
SELECT model, price
FROM computers
WHERE
    brand = 'Lenovo'
    AND price BETWEEN 800 AND 1200
ORDER BY price
LIMIT 10000;