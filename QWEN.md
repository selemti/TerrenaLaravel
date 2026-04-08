# QWEN.md - Análisis de Directorios

## Análisis de Estructura de Proyectos

Se han identificado dos directorios principales de trabajo:

1. `C:\xampp3\htdocs\TerrenaLaravel` - Proyecto web Laravel (sistema TerrenaUI)
2. `D:\floreantpos\Orocube\floreantpos-code-r1960-trunk` - Código fuente de FloreantPOS

## Directorio 1: TerrenaLaravel (C:\xampp3\htdocs\TerrenaLaravel)

Este es un proyecto web construido con Laravel 12 y PostgreSQL, que implementa un sistema de gestión de inventarios y recursos llamado TerrenaUI (Project Terrena).

### Características principales:
- **Framework:** Laravel 12
- **Frontend:** Livewire 3, TailwindCSS, Bootstrap 5, Vite
- **Base de datos:** PostgreSQL 9.5
- **Autenticación:** Laravel Breeze con JWT-Auth y Laravel Sanctum
- **Documentación de API:** L5-Swagger
- **Gestión de permisos:** Spatie/laravel-permission

### Estructura de proyecto:
- `app/Livewire/` - Componentes Livewire para UI dinámica
- `app/Models/` - Modelos Eloquent (con subdirectorios como `app/Models/Caja/`)
- `app/Console/Commands/` - Comandos Artisan personalizados
- `routes/` - Definición de rutas web y API
- `resources/` - Vistas, CSS, JS (usando Vite)
- `database/migrations/` - Migraciones de base de datos

### Módulos clave:
- Caja Chica (Petty Cash)
- Gestión de inventario
- Recetas
- Compras
- Transferencias
- Catálogos
- Producción y KDS

## Directorio 2: FloreantPOS (D:\floreantpos\Orocube\floreantpos-code-r1960-trunk)

Este es un proyecto de punto de venta (POS) desarrollado en Java, específicamente FloreantPOS versión r1960.

### Características principales:
- **Lenguaje:** Java
- **Tipo de proyecto:** Punto de venta (POS) para restaurantes
- **Configuración:** Archivo `floreantpos.config.properties`
- **Gestión de dependencias:** Maven (`pom.xml`)

### Archivos importantes:
- `pom.xml` - Archivo de configuración de Maven con dependencias
- `floreantpos.config.properties` - Archivo de configuración del sistema
- `CHANGES` - Registro de cambios del proyecto

## Conexión entre ambos proyectos

Ambos proyectos están relacionados en el contexto de un sistema de gestión de restaurantes/hoteles:
- TerrenaLaravel actúa como sistema de gestión de inventarios y recursos
- FloreantPOS es el sistema de punto de venta que registra las ventas
- Los datos de ventas de FloreantPOS se analizan para conciliación con TerrenaLaravel

## Objetivo de análisis actual

El propósito actual es determinar cómo FloreantPOS/Jasper calcula el "Item Sales Grand Total" del día 2025-12-16 para implementar una funcionalidad de conciliación en TerrenaLaravel.

### Valores objetivo:
- Item Sales Grand Total: 631.00
- Discount: 8.8
- Net Sales: 622.20
- TTL VOIDS: 16.00 (en Exceptions Report)

## Recursos disponibles

- Acceso a PostgreSQL vía psql en `C:\Program Files (x86)\PostgreSQL\9.5\bin\psql`
- Base de datos `pos` con esquemas `selemti` y `public`
- Tablas relevantes en esquema `public`: `ticket`, `menu_item`, `ticket_item`, etc.
- Comandos Artisan disponibles para análisis