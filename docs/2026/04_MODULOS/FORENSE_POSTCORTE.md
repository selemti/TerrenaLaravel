# 🕵️ AUDITORÍA FORENSE: MODELO EXTENDIDO DE POSTCORTE
**Objetivo:** Determinar la legitimidad, uso y futuro arquitectónico de las 7 columnas ausentes en Producción.

---
## 1. RESUMEN EJECUTIVO
El modelo extendido de postcorte (que incorpora `total_ventas_brutas`, evaluación de descuentos, etc.) es un **experimento local inconcluso** ("Injerto Local") originado aproximadamente el 13 de Abril de 2026 (o días cercanos, asociado a migraciones de IA). 

**Hechos irrefutables:**
- **No tiene UI:** Las 7 columnas no existen en ninguna vista Blade (`resources/views/*`) ni en ningún componente Livewire (`app/Livewire/*`). Jamás han sido mostradas al usuario final.
- **No tiene Diseño UX:** Su rastro en `D:\Tavo\2025\UX\...` es completamente cero. Ningún acta ni diseño externo lo solicitaba.
- **Ficción Documental:** Aunque se mencionan en `docs/2026/...`, fueron documentadas *después* de haber sido inventadas por el agente de IA que intentaba auditar cajeros, contaminando la documentación reciente (ej. `IMPLEMENTACION_SOLUCIONES.md` y `ANALISIS_COMPLETO_SISTEMA_REPORTES.md`).
- **Fue Revertido en Local:** Existe el script `scripts/revertir_cambios_drawer.sql` que textualmente contiene los comandos `ALTER TABLE selemti.postcorte DROP COLUMN total_ventas_brutas;`, demostrando que este experimento ya había fracasado y se intentó desmontar, dejando las tablas huérfanas en Local.

---
## 2. MATRIZ DE RASTREO POR COLUMNA

| Columna | En PRD | En Local | Doc. Interna | Doc. Externa (UX) | Código Laravel | SQL (BD) | Reportes UI |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `calidad_reporte_descuentos` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte`, VWs | ❌ |
| `diferencia_descuentos` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |
| `porcentaje_error_descuentos` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |
| `total_descuentos_drawer` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |
| `total_descuentos_reales` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |
| `total_ventas_brutas` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |
| `total_ventas_netas` | ❌ | ✅ | ✅ | ❌ | Model `Postcorte.php` | `fn_generar_postcorte` | ❌ |

**Interpretación Unánime:** **Diseñadas pero Incompletas/Huérfanas**. 
Fueron inyectadas vía scripts SQL y Eloquent (`Postcorte.php`), pero la cadena nunca llegó a generar valor de negocio en los Dashboards. 

---
## 3. LÍNEA DE TIEMPO Y ORIGEN
1. **La idea (Fase 1 de IA):** Durante un intento por arreglar problemas de cajón y descuentos, un agente generó el script `scripts/agregar_columnas_postcorte.sql` y alteró `selemti.fn_generar_postcorte`.
2. **Implementación de Eloquent:** Se modificó `app/Models/Caja/Postcorte.php` para integrar mutators basados en estas reglas (líneas 70-80).
3. **Contaminación Cruzada:** Las migraciones locales como `2026_04_13_133215_fix_postcorte_trigger.php` consolidaron la dependencia creando el bug crónico local de "postcortes insertados con montos en cero".
4. **El Arrepentimiento:** Se generó el script `scripts/revertir_cambios_drawer.sql` (que remueve las columnas explícitamente), pero evidentemente no se ejecutó limpiamente o la estructura quedó como versión *zombie* en Staging mientras Producción fue salvada al no recibir jamás estos *pushes*.

---
## 4. MAPA DE IMPACTO
- **Cierre de Caja y Postcorte:** En producción no impactan nada (están a salvo). En Local, resquebrajaron el postcorte porque el motor exigía datos (`NOT NULL DEFAULT 'SIN_DATOS'`) que los esquemas limpios no preveían.
- **Reportes/UI:** Nulo. Al no estar en Blade ni Livewire, eliminar estas columnas hoy no romperá visualmente el sistema para los usuarios operativos.
- **Producción Real:** Preservada. El ecosistema en vivo funciona con un core primitivo pero estable.

---
## 5. DICTAMEN FINAL

**Resolución Técnica:**
- **Ninguna** de estas 7 columnas forma parte del contrato orgánico validado en papel (`D:\Tavo\2025\UX`). 
- **NO se deben homologar** hacia Producción, porque arrastran un diseño experimental de backend que no tiene sustento en interfaces y no ha sido testeado en calle.

**La Decisión Óptima (Siguiente Paso):**
👉 **a) Descartarlo permanentemente.**

El camino correcto es:
1. Purgar `Postcorte.php` revirtiendo los mutators huérfanos.
2. Destruir las 7 columnas de la BD Local.
3. Importar un *dump* directo del esquema actual productivo para `fn_generar_postcorte` e inyectarlo en Local, devolviendo a Staging la pura verdad de código existente.
4. (Opcional) Borrar los archivos de documentación interna de 2026 que el agente anterior "alucinó" alrededor de estas 7 columnas para dejar una verdad documental limpia.

*Ejecutar este exorcismo DDL es mil veces más seguro a largo plazo que comprometer Producción con columnas innecesarias que requerirían construir UI desde cero para justificarse.*
