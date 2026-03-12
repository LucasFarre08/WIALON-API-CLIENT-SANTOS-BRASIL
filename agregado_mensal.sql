START TRANSACTION;

CREATE TABLE IF NOT EXISTS agregado_mensal (
  grouping_id VARCHAR(64) NOT NULL,
  ano_mes DATE NOT NULL,
  km_total DECIMAL(14,2) DEFAULT 0,
  litros_total DECIMAL(14,2) DEFAULT 0,
  PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

CREATE TEMPORARY TABLE tmp_agregado (
  grouping_id VARCHAR(64) NOT NULL,
  ano_mes DATE NOT NULL,
  km_total DECIMAL(14,2) DEFAULT 0,
  litros_total DECIMAL(14,2) DEFAULT 0,
  PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

INSERT INTO tmp_agregado (grouping_id, ano_mes, km_total, litros_total)
SELECT
  x.grouping_id,
  x.ano_mes,
  ROUND(SUM(COALESCE(x.quilometragem,0)), 2) AS km_total,
  ROUND(SUM(COALESCE(x.litros_consumidos,0)), 2) AS litros_total
FROM (
  SELECT
    REPLACE(REPLACE(TRIM(UPPER(`grouping`)), '.', ''), '-', '') AS grouping_id,
    DATE_FORMAT(`inicio`, '%Y-%m-01') + INTERVAL 0 DAY AS ano_mes, -- já é DATE
    quilometragem,
    litros_consumidos
  FROM viagens
  WHERE `inicio` IS NOT NULL
    AND TRIM(`grouping`) <> ''
) AS x
GROUP BY x.grouping_id, x.ano_mes;

-- atualizar existentes
UPDATE agregado_mensal a
JOIN tmp_agregado t
  ON a.grouping_id = t.grouping_id
 AND a.ano_mes = t.ano_mes
SET a.km_total = t.km_total,
    a.litros_total = t.litros_total;

-- inserir novos
INSERT INTO agregado_mensal (grouping_id, ano_mes, km_total, litros_total)
SELECT t.grouping_id, t.ano_mes, t.km_total, t.litros_total
FROM tmp_agregado t
LEFT JOIN agregado_mensal a
  ON a.grouping_id = t.grouping_id
 AND a.ano_mes = t.ano_mes
WHERE a.grouping_id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado;

COMMIT;
