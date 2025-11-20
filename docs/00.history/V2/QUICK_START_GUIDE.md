# Gu��a Rápida de Inicio - Terrena POS

## 🎯 Resumen

Este documento proporciona una guía completa para usar el sistema Terrena POS, un sistema integral de gestión para restaurantes con múltiples ubicaciones.

## 📊 Módulos Disponibles

### 1. Dashboard Principal
**URL:** `/dashboard`

Vista general del negocio con KPIs principales:
- Ventas del d��a por sucursal y terminal
- Gráficos de ventas por hora
- Top productos más vendidos
- Análisis por familia de productos
- Ticket promedio
- Formas de pago

### 2. Inventario
**URL:** `/inventario`

Gestión completa de inventario con:
- **KPIs en tiempo real:**
  - Total de items distintos
  - Valor total del inventario
  - Items con stock bajo
  - Items próximos a caducar

- **Filtros:**
  - Búsqueda por SKU/nombre/descripción
  - Filtro por sucursal
  - Filtro por categoría
  - Estados: activos, inactivos, bajo stock, por caducar

- **Funciones:**
  - Ver kardex completo de cualquier item
  - Movimientos rápidos (entrada, salida, ajuste, merma)
  - Exportación de datos

**Endpoints API:**
- `GET /api/inventory/kpis` - Métricas del dashboard
- `GET /api/inventory/stock/list` - Listado de stock
- `GET /api/inventory/items/{id}/kardex` - Historial de movimientos
- `POST /api/inventory/movements` - Crear movimiento rápido

### 3. Catálogos

Todos los catálogos están accesibles desde `/catalogos/*`

#### 3.1 Unidades de Medida
**URL:** `/catalogos/unidades`

Catálogo de unidades con 22 unidades precargadas:

**Peso (BASE: KG):**
- KG - Kilogramo
- GR - Gramo
- MG - Miligramo
- TON - Tonelada
- LB - Libra (Imperial)
- OZ - Onza (Imperial)

**Volumen (BASE: LT):**
- LT - Litro
- ML - Mililitro
- MC - Metro Cúbico
- GAL - Galón (Imperial)
- FLOZ - Onza Fluida (Imperial)
- TAZA, CDTA, CDSP - Unidades culinarias

**Unidad:**
- PZ - Pieza
- PAQ - Paquete
- CAJA - Caja
- COST - Costal
- PORC - Porción
- PLAT - Plato

**Tiempo:**
- MIN - Minuto
- HR - Hora

**Funciones:**
- Crear/Editar/Eliminar unidades
- Filtros por tipo y categoría
- Configurar factores de conversión
- Definir decimales por unidad

#### 3.2 Sucursales
**URL:** `/catalogos/sucursales`

**Sucursales precargadas:**
1. **CENTRO** - Terrena Centro Histórico
2. **POLANCO** - Terrena Polanco
3. **ROMA** - Terrena Roma Norte
4. **COYOACAN** - Terrena Coyoacán
5. **CENTRAL** - Centro de Distribución Central

**Campos:**
- Clave única (ej. CENTRO, POLANCO)
- Nombre completo
- Ubicación/dirección
- Estado activo/inactivo

#### 3.3 Almacenes
**URL:** `/catalogos/almacenes`

**17 almacenes precargados** distribuidos por sucursal:

**Por Sucursal:**
- Cocina
- Barra
- Almacén Seco
- Refrigeración
- Congelación (solo CD)

**Campos:**
- Clave única
- Nombre
- Sucursal asociada
- Estado activo/inactivo

#### 3.4 Proveedores
**URL:** `/catalogos/proveedores`

**8 proveedores precargados:**
1. Abarrotes Don Pepe SA de CV
2. Carnes Selectas del Norte SA
3. Lacteos La Vaquita SA de CV
4. Frutas y Verduras del Mercado SA
5. Distribuidora de Bebidas Premium SA
6. Panaderia y Reposteria El Horno SA
7. Mariscos y Pescados Frescos del Golfo SA
8. Desechables y Empaques Eco SA de CV

**Campos:**
- RFC (único)
- Nombre/Razón Social
- Teléfono
- Email
- Estado activo/inactivo

#### 3.5 Políticas de Stock
**URL:** `/catalogos/stock-policy`

Definir niveles mínimos y máximos de inventario por:
- Item
- Sucursal
- Almacén

**Funciones:**
- Establecer stock mínimo
- Establecer stock máximo
- Alertas automáticas cuando stock < mínimo

#### 3.6 Conversiones de Unidades
**URL:** `/catalogos/uom`

Gestionar conversiones entre unidades:
- Definir factores de conversión personalizados
- Convertir entre sistemas métrico/imperial
- Conversiones culinarias

### 4. Recetas
**URL:** `/recipes`

Gestión de recetas y costeo:
- Crear recetas con ingredientes
- Calcular costos automáticamente
- Versionado de recetas
- Modificadores y variaciones
- Órdenes de producción

**Editor de Recetas:** `/recipes/editor/{id}`

### 5. Compras
**URL:** `/compras`

Módulo de compras y recepciones:
- Crear órdenes de compra
- Recibir mercancía
- Asignar lotes y fechas de caducidad
- Actualizar inventario automáticamente

**Recepciones de Inventario:** `/inventory/receptions`

### 6. Producción
**URL:** `/produccion`

Control de producción:
- Órdenes de producción
- Consumo de ingredientes
- Producción terminada
- Trazabilidad de lotes

### 7. Personal
**URL:** `/personal`

Gestión de personal (en desarrollo):
- Empleados
- Horarios
- Asistencia
- Nómina

### 8. KDS (Kitchen Display System)
**URL:** `/kds`

Sistema de pantalla para cocina:
- Visualización de tickets en tiempo real
- Organización por estaciones
- Control de tiempos de preparación
- Notificaciones de tickets listos

### 9. Caja
**URL:** `/caja/cortes`

Módulo de caja y cortes:
- Precortes (durante turno)
- Postcortes (cierre de turno)
- Conciliación de efectivo
- Sesiones de caja
- Formas de pago

### 10. Reportes
**URL:** `/reportes`

Centro de reportes:
- Ventas por período
- Análisis de productos
- Rotación de inventario
- Márgenes y costos
- Reportes personalizados

## 🔑 Endpoints API Principales

### Inventario
```
GET  /api/inventory/kpis              - KPIs del dashboard
GET  /api/inventory/stock/list        - Listado de stock
GET  /api/inventory/items             - Items de inventario
GET  /api/inventory/items/{id}        - Detalle de item
POST /api/inventory/items             - Crear item
PUT  /api/inventory/items/{id}        - Actualizar item
DEL  /api/inventory/items/{id}        - Desactivar item
GET  /api/inventory/items/{id}/kardex - Kardex del item
POST /api/inventory/movements         - Crear movimiento
```

### Catálogos
```
GET /api/catalogs/categories      - Categorías de productos
GET /api/catalogs/sucursales      - Sucursales
GET /api/catalogs/almacenes       - Almacenes
GET /api/catalogs/movement-types  - Tipos de movimiento
```

### Reportes
```
GET /api/reports/kpis/sucursal     - KPIs por sucursal
GET /api/reports/kpis/terminal     - KPIs por terminal
GET /api/reports/ventas/familia    - Ventas por familia
GET /api/reports/ventas/hora       - Ventas por hora
GET /api/reports/ventas/top        - Top productos
GET /api/reports/stock/val         - Stock valorizado
```

### Caja
```
GET  /api/caja/sesiones/activa     - Sesión activa
GET  /api/caja/precortes/{id}      - Ver precorte
POST /api/caja/precortes           - Crear precorte
GET  /api/caja/postcortes/{id}     - Ver postcorte
POST /api/caja/postcortes          - Crear postcorte
```

## 💡 Flujos de Trabajo Típicos

### Flujo 1: Recepción de Mercancía

1. Ir a `/inventory/receptions/new`
2. Seleccionar proveedor
3. Agregar items recibidos con cantidades y precios
4. Asignar lotes y fechas de caducidad
5. Guardar recepción
6. El sistema automáticamente:
   - Crea registros en el kardex
   - Actualiza stock actual
   - Recalcula costos promedio (WAC)

### Flujo 2: Crear Receta

1. Ir a `/recipes`
2. Clic en "Nueva Receta"
3. Ingresar nombre y categoría
4. Agregar ingredientes con cantidades
5. El sistema automáticamente:
   - Calcula costo total
   - Sugiere precio de venta
   - Guarda versión de la receta

### Flujo 3: Movimiento de Inventario

1. Ir a `/inventario`
2. Buscar el item
3. Clic en "Movimiento Rápido"
4. Seleccionar tipo (entrada/salida/ajuste/merma)
5. Ingresar cantidad y razón
6. Guardar
7. El sistema automáticamente:
   - Registra en kardex
   - Actualiza stock
   - Genera trazabilidad

### Flujo 4: Consultar Kardex

1. Ir a `/inventario`
2. Buscar el item
3. Clic en "Ver Kardex"
4. Ver historial completo con:
   - Fecha y hora
   - Tipo de movimiento
   - Entradas/Salidas
   - Saldo acumulado
   - Referencia del movimiento

### Flujo 5: Precorte y Postcorte

1. Abrir sesión de caja (automático al iniciar turno)
2. Durante el turno: `/caja/cortes` → "Nuevo Precorte"
   - Contar efectivo
   - Verificar vs. sistema
   - Imprimir reporte
3. Al cerrar: "Nuevo Postcorte"
   - Conteo final
   - Conciliación total
   - Cierre de sesión
   - Depósito bancario

## 🎨 Características de la Interfaz

### Filtros Inteligentes
Todos los listados incluyen:
- Búsqueda en tiempo real
- Filtros combinables
- Paginación
- Ordenamiento por columnas

### Livewire Components
Interfaces reactivas sin recargar página:
- Edición inline
- Modales de creación/edición
- Notificaciones toast
- Validación en tiempo real

### Responsive Design
- Adaptado para desktop, tablet y móvil
- Menú colapsable en móviles
- Tablas responsivas con scroll horizontal

## 🔧 Comandos Útiles

### Desarrollo
```bash
# Iniciar servidor de desarrollo
composer dev

# Limpiar caché
php artisan config:clear
php artisan route:clear
php artisan cache:clear

# Ver rutas
php artisan route:list

# Ver rutas de un módulo específico
php artisan route:list --path=inventory
php artisan route:list --path=catalogos
```

### Base de Datos
```bash
# Ejecutar migraciones
php artisan migrate

# Poblar catálogos con datos de ejemplo
php artisan db:seed --class=RestaurantCatalogsSeeder

# Resetear base de datos
php artisan migrate:fresh --seed
```

## 📝 Notas Importantes

### Conexión a Base de Datos
- **SQLite**: Modelos de inventario, recetas, catálogos (conexión: `database`)
- **PostgreSQL**: Módulo de caja y POS (conexión: `pgsql`)

### Validaciones
- SKUs deben ser únicos
- RFCs de proveedores deben ser únicos
- Códigos de unidades: 2-5 letras mayúsculas
- Stock no puede ser negativo (excepto con permisos especiales)

### Permisos
Sistema basado en roles (Spatie Permission):
- **Admin**: Acceso total
- **Gerente**: Gestión operativa
- **Cajero**: Solo módulo de caja
- **Cocina**: Solo KDS y producción

## 🆘 Solución de Problemas

### Error: "No existe la tabla X"
```bash
php artisan migrate
```

### Error: "No hay datos en catálogos"
```bash
php artisan db:seed --class=RestaurantCatalogsSeeder
```

### Error: "CORS" o "419 Session Expired"
```bash
php artisan config:clear
php artisan route:clear
```

### Error: "Class not found"
```bash
composer dump-autoload
```

## 🚀 Próximos Pasos

1. Configurar políticas de stock para items críticos
2. Cargar catálogo completo de productos
3. Crear recetas de platillos del menú
4. Configurar usuarios y permisos
5. Capacitar personal en el uso del sistema

---

*Última actualización: 2025-10-21*
*Versión del sistema: 2.0*
