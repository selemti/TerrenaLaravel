# 📋 PLAN DE MEJORA - Reporte Ítems + Modificadores v2.0

**Basado en**: Análisis de vista actual `http://localhost/TerrenaLaravel/reports/sales/mods`
**Fecha**: 15 Diciembre 2025
**Objetivo**: Transformar el reporte actual en una herramienta profesional con jerarquía macro→micro

---

## 🎯 **ESTADO ACTUAL - Análisis Rápido**

### ✅ **Lo que ya funciona bien**
1. **Filtros**: Completos y funcionales
2. **KPIs**: Métricas principales visibles
3. **Jerarquía por Categoría**: Headers colapsables ✅
4. **Expandible por Ítem**: Combinaciones visibles ✅
5. **Datos correctos**: Cálculos validados con base de datos

### ⚠️ **Áreas de mejora identificadas**
- "Grupo" como columna, no como nivel jerárquico
- Mezcla de "Base/Extra" en visualización
- "Precio Promedio" puede confundir
- Conteo de tickets no explícito en nivel ítem
- Término "Selecciones" poco claro
- Firma de combinación denso
- Filtros visibles sin impacto en layout

---

## 🏗️ **PLAN DE IMPLEMENTACIÓN - 10 Mejoras Clave**

### **1️⃣ Completar Jerarquía Macro→Micro (Nivel Grupo)**

**Estado Actual**:
```html
📁 CATEGORÍA (colapsable) ✅
   ├── Fila: Ítem + Grupo (badge) ⛔
   └── Fila: Ítem + Grupo (badge) ⛔
```

**Estado Deseado**:
```html
📁 CATEGORÍA (colapsable) ✅
   📂 GRUPO (colapsable) 🆕
       ├── 🥙 Ítem 1 (fila) ✅
       └── 🥪 Ítem 2 (fila) ✅
```

**Implementación**:
- Convertir grupo de badge a header colapsable real
- Agregar estilos `level-group` con borde verde (#198754)
- Mantener íconos expandibles para navegación

### **2️⃣ Separar "Base" vs "Extras" claramente**

**Estado Actual**:
```html
Ingreso: $92.00
Extra: $26.00
```

**Estado Deseado**:
```html
Base: $66.00 | Mods: +$26.00 | Total: $92.00
```

**Implementación**:
- Columnas separadas o mini-subtítulos
- En headers de Categoría/Grupo también mostrar estos 3 totales
- KPIs con separación clara de componentes

### **3️⃣ Cambiar "Precio Prom." por "Precio Base"**

**Problema**: "Precio Prom." incluye modificadores → confuso

**Solución**:
```html
<!-- Actual -->
Precio Promedio: $30.67

<!-- Mejorado -->
Precio Base: $22.00
Unit Avg: $30.67 (tooltip: "Incluye modificadores")
```

**Implementación**:
- Nuevo campo: `precio_base_catálogo`
- Mantener promedio solo en vista analítica
- Tooltips explicativos

### **4️⃣ Conteo de Tickets (Distinct) Explícito**

**Problema**: No se ven tickets reales en nivel ítem

**Estado Actual**:
```html
Quesadilla: 3 unidades | 2 tickets (aquí sí se ve)
```

**Estado Deseado**:
```html
Quesadilla: 3 unidades | 4 tickets (distinct)
├─ Con Champiñones: 2 unidades | 1 ticket
└─ Simples: 1 unidad | 1 ticket
```

**Implementación**:
- Agregar `tickets_distinct` en todas las filas
- Mostrar en headers de Categoría/Grupo
- Validar conteo: COUNT(DISTINCT ticket_id)

### **5️⃣ Normalizar "Selecciones" → "#Mods"**

**Estado Actual**:
```html
Selecciones: 2
```

**Estado Deseado**:
```html
Mods: 2 total (1 con costo)
```

**Implementación**:
- Renombrar campo a `#Mods`
- Mostrar: mods totales / mods con costo
- Tooltips explicativos claros

### **6️⃣ Mejorar Firma de Combinación (Chips)**

**Estado Actual**:
```html
Grupo: Mod | Grupo: Mod | ...
```

**Estado Deseado**:
```html
[Salsa: Roja] [Proteína: Sencilla] [Extra: Queso +$3]
```

**Implementación**:
- CSS class `modifier-chip` con diseño de chips
- Orden fijo por grupo (alfabético)
- Chips con costo tienen estilo diferente (`has-cost`)

### **7️⃣ KPI "Combinaciones Únicas" con Contexto**

**Estado Actual**:
```html
Combinaciones únicas: 5
```

**Estado Deseado**:
```html
Combinaciones únicas: 5
<small class="text-muted">(firmas de modificadores distintas)</small>
```

**Implementación**:
- Microtexto explicativo
- Filtro rápido "Ver solo combinaciones"
- Opción de ordenar por combinaciones

### **8️⃣ "Por día" cambia el layout, no solo datos**

**Problema**: `group_by_day=1` no se refleja visualmente

**Estado Deseado**:
```html
📅 15/12/2025
   📁 ALIMENTOS
       📂 ANTOJITOS
           🥙 Quesadilla
📅 16/12/2025
   📁 ALIMENTOS
       ...
```

**Implementación**:
- Nuevo nivel jerárquico: Día → Categoría → Grupo → Ítem
- Sub-headers visuales por fecha
- Estilos `level-date` con borde azul

### **9️⃣ "Incluir ítems sin ventas" como vista separada**

**Problema**: Checkbox "ensucia" vista operativa

**Solución**:
```html
Vista: [Operativa (ventas)] [Catálogo (completo)]
```

**Implementación**:
- Convertir checkbox en selector de vista
- Badge global "Incluye sin ventas"
- Botón "Ocultar ceros" rápido

### **🔟 Enlace Contextual por Combinación**

**Estado Deseado**:
```html
Quesadilla + Champiñones [Ver tickets] 🔗
```

**Implementación**:
- Modal con lista filtrada de tickets
- URL directa: `/tickets?combo=quesadilla-champinones`
- Exportación por combinación

---

## 📊 **ESTRUCTURA FINAL DE DATOS (Jerarquía Completa)**

```
📊 KPIs Generales (mejorados)
├── Combinaciones únicas: X
├── Ítems únicos: Y
├── Tickets: Z (distinct)
├── Base: $X | Mods: +$Y | Total: $Z
└── Unidades vendidas: N

📅 DÍA (si group_by_day=1)
└── 📁 CATEGORÍA (colapsable)
    └── 📂 GRUPO (colapsable) 🆕
        ├── 🥙 ÍTEM (fila con tickets distinct) 🆕
        │   ├── Base: $22 | Mods: +$13 | Total: $35 🆕
        │   ├── Unidades: 2 | Tickets: 1 🆕
        │   └── ▼ Combinaciones (expandible)
        │       ├── [Proteína: Champiñones +$13] 🆕
        │       │   ├── Unidades: 2 | Mods: 1 🆕
        │       │   ├── Tickets: 1 | Extra: $13
        │       │   └── [Ver tickets] 🔗 🆕
        │       └── [Proteína: Simple]
        │           ├── Unidades: 1 | Mods: 1
        │           └── Tickets: 1 | Extra: $0
        └── 🥪 OTRO ÍTEM...
```

---

## 🎨 **MEJORAS VISUALES Y UX**

### **Colores y Estilos**:
- **Categoría**: Azul (#0d6efd) - Already implemented
- **Grupo**: Verde (#198754) - Nuevo
- **Ítem**: Gris (#6c757d) - Existing
- **Mods con costo**: Amarillo (#ffc107) - Nuevo
- **Chips**: Gris claro (#f8f9fa) - Nuevo

### **Interacciones**:
- **Click**: Colapsar/Expandir
- **Hover**: Efectos sutiles
- **Tooltips**: Contexto claro
- **Mobile**: Touch-friendly

### **Accesibilidad**:
- **Keyboard Navigation**: Tab/Enter
- **Screen Readers**: ARIA labels
- **Color Contrast**: WCAG AA

---

## 📝 **REQUERIMIENTOS TÉCNICOS**

### **Cambios en Controller**:
- Agregar `tickets_distinct` a todos los cálculos
- Separar `precio_base` de `precio_promedio`
- Agrupar por `categoria → grupo → item`

### **Cambios en Blade**:
- Nueva estructura jerárquica HTML
- Componentes reutilizables (chips, badges)
- Scripts para colapsables multinivel

### **Cambios en CSS**:
- Clases `level-*` para cada nivel
- Animaciones suaves
- Responsive design

---

## 🚀 **ROADMAP DE IMPLEMENTACIÓN**

### **FASE 1 (Crítico - Prioridad Alta)**
1. ✅ Crear copia de vista actual (`mods_v2.blade.php`)
2. 🔄 Implementar nivel Grupo como header colapsable
3. 🔄 Separar Base/Mods en KPIs y filas
4. 🔄 Agregar tickets distinct en nivel ítem

### **FASE 2 (UX - Prioridad Media)**
5. 🔄 Mejorar firma de combinación (chips)
6. 🔄 Renombrar "Selecciones" → "#Mods"
7. 🔄 Mejorar KPI combinaciones únicas

### **FASE 3 (Avanzado - Prioridad Baja)**
8. 🔄 Implementar layout "Por día"
9. 🔄 Vista separada "Catálogo"
10. 🔄 Enlaces contextuales por combinación

---

## 🎯 **METAS DE ÉXITO**

### **Funcionales**:
- ✅ Jerarquía completa: Día → Categoría → Grupo → Ítem → Combo
- ✅ Navegación sin columnas (todo colapsable)
- ✅ Totales exactos y trazabilidad clara
- ✅ Distinción base/mods transparente

### **UX**:
- ✅ Lectura ejecutiva sin necesidad de解读
- ✅ Auditoría posible con clicks
- ✅ Mobile-friendly
- ✅ Exportación por niveles

### **Técnicos**:
- ✅ Performance < 2s para 10k registros
- ✅ Responsive design
- ✅ Accesibilidad WCAG AA
- ✅ Compatible con exports actuales

---

## 📋 **CHECKLIST DE VALIDACIÓN**

**Después de cada mejora:**
- [ ] Totales coinciden con versión actual
- [ ] Todos los niveles colapsan/expanden correctamente
- [ ] Mobile funciona bien
- [ ] Export PDF/Excel funciona
- [ ] No se rompe ninguna funcionalidad existente

**Antes de producción:**
- [ ] Test con datos reales >1000 items
- [ ] Test con modificadores complejos (>4 mods)
- [ ] Test con todos los filtros activos
- [ ] Validar performance
- [ ] Test accesibilidad

---

## 🏁 **RESULTADO ESPERADO**

Un reporte profesional que permite:

1. **Navegación intuitiva**: Macro→micro sin columnas
2. **Trazabilidad total**: Desde combinación hasta tickets
3. **Claridad absoluta**: Separación base/mods explícita
4. **Flexibilidad**: Múltiples vistas y exportaciones
5. **Escalabilidad**: Funciona con 100k+ registros

**Transformará el reporte actual de "datos crudos" a "herramienta de análisis ejecutivo".**

---

**Creado**: 15 Diciembre 2025
**Basado en**: Análisis de vista actual + 10 mejoras propuestas
**Estado**: Listo para implementación por fases