-- Aggregations
SELECT brand, AVG(price) AS avg_price
FROM computers
GROUP BY
    brand
ORDER BY avg_price DESC
LIMIT 20000;