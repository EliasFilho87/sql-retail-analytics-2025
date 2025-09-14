
-- SQL Portfolio - Retail Analytics 2025
-- Starter queries (SQLite dialect)

-- 1) Top 10 produtos por receita
SELECT 
  p.name AS produto,
  p.category AS categoria,
  SUM(oi.quantity) AS quantidade_total,
  ROUND(SUM(oi.quantity * oi.selling_price), 2) AS receita
FROM order_items oi
JOIN products p   ON p.product_id = oi.product_id
JOIN orders   o   ON o.order_id   = oi.order_id
WHERE o.status = 'Concluído'
GROUP BY p.product_id
ORDER BY receita DESC
LIMIT 10;

-- 2) Top 5 clientes por receita + ticket médio
WITH order_totals AS (
  SELECT 
    o.order_id,
    o.customer_id,
    SUM(oi.quantity * oi.selling_price) AS order_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'Concluído'
  GROUP BY o.order_id, o.customer_id
)
SELECT 
  c.customer_id,
  c.name,
  c.city,
  c.state,
  ROUND(SUM(ot.order_revenue), 2) AS receita_total,
  ROUND(AVG(ot.order_revenue), 2) AS ticket_medio,
  COUNT(*) AS num_pedidos
FROM order_totals ot
JOIN customers c ON c.customer_id = ot.customer_id
GROUP BY c.customer_id
ORDER BY receita_total DESC
LIMIT 5;

-- 3) Receita mensal (2025)
SELECT 
  strftime('%Y-%m', o.order_date) AS ano_mes,
  ROUND(SUM(oi.quantity * oi.selling_price), 2) AS receita
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Concluído'
GROUP BY ano_mes
ORDER BY ano_mes;

-- 4) Mix de receita por canal
WITH rev AS (
  SELECT 
    o.channel,
    SUM(oi.quantity * oi.selling_price) AS receita
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'Concluído'
  GROUP BY o.channel
)
SELECT 
  channel,
  ROUND(receita, 2) AS receita,
  ROUND(100.0 * receita / (SELECT SUM(receita) FROM rev), 2) AS pct_receita
FROM rev
ORDER BY receita DESC;

-- 5) Margem bruta por produto (Top 10)
SELECT 
  p.name AS produto,
  ROUND(SUM( (oi.selling_price - p.unit_cost) * oi.quantity ), 2) AS margem_bruta,
  ROUND(100.0 * SUM( (oi.selling_price - p.unit_cost) * oi.quantity )
          / SUM(oi.selling_price * oi.quantity), 2) AS margem_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders   o ON o.order_id   = oi.order_id
WHERE o.status = 'Concluído'
GROUP BY p.product_id
ORDER BY margem_bruta DESC
LIMIT 10;

-- 6) Clientes com recompra (2+ pedidos)
WITH customer_orders AS (
  SELECT 
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS num_pedidos
  FROM orders o
  WHERE o.status = 'Concluído'
  GROUP BY o.customer_id
)
SELECT 
  c.customer_id,
  c.name,
  num_pedidos
FROM customer_orders co
JOIN customers c ON c.customer_id = co.customer_id
WHERE num_pedidos >= 2
ORDER BY num_pedidos DESC, c.name
LIMIT 20;

-- 7) Taxa de devolução (% sobre pedidos não cancelados)
SELECT 
  ROUND(100.0 * SUM(CASE WHEN status = 'Devolvido' THEN 1 ELSE 0 END)
        / SUM(CASE WHEN status IN ('Concluído', 'Devolvido') THEN 1 ELSE 0 END), 2) AS taxa_de_devolucao_pct
FROM orders;

-- 8) Ticket médio por canal
WITH order_totals AS (
  SELECT 
    o.order_id,
    o.channel,
    SUM(oi.quantity * oi.selling_price) AS order_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'Concluído'
  GROUP BY o.order_id, o.channel
)
SELECT 
  channel,
  ROUND(AVG(order_revenue), 2) AS ticket_medio
FROM order_totals
GROUP BY channel
ORDER BY ticket_medio DESC;

-- 9) Top 5 subcategorias por receita
SELECT 
  p.subcategory,
  ROUND(SUM(oi.quantity * oi.selling_price), 2) AS receita
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders   o ON o.order_id   = oi.order_id
WHERE o.status = 'Concluído'
GROUP BY p.subcategory
ORDER BY receita DESC
LIMIT 5;

-- 10) Novos clientes por mês (com base no signup_date)
SELECT 
  strftime('%Y-%m', signup_date) AS ano_mes,
  COUNT(*) AS novos_clientes
FROM customers
GROUP BY ano_mes
ORDER BY ano_mes;
