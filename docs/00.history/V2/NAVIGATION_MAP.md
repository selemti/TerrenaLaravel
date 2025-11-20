# Mapa de Navegación - Terrena POS

## 📋 **DIAGNÓSTICO ACTUAL**

### ✅ **Vistas Principales Accesibles (en Menú Sidebar)**

| Item Menú | URL | Tipo Vista | Estado |
|-----------|-----|------------|--------|
| Dashboard | `/dashboard` | Blade estático | ✅ Funcional |
| Cortes de Caja | `/caja/cortes` | Controller | ✅ Funcional |
| Inventario | `/inventario` | Blade + JS | ✅ Funcional |
| Compras | `/compras` | Blade estático | ⚠️ Placeholder |
| Recetas | `/recetas` | Blade estático | ⚠️ Placeholder |
| Producción | `/produccion` | Blade estático | ⚠️ Placeholder |
| Reportes | `/reportes` | Blade placeholder | ⚠️ Placeholder |
| Configuración | `/admin` | Blade placeholder | ⚠️ Placeholder |
| Personal | `/personal` | Blade estático | ⚠️ Placeholder |

### ❌ **Vistas HUÉRFANAS (sin acceso desde menú)**

#### Catálogos Livewire (funcionan pero no están en menú)
| Componente | URL | Estado |
|------------|-----|--------|
| Unidades de Medida | `/catalogos/unidades` | ✅ Funcional con datos |
| Conversiones UOM | `/catalogos/uom` | ✅ Funcional |
| Almacenes | `/catalogos/almacenes` | ✅ Funcional con datos |
| Proveedores | `/catalogos/proveedores` | ✅ Funcional con datos |
| Sucursales | `/catalogos/sucursales` | ✅ Funcional con datos |
| Políticas de Stock | `/catalogos/stock-policy` | ✅ Funcional |

#### Inventario Livewire (huérfanos)
| Componente | URL | Estado |
|------------|-----|--------|
| Items de Inventario | `/inventory/items` | ✅ Funcional |
| Recepciones | `/inventory/receptions` | ✅ Funcional |
| Nueva Recepción | `/inventory/receptions/new` | ✅ Funcional |
| Lotes/Batches | `/inventory/lots` | ✅ Funcional |

#### Recetas Livewire (parcialmente huérfanos)
| Componente | URL | Estado |
|------------|-----|--------|
| Índice de Recetas | `/recipes` | ✅ Funcional |
| Editor de Recetas | `/recipes/editor/{id?}` | ✅ Funcional |

#### KDS
| Componente | URL | Estado |
|------------|-----|--------|
| Kitchen Display | `/kds` | ✅ Funcional |

---

## 🎯 **SOLUCIÓN PROPUESTA**

### Opción 1: Menú con Submenús (RECOMENDADO)

Reorganizar el sidebar con estructura jerárquica:

```
📊 Dashboard
💰 Cortes de Caja
📦 Inventario
   ├── Vista General (/inventario)
   ├── Items (/inventory/items)
   ├── Lotes (/inventory/lots)
   └── Recepciones (/inventory/receptions)
🛒 Compras
   └── Recepciones (/inventory/receptions)
🍳 Recetas
   ├── Recetas (/recipes)
   └── Editor (/recipes/editor)
🏭 Producción
📊 Reportes
👥 Personal
⚙️ Configuración
   ├── Catálogos (/catalogos) [Vista índice nueva]
   ├── Sucursales (/catalogos/sucursales)
   ├── Almacenes (/catalogos/almacenes)
   ├── Unidades (/catalogos/unidades)
   ├── Conversiones (/catalogos/uom)
   ├── Proveedores (/catalogos/proveedores)
   └── Políticas Stock (/catalogos/stock-policy)
📺 KDS (acceso directo o en menú)
```

### Opción 2: Vista Índice de Catálogos

Crear `/catalogos` como vista de tarjetas con acceso a todos los catálogos:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  📍 Sucursales  │  │  🏪 Almacenes   │  │  📏 Unidades    │
│                 │  │                 │  │                 │
│  5 sucursales   │  │  17 almacenes   │  │  22 unidades    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 📊 **INVENTARIO COMPLETO DE VISTAS**

### Por Módulo

#### 1. **Dashboard y Reportes**
- `/dashboard` - Vista principal con KPIs
- `/reportes` - Placeholder (pendiente implementar)

#### 2. **Caja**
- `/caja/cortes` - Cortes de caja

#### 3. **Inventario**
- `/inventario` - Dashboard de inventario (✅ Completo)
- `/inventory/items` - Gestión de items Livewire
- `/inventory/lots` - Gestión de lotes
- `/inventory/receptions` - Listado de recepciones
- `/inventory/receptions/new` - Nueva recepción

#### 4. **Compras**
- `/compras` - Placeholder
- (usa `/inventory/receptions` para recepciones)

#### 5. **Recetas**
- `/recetas` - Placeholder blade estático
- `/recipes` - Índice Livewire
- `/recipes/editor/{id?}` - Editor Livewire

#### 6. **Producción**
- `/produccion` - Placeholder

#### 7. **Catálogos** (TODOS sin acceso en menú)
- `/catalogos` - **NO EXISTE** (hay que crear índice)
- `/catalogos/sucursales` - ✅ Livewire funcional
- `/catalogos/almacenes` - ✅ Livewire funcional
- `/catalogos/unidades` - ✅ Livewire funcional
- `/catalogos/uom` - ✅ Livewire funcional
- `/catalogos/proveedores` - ✅ Livewire funcional
- `/catalogos/stock-policy` - ✅ Livewire funcional

#### 8. **KDS**
- `/kds` - Kitchen Display System

#### 9. **Personal**
- `/personal` - Placeholder

#### 10. **Configuración**
- `/admin` - Placeholder

---

## 🔧 **PLAN DE IMPLEMENTACIÓN**

### Fase 1: Vista Índice de Catálogos ✅
- [ ] Crear `/catalogos` con tarjetas de acceso rápido
- [ ] Mostrar contador de registros en cada catálogo
- [ ] Botones de acceso directo

### Fase 2: Actualizar Sidebar ✅
- [ ] Cambiar "Configuración" por menú desplegable
- [ ] Agregar submenú "Catálogos" bajo Configuración
- [ ] Agregar enlaces a todos los catálogos
- [ ] Agregar submenú bajo "Inventario" para vistas Livewire

### Fase 3: Organizar Vistas Duplicadas ✅
- [ ] Decidir: `/recetas` (blade) vs `/recipes` (Livewire)
- [ ] Unificar acceso a recepciones (Compras e Inventario)
- [ ] Documentar qué vista usar para cada función

### Fase 4: Completar Placeholders ⏭️
- [ ] Implementar `/compras` completo
- [ ] Implementar `/produccion`
- [ ] Implementar `/personal`
- [ ] Implementar `/admin`

---

## 🗺️ **MAPA VISUAL DE NAVEGACIÓN**

```
┌─────────────────────────────────────────────────────────────┐
│                     TERRENA POS                             │
│                                                             │
│  SIDEBAR                          VISTAS PRINCIPALES        │
│  ════════                         ══════════════════        │
│                                                             │
│  📊 Dashboard ──────────────────► /dashboard               │
│                                                             │
│  💰 Cortes de Caja ─────────────► /caja/cortes             │
│                                                             │
│  📦 Inventario                                              │
│     ├─ Vista General ───────────► /inventario              │
│     ├─ Items ───────────────────► /inventory/items         │
│     ├─ Lotes ───────────────────► /inventory/lots          │
│     └─ Recepciones ─────────────► /inventory/receptions    │
│                                                             │
│  🛒 Compras ────────────────────► /compras                 │
│                                                             │
│  🍳 Recetas                                                 │
│     ├─ Listado ─────────────────► /recipes                 │
│     └─ Editor ──────────────────► /recipes/editor          │
│                                                             │
│  🏭 Producción ─────────────────► /produccion              │
│                                                             │
│  📊 Reportes ───────────────────► /reportes                │
│                                                             │
│  ⚙️  Configuración                                          │
│     ├─ Catálogos ───────────────► /catalogos (NUEVO)       │
│     │   ├─ Sucursales ───────────► /catalogos/sucursales   │
│     │   ├─ Almacenes ────────────► /catalogos/almacenes    │
│     │   ├─ Unidades ─────────────► /catalogos/unidades     │
│     │   ├─ Conversiones ─────────► /catalogos/uom          │
│     │   ├─ Proveedores ──────────► /catalogos/proveedores  │
│     │   └─ Políticas Stock ──────► /catalogos/stock-policy │
│     └─ Sistema ─────────────────► /admin                   │
│                                                             │
│  👥 Personal ───────────────────► /personal                │
│                                                             │
│  📺 KDS ────────────────────────► /kds                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ **CHECKLIST DE VERIFICACIÓN**

### Vistas que FUNCIONAN y están en menú:
- [x] Dashboard
- [x] Cortes de Caja
- [x] Inventario (vista general)

### Vistas que FUNCIONAN pero SIN acceso en menú:
- [ ] Items de inventario
- [ ] Lotes
- [ ] Recepciones
- [ ] Recetas (Livewire)
- [ ] Editor de recetas
- [ ] Todos los catálogos (6 vistas)
- [ ] KDS

### Vistas Placeholder (en menú pero sin contenido):
- [ ] Compras
- [ ] Recetas (blade)
- [ ] Producción
- [ ] Reportes (parcial)
- [ ] Configuración
- [ ] Personal

---

## 🎯 **PRIORIDADES**

### Alta Prioridad (Implementar YA)
1. ✅ Crear vista índice `/catalogos`
2. ✅ Actualizar sidebar con submenús
3. ✅ Agregar todos los catálogos al menú
4. ✅ Agregar vistas de inventario al menú

### Media Prioridad
5. ⏭️ Unificar `/recetas` y `/recipes`
6. ⏭️ Completar vista `/compras`
7. ⏭️ Agregar KDS al menú

### Baja Prioridad
8. ⏭️ Implementar `/produccion`
9. ⏭️ Implementar `/personal`
10. ⏭️ Completar `/admin`

---

*Documento generado: 2025-10-21*
*Versión: 1.0*
