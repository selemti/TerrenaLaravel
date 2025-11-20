# Sistema de Fondo de Caja Chica

**Versión:** 1.0
**Fecha:** Octubre 2025
**Autor:** Sistema TerrenaLaravel

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Documentación Disponible](#documentación-disponible)
3. [Arquitectura General](#arquitectura-general)
4. [Inicio Rápido](#inicio-rápido)
5. [Características Principales](#características-principales)

---

## 🎯 Introducción

El **Sistema de Fondo de Caja Chica** es un módulo completo para la gestión de fondos diarios asignados para gastos menores y pagos a proveedores en sucursales de restaurantes.

Este sistema es **independiente** del efectivo de ventas (cortes de caja POS) y proporciona un control exhaustivo sobre:
- Apertura de fondos diarios
- Registro de egresos y reintegros
- Gestión de comprobantes digitales
- Arqueo (conciliación) al cierre del día
- Sistema de aprobaciones y cierre definitivo
- Auditoría completa de cambios

---

## 📚 Documentación Disponible

La documentación está organizada en los siguientes archivos:

| Archivo | Descripción |
|---------|-------------|
| [01-ARQUITECTURA.md](01-ARQUITECTURA.md) | Arquitectura del sistema, componentes y estructura |
| [02-MODELOS.md](02-MODELOS.md) | Modelos Eloquent y relaciones |
| [03-MIGRACIONES.md](03-MIGRACIONES.md) | Estructura de base de datos y migraciones |
| [04-COMPONENTES-LIVEWIRE.md](04-COMPONENTES-LIVEWIRE.md) | Componentes Livewire y sus métodos |
| [05-VISTAS.md](05-VISTAS.md) | Vistas Blade y diseño UI |
| [06-FLUJOS-DE-TRABAJO.md](06-FLUJOS-DE-TRABAJO.md) | Flujos de trabajo y casos de uso |
| [07-PERMISOS.md](07-PERMISOS.md) | Sistema de permisos y roles |
| [08-API-METODOS.md](08-API-METODOS.md) | API interna y métodos públicos |
| [09-INSTALACION.md](09-INSTALACION.md) | Guía de instalación y configuración |
| [10-MANTENIMIENTO.md](10-MANTENIMIENTO.md) | Mantenimiento y solución de problemas |

---

## 🏗️ Arquitectura General

### Stack Tecnológico

- **Backend:** Laravel 12
- **Frontend:** Livewire 3.7 + Alpine.js
- **UI:** Bootstrap 5 + FontAwesome 6
- **Base de Datos:** PostgreSQL (schema `selemti`)
- **Autenticación:** Laravel Auth + Spatie Permissions
- **Archivos:** Laravel Storage (symlink)

### Componentes Principales

```
Sistema de Fondo de Caja
│
├── Modelos (Eloquent ORM)
│   ├── CashFund
│   ├── CashFundMovement
│   ├── CashFundArqueo
│   └── CashFundMovementAuditLog
│
├── Componentes Livewire
│   ├── Index (listado)
│   ├── Open (apertura)
│   ├── Movements (gestión)
│   ├── Arqueo (conciliación)
│   ├── Approvals (aprobaciones)
│   └── Detail (detalle)
│
├── Vistas Blade
│   └── livewire/cash-fund/*.blade.php
│
└── Rutas
    └── /cashfund/*
```

---

## 🚀 Inicio Rápido

### Requisitos Previos

- Laravel 12 instalado y configurado
- PostgreSQL con schema `selemti`
- Usuarios creados en tabla `users`
- Sucursales en `selemti.cat_sucursales`

### Instalación Básica

```bash
# 1. Ejecutar migraciones
php artisan migrate

# 2. Crear symlink de storage
php artisan storage:link

# 3. Configurar permisos (opcional pero recomendado)
php artisan tinker
>>> \Spatie\Permission\Models\Permission::create(['name' => 'approve-cash-funds']);
>>> \Spatie\Permission\Models\Permission::create(['name' => 'close-cash-funds']);
```

### Acceso al Sistema

```
URL: http://localhost/TerrenaLaravel/cashfund
Menú: Caja → Caja Chica
```

---

## ✨ Características Principales

### 1. **Gestión de Fondos**
- ✅ Apertura de fondo con monto inicial
- ✅ Asignación de responsable
- ✅ Descripción opcional para identificación
- ✅ Control por sucursal y fecha

### 2. **Registro de Movimientos**
- ✅ Egresos, Reintegros y Depósitos
- ✅ Métodos de pago: Efectivo y Transferencia
- ✅ Adjuntar comprobantes (PDF, imágenes)
- ✅ Información de proveedor
- ✅ Edición y eliminación con auditoría

### 3. **Sistema de Auditoría**
- ✅ Registro automático de todos los cambios
- ✅ Historial detallado por movimiento
- ✅ Trazabilidad completa (quién, cuándo, qué cambió)
- ✅ Valores anteriores y nuevos

### 4. **Arqueo y Conciliación**
- ✅ Conteo de efectivo físico
- ✅ Comparación automática con saldo teórico
- ✅ Detección de diferencias (faltantes/sobrantes)
- ✅ Observaciones y justificaciones

### 5. **Sistema de Aprobaciones**
- ✅ Estado EN_REVISION después del arqueo
- ✅ Revisión por usuarios autorizados
- ✅ Aprobación con validaciones
- ✅ Posibilidad de rechazar y reabrir
- ✅ Cierre definitivo (estado CERRADO)

### 6. **Vista de Detalle Completa**
- ✅ Información general del fondo
- ✅ Resumen financiero
- ✅ Tabla de movimientos
- ✅ Resultado del arqueo
- ✅ Timeline de eventos
- ✅ Formato de impresión profesional

### 7. **Impresión Profesional**
- ✅ Formato tipo estado de cuenta bancario
- ✅ Header con logo y datos del fondo
- ✅ Tabla optimizada para papel
- ✅ Resumen financiero destacado
- ✅ Footer con fecha de generación
- ✅ Optimizado para papel tamaño letter

---

## 🔐 Seguridad

- **Autenticación:** Todos los endpoints requieren usuario autenticado
- **Autorización:** Permisos granulares con Spatie Permission
- **Validación:** Validación exhaustiva en todos los formularios
- **Auditoría:** Registro completo de acciones
- **Integridad:** Transacciones de BD para operaciones críticas

---

## 📊 Estados del Fondo

```
ABIERTO
   │
   ├─→ Registrar movimientos
   ├─→ Adjuntar comprobantes
   ├─→ Editar/Eliminar movimientos
   │
   └─→ [Realizar Arqueo]
         │
         ↓
    EN_REVISION
         │
         ├─→ [Rechazar] → vuelve a ABIERTO
         │
         └─→ [Aprobar y Cerrar]
               │
               ↓
          CERRADO
          (solo lectura)
```

---

## 🆘 Soporte

Para más información, consulta los archivos de documentación específicos o contacta al equipo de desarrollo.

**Documentación Técnica:** Ver archivos 01-10 en esta carpeta
**Errores Comunes:** Ver [10-MANTENIMIENTO.md](10-MANTENIMIENTO.md)
**Instalación:** Ver [09-INSTALACION.md](09-INSTALACION.md)
