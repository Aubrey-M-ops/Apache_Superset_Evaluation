-- Scan with filters
SELECT price, model, brand
FROM computers
WHERE
    brand = 'Lenovo'
    AND model = 'Lenovo Legion SZI';