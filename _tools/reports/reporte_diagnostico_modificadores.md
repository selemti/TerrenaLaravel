# Reporte Final: Diagnóstico de Inconsistencias en Modificadores

## Resumen Ejecutivo

El análisis de la base de datos `public` ha revelado una inconsistencia **crítica y sistémica** en el registro de modificadores de ítems. Cerca del **99.8%** de los modificadores registrados desde noviembre de 2025 tienen un `group_id` incorrecto en la tabla `public.ticket_item_modifier`. Este error invalida la data histórica para análisis de costos, inventarios y popularidad de productos, afectando directamente la toma de decisiones del negocio.

El problema no se debe a errores aislados, sino a un fallo fundamental en la lógica de la aplicación (probablemente el punto de venta) que asigna un `group_id` incorrecto y estático a los modificadores en el momento de la venta.

## Hallazgos Clave

### 1. Impacto Cuantificado
- **Total de Inconsistencias (desde Ene-2025):** 9,269 registros.
- **Monto Afectado (desde Ene-2025):** $25,982.
- **Items Únicos Afectados:** 45.
- **Tasa de Error (Nov-Dic 2025):** Superior al 99.7%. El problema se ha generalizado y es la norma, no la excepción.

### 2. Items Críticos Más Afectados
Los siguientes ítems concentran la mayor cantidad de inconsistencias y representan un riesgo alto para el control de inventario y análisis de rentabilidad:

1.  **Taco de Guisado:** Se registra `group_id` `9` o `27` en lugar del correcto `33`.
2.  **Torta:** Se registra `group_id` `19` en lugar del correcto `25`.
3.  **Empanada:** Se registra `group_id` `8` en lugar del correcto `3`.
4.  **Chilaquiles:** Se registra `group_id` `64` (para proteína) y `63` (para salsa) en lugar de los correctos `21` y `20` respectivamente.

### 3. Patrón Identificado
El error es consistente. Para un mismo ítem, siempre se graba el mismo `group_id` incorrecto. Por ejemplo, todos los modificadores de "Empanada" se guardan con `group_id = 8`, cuando el correcto es `3`. Esto sugiere fuertemente que el valor incorrecto está hardcodeado o es el resultado de una lógica de mapeo defectuosa en el sistema que origina la transacción.

### 4. Riesgos Potenciales
- **Inventario Inexacto:** El consumo de ingredientes ligados a modificadores se está registrando de forma incorrecta, llevando a discrepancias entre el stock teórico y el real.
- **Costeo Erróneo:** El costo de los platos con modificadores es incorrecto, afectando el cálculo de la rentabilidad (Food Cost).
- **Reportes de Venta Inservibles:** Los reportes de ventas por grupo de modificadores (ej. "¿cuántos rellenos de queso se vendieron?") son completamente inútiles y engañosos.
- **Toma de Decisiones Comprometida:** Decisiones de compra, producción y marketing basadas en estos datos serán erróneas.

## Recomendaciones Específicas para Corrección

### **FASE 1: Contención Inmediata (Aplicación)**

1.  **Auditoría del Código Fuente del POS:** Es **urgente** identificar la sección del código (del sistema de punto de venta o middleware) que inserta los registros en `public.ticket_item_modifier`. La lógica que asigna el `group_id` debe ser corregida para que utilice el valor correcto de `public.menu_modifier.group_id` asociado al `item_id` del modificador.

### **FASE 2: Corrección de Datos Históricos (Base de Datos)**

1.  **Crear un Script de Actualización (UPDATE):** Se debe desarrollar un script SQL que corrija los `group_id` incorrectos en la tabla `public.ticket_item_modifier` para todos los registros históricos. El script debe usar la siguiente lógica:
    ```sql
    UPDATE public.ticket_item_modifier as tim
    SET group_id = mm.group_id
    FROM public.menu_modifier as mm
    WHERE tim.item_id = mm.id
      AND tim.group_id != mm.group_id;
    ```
2.  **Ejecución Controlada:** Este script debe ser ejecutado en un entorno de pruebas primero. Para producción, se debe ejecutar en una ventana de bajo tráfico, previa copia de seguridad de la tabla `public.ticket_item_modifier`. **Se requiere autorización explícita antes de ejecutar cualquier `UPDATE` en el esquema `public`.**

### **FASE 3: Verificación y Monitoreo**

1.  **Recálculo de Reportes:** Una vez corregidos los datos, los reportes de ventas e inventario deben ser recalculados.
2.  **Monitoreo Continuo:** Implementar una alerta o un reporte diario que verifique si persisten las inconsistencias (`tim.group_id != mm.group_id`) para asegurar que la corrección en la aplicación fue efectiva.

Se ha finalizado el diagnóstico. Quedo a la espera de la autorización para proceder con la fase de corrección.
