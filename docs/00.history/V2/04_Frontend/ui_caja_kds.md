# UI · Caja, Cortes y KDS

## 1. Caja / Cortes

### Vistas y Controladores

- `resources/views/caja/cortes.blade.php`: interfaz actual para cortes (usa assets en `public/assets/js/caja` y `css/caja.css`).
- APIs bajo `App\Http\Controllers\Api\Caja\*` sirven datos (precorte, postcorte, conciliación).
- Rutas legacy (`/api/legacy/*`) mantienen compatibilidad con Slim PHP.

### Flujo Precorte/Postcorte

1. **Sesión activa** (`/api/caja/sesiones/activa`).
2. **Precorte**: preflight tickets, crear/actualizar, obtener totales.
3. **Postcorte**: registrar conciliación, imprimir reportes.
4. **Formas de pago**: catálogos para cuadratura.

### Material de Referencia

- `D:\Tavo\2025\UX\Cortes\Definición de módulos*.docx`
- Scripts SQL `precorte_conciliacion_*.sql` (optimización de dashboards).
- Mockups y versiones (`D:\Tavo\2025\UX\Cortes\V5`, `v2`, `v3`, `v4`).
- Dashboards Excel (`CORTE DE VENTAS.xlsx`).

### Pendientes

- Migrar wizard completo de precorte (ver `docs/WIZARD_CORTE_CAJA-*.md`) al nuevo frontend.
- Implementar autenticación y roles específicos (cajero, supervisor).
- Centralizar assets JS (evitar duplicados `public/assets/js` vs `public/assets/js_`).
- Documentar proceso de conciliación y excepciones.

## 2. KDS (Kitchen Display System)

- Componente actual: `App\Livewire\Kds\Board` (placeholder).  
- Requiere definir modelo de órdenes, eventos en tiempo real (p.ej. Pusher, websockets o polling).  
- Revisar lineamientos UX en `D:\Tavo\2025\UX\Cortes\` y `Pantallas.xlsx`.

## 3. Próximos Pasos

- [ ] Consolidar documentación funcional de precorte/postcorte y migrarla a esta carpeta.  
- [ ] Diseñar nuevas pantallas (Figma/Mockups) para KDS y dashboard de cortes.  
- [ ] Conectar APIs existentes con UI Reactiva (Livewire o Vue).  
- [ ] Establecer pruebas end-to-end para flujo de caja.  
- [ ] Definir soporte para impresión (PDF, impresoras térmicas).  

Actualiza este documento cuando se modifique la UI de caja o se avance en KDS.
