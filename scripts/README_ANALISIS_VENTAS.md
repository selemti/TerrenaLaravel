# Script de Análisis de Discrepancias en Ventas

## Descripción

Este script analiza las discrepancias entre los reportes de caja (Drawer Pull Reports) y los datos reales en la base de datos para identificar problemas sistemáticos en el registro de ventas.

## Ubicación

- **Script PHP:** `scripts/analyze_sales_discrepancies.php`
- **Script BAT:** `analizar_ventas.bat`
- **Documento de análisis:** `ANALISIS_DISCREPANCIAS_VENTAS_AGO_OCT_2025.md`

## Cómo Usar

### Opción 1: Análisis Predeterminado (Agosto-Octubre 2025)

```bash
php scripts/analyze_sales_discrepancies.php
```

O en Windows:
```cmd
analizar_ventas.bat
```

### Opción 2: Análisis Personalizado

Edita el script `analyze_sales_discrepancies.php` y cambia las fechas en la última línea:

```php
// Cambiar estas fechas
$analyzer = new SalesDiscrepancyAnalyzer('2025-08-01', '2025-10-31');
```

## Salidas Generadas

El script genera dos archivos:

1. **Salida en consola:** Resumen visual con tablas y estadísticas
2. **Archivo JSON:** `storage/logs/sales_discrepancies_YYYY-MM-DD_HHMMSS.json`
   - Contiene todos los datos en formato estructurado
   - Útil para análisis adicional o importación a Excel

## Categorías Analizadas

El script analiza 5 categorías de problemas:

### 1. Tickets con Descuento del 100%
- Detecta tickets donde se aplicó descuento total
- Verifica si están correctamente registrados
- Identifica si el monto del descuento es correcto

### 2. Tickets No Pagados Pero Cerrados
- Encuentra tickets cerrados sin registro de pago
- Calcula el monto total no cobrado
- Lista casos específicos para auditoría

### 3. Tickets Anulados con Transacciones
- Identifica anulaciones que mantienen transacciones activas
- Detecta duplicación de registros (Cash + Refund + Void)
- Calcula el impacto financiero

### 4. Discrepancias entre Total y Pagos
- Compara el total del ticket vs suma de pagos
- Encuentra pagos parciales sin explicación
- Lista los casos con mayor diferencia

### 5. Análisis de Drawer Pull Reports
- Compara reportes de caja vs datos reales
- Identifica diferencias sistemáticas
- Proporciona estadísticas por día

## Formato del Archivo JSON

El archivo JSON contiene:

```json
{
  "full_discount_tickets": {
    "total": 79,
    "amount": 7855,
    "by_month": { ... },
    "tickets": [ ... ]
  },
  "unpaid_tickets": { ... },
  "voided_with_payments": { ... },
  "payment_mismatches": { ... },
  "drawer_pull_discrepancies": { ... }
}
```

## Requisitos

- PHP 8.2+
- Laravel 12+
- Acceso a base de datos PostgreSQL configurado en `.env`
- Extensión PHP: `pdo_pgsql`

## Tiempo de Ejecución

- Análisis de 3 meses: ~2-3 minutos
- Análisis de 1 mes: ~30-60 segundos

## Interpretación de Resultados

### Resultados Normales
- **0-5 tickets con problemas por mes:** Aceptable
- **Diferencia en reportes < 1%:** Dentro de tolerancia

### Señales de Alerta
- **> 20 tickets con descuento 100% por mes:** Investigar política de descuentos
- **> 10 tickets no pagados:** Revisar proceso de cierre
- **Anulaciones crecientes:** Posible problema en el código

### Señales Críticas
- **Diferencia en reportes > 10%:** URGENTE - revisar lógica de reportes
- **Triple registro en anulaciones:** CRÍTICO - corregir inmediatamente
- **Discrepancias crecientes mes a mes:** Problema sistémico

## Solución de Problemas

### Error: "No se puede conectar a la base de datos"
- Verifica las credenciales en `.env`
- Asegúrate de que PostgreSQL esté corriendo
- Verifica que el puerto sea el correcto (default: 5433)

### Error: "Undefined column"
- La estructura de la base de datos puede haber cambiado
- Revisa que las tablas existan: `ticket`, `transactions`, `drawer_pull_report`
- Ejecuta `php artisan migrate` para actualizar

### El script se detiene sin resultados
- Verifica que existan datos para el período seleccionado
- Revisa los logs de Laravel: `storage/logs/laravel.log`
- Ejecuta con mayor detalle: `php -d display_errors=1 scripts/analyze_sales_discrepancies.php`

## Acciones Recomendadas Basadas en Resultados

### Si detectas tickets con descuento 100%:
1. Revisa el controller de descuentos
2. Verifica que se registre el monto real (no literal "100")
3. Implementa validación de formato

### Si detectas tickets no pagados:
1. Agrega validación al cerrar tickets
2. Implementa alerta al cajero
3. Crea proceso de revisión diaria

### Si detectas anulaciones con triple registro:
1. **URGENTE:** Revisa el módulo de anulaciones
2. Implementa transacción atómica
3. Limpia registros duplicados

### Si detectas discrepancias en reportes:
1. **CRÍTICO:** Compara SQL del reporte vs realidad
2. Valida filtros de fecha y terminal
3. Regenera reportes históricos

## Mantenimiento

### Frecuencia Recomendada
- **Diario:** Para períodos activos o si hay cambios recientes
- **Semanal:** En operación normal
- **Mensual:** Para análisis de tendencias

### Actualización del Script
El script está en `scripts/analyze_sales_discrepancies.php`. Puedes:
- Agregar nuevas categorías de análisis
- Modificar los umbrales de alertas
- Cambiar el formato de salida

## Contacto y Soporte

Para reportar errores o sugerencias sobre este script:
- Revisa el análisis completo en `ANALISIS_DISCREPANCIAS_VENTAS_AGO_OCT_2025.md`
- Consulta los logs en `storage/logs/`

## Changelog

### Versión 1.0 (2025-11-05)
- ✅ Análisis inicial de agosto-octubre 2025
- ✅ Detección de 5 categorías de problemas
- ✅ Generación de JSON y resumen visual
- ✅ Identificación de causas raíz
