# Guía Técnica Backend – v1.4 (trigger POS diferido)

## Migraciones (orden)
1) 2025_10_23_000001_caja_fondo.sql
2) 2025_10_23_000002_consumo_pos_staging.sql
3) 2025_10_23_000003_produccion.sql
4) 2025_10_23_000004_transferencias.sql

## Notas
- El trigger de descuento POS se postergará. Se usará staging por ahora.
- Implementar endpoints según OpenAPI `api/api_v1_4.yaml`.