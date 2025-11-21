# UI de Mapeos POS

## Descripción
Este componente proporciona una interfaz de usuario completa para la gestión de mapeos POS (Point of Sale) en el sistema Terrena Laravel. Permite establecer relaciones entre productos POS y recetas, lo cual es fundamental para el cálculo automático de consumos teóricos de inventario.

## Funcionalidades

### CRUD de Mapeos POS
- **Crear**: Nuevo mapeo entre PLU POS y receta
- **Leer**: Listado con filtros y paginación
- **Actualizar**: Edición de mapeos existentes
- **Eliminar**: Eliminación lógica de mapeos

### Tipos de Mapeo
- **MENU**: Mapeo de productos de menú a recetas
- **MODIFICADOR**: Mapeo de modificadores POS a impacto en receta/costo
- **COMBO**: Mapeo de productos compuestos a múltiples recetas

### Validaciones
- Control de vigencias (fechas desde/hasta)
- Control de versiones del mapeo
- No se altera el esquema de base de datos

### Reportes Integrados
- Identificación de ventas sin mapeo POS→Receta
- Identificación de modificadores sin mapeo POS
- Verificación diaria de mapeos incompletos

## Acceso
- Ruta: `/pos/mapping`
- Controlador: `App\Livewire\Pos\PosMap`
- Permisos requeridos: `pos.mapping.view`

## Consultas SQL Integradas
El componente incluye ejecución de las consultas del archivo `verification_queries_psql_v6.sql`:
- Consulta 1: Ventas del día sin mapeo POS→Receta (MENÚ)
- Consulta 1.b: Modificadores del día sin mapeo (MODIFIER)
- Consulta 2: Líneas inv_consumo_pos/_det pendientes (requiere reproceso o no procesado)

## Estructura de la Base de Datos
El componente interactúa con la tabla `selemti.pos_map` que contiene:
- `pos_system`: Sistema POS (FLOREANT, etc.)
- `plu`: Código PLU del producto POS
- `tipo`: Tipo de mapeo (MENU, MODIFICADOR, COMBO)
- `receta_id`: Receta asociada
- `valid_from`/`valid_to`: Fechas de vigencia
- `vigente_desde`: Fecha desde la que es vigente
- `meta`: Campos adicionales en formato JSON

## Integración con el Orquestador
Los mapeos POS son fundamentales para:
- Cálculo de consumos teóricos de inventario
- Recálculo de costos de recetas
- Generación de reportes de desviación
- Cierre diario de operaciones