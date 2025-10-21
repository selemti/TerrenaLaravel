# Terrena · Índice Maestro de Documentación (V2)

_Objetivo:_ centralizar en `docs/V2` toda la información vigente del proyecto Terrena, reemplazando versiones dispersas en `docs/` y en los repositorios locales de `D:\Tavo\2025\UX\*`. Esta guía define la estructura destino, el estado actual y los pendientes para migrar cada documento.

---

## 1. Estructura Objetivo

```
docs/
└── V2/
    ├── PROJECT_STATUS.md          ← visión ejecutiva y backlog (existente)
    ├── DOCUMENTATION_INDEX.md     ← este índice
    ├── 01_General/
    │   ├── vision.md              ← resumen ejecutivo / roadmap
    │   └── stakeholders.md        ← responsables y contacto
    ├── 02_Database/
    │   ├── schema_public.md       ← tablas/migraciones del esquema public
    │   ├── schema_selemti.md      ← dependencias externas (selemti.*)
    │   └── scripts/               ← SQL versionado (desde BD/ y D:\)
    ├── 03_Backend/
    │   ├── routes_web.md          ← rutas Blade/Livewire
    │   ├── routes_api.md          ← endpoints REST + legacy
    │   └── services.md            ← servicios y jobs
    ├── 04_Frontend/
    │   ├── ui_catalogs.md         ← catálogos Livewire
    │   ├── ui_inventory.md        ← inventario/recepciones
    │   ├── ui_recipes.md          ← recetas
    │   └── ui_caja_kds.md         ← caja/KDS/Dashboard
    ├── 05_Operations/
    │   ├── deployment.md          ← checklist deploy, migraciones, build
    │   ├── security.md            ← auth, roles, JWT
    │   └── monitoring.md          ← health checks, logs
    └── assets/
        ├── ux/                    ← mockups, PDFs, Excel (ver 4.3)
        └── legacy/                ← documentos históricos no vigentes
```

> Nota: los subdirectorios `01_*` a `05_*` se pueden crear conforme se migra contenido. Usa nombres en español consistentes con el equipo.

---

## 2. Documentación Actual en el Repositorio

| Archivo / Carpeta                                     | Estado | Acción recomendada | Destino sugerido |
|-------------------------------------------------------|--------|--------------------|------------------|
| `docs/PROJECT_OVERVIEW.md`                            | ✅ Vigente | Mover/renombrar como `01_General/vision.md` | `docs/V2/01_General/` |
| `docs/DATA_DICTIONARY-2025-10-17.md`                  | ⚠ Mixto (vigente pero desordenado) | Curar y dividir por esquema (`schema_public`, `schema_selemti`) | `docs/V2/02_Database/` |
| `docs/DOC_ERD-FULL-20251017-081101.md`                | ✅ | Referenciar en `schema_public.md` | `docs/V2/02_Database/` |
| `docs/DOC_GENERAL-20251017-0146.md`                   | ⚠ Obsoleto parcial | Extraer secciones útiles (auditoría) y amalgamar en `PROJECT_STATUS.md` | `legacy/` |
| `docs/DOC_RUTAS_Y_CASOS_DE_USO-*.md`                  | ⚠ Duplicados | Consolidar en `03_Backend/routes_web.md` y `routes_api.md` | `docs/V2/03_Backend/` |
| `docs/WIZARD_CORTE_CAJA-*.md`                         | ✅ | Integrar resumen en `ui_caja_kds.md`; guardar detalle en `legacy/` si hay versiones duplicadas | `docs/V2/04_Frontend/` |
| `docs/CRUD_*.md`, `AUDITORIA-*.md`, `GAP_ANALYSIS_*.md` | ⚠ Multiples versiones | Seleccionar versión más reciente, resumir hallazgos en `PROJECT_STATUS.md` y archivar resto | `legacy/` |
| `docs/Documentación_full.zip`                         | ❓ sin revisar | Descomprimir, evaluar contenido y clasificar según corresponda | `assets/legacy/` (hasta clasificar) |
| `BD/*.sql`, `BD/*.ps1`, `BD/*.log`                    | ⚠ Mezcla de deploys/backups | Identificar scripts vigentes (deploy + postdeploy) y mover a `docs/V2/02_Database/scripts/`. Marcar backups como referencia histórica | `docs/V2/02_Database/scripts/` |

---

## 3. Material Externo en `D:\Tavo\2025\UX`

### 3.1 Inventarios (`D:\Tavo\2025\UX\Inventarios\`)

| Recurso | Descripción | Acción |
|---------|-------------|--------|
| `Definición de Inventarios.docx` | Alcance funcional de inventarios | Convertir a Markdown (o PDF) y almacenar en `04_Frontend/ui_inventory.md` (resumen) + `assets/ux/Inventarios/` (original) |
| `Inventario_Floreant_DataDictionary_v*.xlsx` | Diccionarios de datos Floreant | Revisar versión más reciente (`v4.xlsx` en carpeta v2). Extraer tablas relevantes a `02_Database/schema_public.md` y `schema_selemti.md`. Guardar original en `assets/ux/Inventarios/`. |
| `MasterData_Templates*.xlsx/csv` | Plantillas de carga | Guardar en `assets/ux/Inventarios/` con README explicativo. |
| `selemti_deploy_inventarios_*.sql` | Scripts SQL | Evaluar y, si son vigentes, integrarlos en migraciones o mover a `02_Database/scripts/`. |
| `Inventarios_Old.zip` | Histórico | Revisar y archivar en `assets/legacy/` hasta que se determine relevancia. |

### 3.2 Cortes (`D:\Tavo\2025\UX\Cortes\`)

| Recurso | Descripción | Acción |
|---------|-------------|--------|
| `Definición de módulos*.docx` | Especificación de precortes/postcortes | Sintetizar en `ui_caja_kds.md`. Guardar doc original en `assets/ux/Cortes/`. |
| `precorte_*` `.php/.sql/.txt` | Código legacy y consultas | Analizar qué partes se migraron a Laravel; documentar en `03_Backend/routes_api.md` y `04_Frontend/ui_caja_kds.md`; mover SQL útil a `02_Database/scripts/` |
| `CORTE DE VENTAS.xlsx` | Dashboard de KPIs | Adjuntar en `assets/ux/Cortes/` y referenciar en `PROJECT_STATUS.md` (backlog reportes). |
| Subcarpetas `v2`, `v3`, `V5` | Mockups o evoluciones | Clasificar según vigencia. |

### 3.3 Recetas (`D:\Tavo\2025\UX\00. Recetas\`)

| Recurso | Descripción | Acción |
|---------|-------------|--------|
| `Acta de Diseño...`, `ESPECIFICACIÓN DE REQUERIMIENTOS (SRS)` | Documentos funcionales | Convertir resumen a `04_Frontend/ui_recipes.md`; guardar originales en `assets/ux/Recetas/`. |
| `UML_Catalogo.*`, `Documentación V1/` | Modelado y docs técnicas | Incorporar diagramas relevantes en `PROJECT_STATUS.md` (estado módulo recetas) y subir a `assets/ux/Recetas/`. |
| `Query Recetas/*.sql` | Scripts SQL | Validar y mover a `02_Database/scripts/recetas/`. |
| `RECETARIO YESI.xlsx` | Fuente recetas | Evaluar si se necesita como seed; guardar en `assets/ux/Recetas/`. |

---

## 4. Plan de Ejecución

1. **Crear estructura de carpetas** `docs/V2/0x_*` y `assets/` según el mapa de la sección 1.  
2. **Inventario actual**: llenar tablas de secciones 2 y 3 con responsables y fechas (usar PR o board interno).  
3. **Migración iterativa**: por cada categoría (General, DB, Backend, Front, Operaciones):
   - Seleccionar documento fuente (repositorio o carpeta D:).
   - Depurar versiones duplicadas, priorizando la más reciente.  
   - Convertir a Markdown cuando aplique.  
   - Guardar archivos binarios (XLSX, PDF) en `assets/ux/<dominio>/` con README.  
   - Actualizar este índice (estado → ✅) y enlazar desde `PROJECT_STATUS.md`.  
4. **Archivar legado**: mover documentos desactualizados a `docs/V2/assets/legacy/` o eliminarlos si no aportan valor.  
5. **Automatizar referencia**: considerar crear script `docs/sync-index.sh` o una tabla en Notion para seguimiento.  
6. **Revisión periódica**: al cierre de cada sprint, validar que los nuevos entregables se añadan a `docs/V2` y actualizar `PROJECT_STATUS.md`.

---

## 5. Seguimiento (Plantilla)

| Dominio | Responsable | Fecha objetivo | Estado |
|---------|-------------|----------------|--------|
| General / Visión          | _(Asignar)_ | _(dd/mm)_ | ☐ |
| Base de datos (public)    |             |          | ☐ |
| Base de datos (selemti)   |             |          | ☐ |
| Catálogos / Livewire      |             |          | ☐ |
| Inventario / Recepciones  |             |          | ☐ |
| Recetas                   |             |          | ☐ |
| Caja / Cortes             |             |          | ☐ |
| KDS / Operaciones         |             |          | ☐ |
| Deploy / Seguridad        |             |          | ☐ |
| Assets UX (Inventarios)   |             |          | ☐ |
| Assets UX (Cortes)        |             |          | ☐ |
| Assets UX (Recetas)       |             |          | ☐ |

Marca cada casilla cuando el contenido esté migrado y actualizado en `docs/V2`.

---

## 6. Notas

- Mantén una sola “fuente de verdad” por tema; evita duplicar PDFs o plantillas sin necesidad.  
- Documentos sensibles (contratos, cotizaciones) pueden tener acceso restringido; guarda solo referencias si corresponde.  
- Antes de eliminar archivos antiguos, valida con el equipo si aún se requieren para auditorías o compliance.  
- Considera versionar la carpeta `docs/V2` con etiquetado (ej. `docs/V2/README.md` explicando la convención).  
- Actualiza `PROJECT_STATUS.md` cada vez que cambie el estado de un módulo o se añada documentación clave.

---

> **Próximo paso recomendado:** crear las subcarpetas objetivo y comenzar con la migración de los documentos “General” y “Database”, ya que sostienen el resto de los módulos. Usa este índice como checklist vivo; ajusta estructura según necesidades reales del equipo.
