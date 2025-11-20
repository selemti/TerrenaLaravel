# 📚 ÍNDICE MAESTRO DE DEFINICIONES - TERRENA LARAVEL ERP

**Fecha**: 31 de octubre de 2025
**Versión**: 1.0
**Analista**: Qwen AI

---

## 🎯 Propósito del Directorio

Este directorio `docs/UI-UX/definición/` contiene la documentación completa y actualizada de cada módulo del sistema TerrenaLaravel ERP. Cada archivo representa la definición oficial de un módulo, incluyendo:

- Descripción general del módulo
- Componentes y funcionalidades
- Requerimientos técnicos y de UI/UX
- Integración con otros módulos
- KPIs asociados
- Flujos de trabajo
- Estados y transiciones
- Componentes técnicos
- Permisos y roles
- Consideraciones especiales

---

## 📁 Estructura de Documentación

```
docs/UI-UX/definición/
├── RESUMEN_EJECUTIVO.md              # Vista general del proyecto
├── ESPECIFICACIONES_TECNICAS.md      # Especificaciones técnicas completas
├── CajaChica.md                      # Sistema de fondo de caja
├── Catálogos.md                      # Entidades maestras
├── Compras.md                        # Módulo de compras y proveedores
├── Inventario.md                     # Gestión completa de inventario
├── Permisos.md                       # Control de acceso y seguridad
├── POS.md                            # Integración con Floreant POS
├── Producción.md                     # Planificación y ejecución de producción
├── Recetas.md                        # Gestión de recetas y costeo
├── Reportes.md                       # Dashboards y análisis
├── Transferencias.md                 # Movimientos internos entre almacenes
└── INDEX.md                         # Este archivo (índice maestro)
```

---

## 📊 Estado de los Módulos

### 🟢 Módulos Completos (>80%)
| Módulo | Backend | Frontend | API | Documentación | Estado |
|--------|---------|----------|-----|---------------|--------|
| **CajaChica** | 80% | 75% | 85% | 90% | ✅ Muy Bueno |
| **Catálogos** | 80% | 70% | 85% | 85% | ✅ Muy Bueno |
| **Permisos** | 80% | 75% | 85% | 90% | ✅ Muy Bueno |

### 🟡 Módulos en Desarrollo (60-80%)
| Módulo | Backend | Frontend | API | Documentación | Estado |
|--------|---------|----------|-----|---------------|--------|
| **Inventario** | 70% | 60% | 75% | 85% | ⚠️ Bueno |
| **POS** | 65% | 55% | 70% | 80% | ⚠️ Bueno |
| **Compras** | 60% | 50% | 65% | 80% | ⚠️ Regular |

### 🔴 Módulos en Progreso (<60%)
| Módulo | Backend | Frontend | API | Documentación | Estado |
|--------|---------|----------|-----|---------------|--------|
| **Recetas** | 50% | 40% | 55% | 75% | ⚠️ Regular |
| **Producción** | 30% | 20% | 35% | 70% | 🔴 Bajo |
| **Reportes** | 40% | 30% | 45% | 65% | 🔴 Bajo |
| **Transferencias** | 20% | 15% | 25% | 60% | 🔴 Crítico |

---

## 📚 Descripción de los Módulos

### 1. CajaChica.md
**Sistema de Fondo de Caja Chica**
Gestiona los fondos diarios asignados para gastos menudos y pagos a proveedores en sucursales de restaurantes.

**Componentes principales:**
- Gestión de fondos (apertura, estados)
- Registro de movimientos (egresos, reintegros, depósitos)
- Sistema de auditoría completo
- Arqueo y conciliación
- Sistema de aprobaciones
- Vista de detalle completa
- Impresión profesional

### 2. Catálogos.md
**Gestión de Entidades Maestras**
Administra todas las entidades maestras del sistema, incluyendo sucursales, almacenes, unidades de medida, proveedores y políticas de negocio.

**Componentes principales:**
- Sucursales con información detallada
- Almacenes con jerarquía y configuración
- Unidades de medida y conversiones
- Proveedores con información completa
- Políticas de stock configurables

### 3. Compras.md
**Gestión de Compras y Proveedores**
Administra todo el proceso de adquisición de bienes y servicios, desde la generación automática de sugerencias hasta la recepción de productos.

**Componentes principales:**
- Solicitudes y órdenes de compra
- Motor de reposición (Replenishment)
- Gestión de proveedores y precios
- Dashboard de sugerencias con razones del cálculo
- Recepciones en 5 pasos con validación de tolerancias

### 4. Inventario.md
**Gestión Integral de Inventario**
Gestiona todos los aspectos relacionados con los productos, materias primas y suministros del negocio.

**Componentes principales:**
- Items/Altas con wizard 2 pasos
- Recepciones con FEFO y snapshot de costo
- Lotes/caducidades con control FEFO
- Conteos físicos con estados (BORRADOR → EN_PROCESO → AJUSTADO)
- Transferencias entre almacenes (Borrador → Despachada → Recibida)
- Costos e inventario con funciones de cálculo históricas

### 5. Permisos.md
**Control de Acceso y Seguridad**
Gestiona el control de acceso al sistema mediante roles y permisos específicos utilizando Spatie/Laravel-Permission.

**Componentes principales:**
- Roles con asignación de permisos
- Permisos atómicos granulares
- Asignación de usuarios a roles
- Sistema de auditoría de cambios
- Prueba de roles (impersonate)

### 6. POS.md
**Integración con Floreant POS**
Gestiona la integración con el sistema de ventas Floreant POS, incluyendo el mapeo de menú, diagnóstico de tickets y control de disponibilidad en vivo.

**Componentes principales:**
- Mapeo de menú POS con items del sistema
- Diagnóstico de tickets problemáticos
- Reprocesamiento y reversa de ventas POS
- Disponibilidad en vivo con control de agotados

### 7. Producción.md
**Planificación y Ejecución de Producción**
Gestiona las órdenes de producción, planificación, ejecución y control de procesos productivos.

**Componentes principales:**
- Planificación Produmix diaria basada en demanda POS
- Ejecución de órdenes (plan → consume → complete → post)
- Control de mermas y rendimientos
- KPIs de eficiencia y producción

### 8. Recetas.md
**Gestión de Recetas y Costeo**
Gestiona las fórmulas de producción de productos terminados, incluyendo ingredientes, cantidades, rendimientos y costos.

**Componentes principales:**
- Editor avanzado de recetas con ID, PLU, ingredientes, merma
- Implosión automática a insumos crudos inventariables
- Costeo histórico por versión con snapshots automáticos
- Alertas de costo con umbral configurable

### 9. Reportes.md
**Dashboards y Análisis**
Proporciona herramientas para la generación, visualización y análisis de información del negocio.

**Componentes principales:**
- Dashboard principal con KPIs de ventas
- Reportes especializados por área funcional
- Exportaciones CSV/PDF de reportes
- Drill-down jerárquico desde resumen a detalle

### 10. Transferencias.md
**Movimientos Internos de Inventario**
Gestiona los movimientos internos de inventario entre almacenes y sucursales.

**Componentes principales:**
- Flujo 3 pasos: Borrador → Despachada → Recibida
- Confirmaciones parciales y discrepancias (corto/exceso)
- Botón "Recibir" en destino
- UI de "reconciliación" simple
- Integración con mov_inv para generar movimientos negativos/positivos

---

## 🔗 Referencias Cruzadas

### Documentación Principal
- `docs/UI-UX/MASTER/` - Documentación maestra del proyecto
- `docs/BD/` - Normalización y esquema de base de datos
- `docs/Seguridad/SECURITY_AND_ROLES.md` - Políticas de seguridad y roles

### Código Fuente
- `app/Models/` - Modelos Eloquent
- `app/Services/` - Lógica de negocio
- `app/Http/Controllers/` - Controladores
- `app/Http/Livewire/` - Componentes reactivos
- `routes/` - Rutas web y API
- `resources/views/` - Vistas Blade

### Infraestructura
- `database/migrations/` - Migraciones de base de datos
- `database/seeders/` - Datos de prueba
- `config/` - Configuración del sistema

---

## 📞 Mantenimiento y Actualización

### Procedimiento de Actualización
1. **Antes de modificar**: Leer documentación existente
2. **Durante el desarrollo**: Actualizar definición en paralelo
3. **Después de implementar**: Revisar y validar cambios
4. **En producción**: Marcar versión y registrar changelog

### Responsables
- **Documentación técnica**: Equipo de desarrollo
- **Documentación funcional**: Equipo de análisis de negocio
- **Revisión y aprobación**: Tech Lead / Arquitecto

### Frecuencia de Actualización
- **Cambios críticos**: Inmediata
- **Nuevas funcionalidades**: Antes de implementar
- **Mejoras menores**: Semanal
- **Revisión general**: Mensual

---

## 🚀 Próximos Pasos

### Inmediatos (Esta Semana)
1. ✅ Consolidar todas las definiciones en este directorio
2. ⏳ Revisar y actualizar definiciones con hallazgos recientes
3. ⏳ Crear índice maestro de definiciones
4. ⏳ Establecer proceso de mantenimiento

### Corto Plazo (Próximas 2 Semanas)
1. ⏳ Completar definiciones de módulos en progreso
2. ⏳ Crear guía de estilo para nuevas definiciones
3. ⏳ Establecer sistema de versionado de documentación
4. ⏳ Integrar con sistema de control de cambios

### Mediano Plazo (Próximo Mes)
1. ⏳ Crear plantillas reutilizables para nuevos módulos
2. ⏳ Implementar sistema de búsqueda en documentación
3. ⏳ Crear índice temático cruzado
4. ⏳ Establecer proceso de revisión periódica

---

**🎉 Documentación completada y organizada**

Esta estructura proporciona una base sólida para el desarrollo, mantenimiento y expansión del sistema TerrenaLaravel ERP. Mantengamos esta documentación actualizada para asegurar la continuidad del proyecto.