# Modificaciones a wizard.js para Cortes Irregulares

**Archivo**: `public/assets/js/caja/wizard.js`
**Última actualización**: 2025-11-11

---

## Descripción General

Este documento describe las modificaciones necesarias al archivo `wizard.js` para soportar el sistema de aprobación de cortes irregulares (cuando `skipped_precorte=true`).

---

## Modificaciones Requeridas

### 1. Detectar `skipped_precorte` en Step 3

Cuando se carga el Step 3 (Postcorte), el wizard debe verificar si la sesión tiene `skipped_precorte=true`.

**Ubicación**: Dentro de la función que carga Step 3 / muestra el postcorte

**Agregar**:

```javascript
/**
 * Check if session has skipped_precorte flag
 * If true, show warning banner and require motivo_irregular
 */
function checkSkippedPrecorte(sesionData) {
  const skippedPrecorte = sesionData?.skipped_precorte === true ||
                           sesionData?.skipped_precorte === 1;

  if (skippedPrecorte) {
    // Show warning banner
    const banner = document.querySelector('[data-role="banner-corte-irregular"]');
    if (banner) {
      banner.classList.remove('d-none');
    }

    // Show motivo_irregular field
    const motivoContainer = document.querySelector('[data-role="motivo-irregular-container"]');
    if (motivoContainer) {
      motivoContainer.classList.remove('d-none');
    }

    // Change button text
    const btnValidar = document.querySelector('[data-role="btn-validar"]');
    if (btnValidar) {
      btnValidar.textContent = 'Enviar a Aprobación';
      btnValidar.classList.remove('btn-success');
      btnValidar.classList.add('btn-warning');
    }

    return true;
  }

  return false;
}
```

**Llamar la función** cuando se carga Step 3:

```javascript
// En la función que carga/muestra el Step 3
const isIrregular = checkSkippedPrecorte(state.sesion || state.data);
state.requiereAprobacion = isIrregular;
```

---

### 2. Incluir `motivo_irregular` al crear Postcorte

Cuando el usuario hace clic en "Enviar a Aprobación" (o "Validar y cerrar"), el wizard debe incluir el campo `motivo_irregular` en el payload si el corte es irregular.

**Ubicación**: En la función que envía el POST al endpoint `/api/caja/postcortes/`

**Modificar el payload**:

```javascript
async function crearPostcorte() {
  const precorteId = state.precorteId;
  const notas = document.getElementById('pc3Notas')?.value || '';

  const payload = {
    precorte_id: precorteId,
    notas: notas
  };

  // If irregular, include motivo_irregular
  if (state.requiereAprobacion) {
    const motivoIrregular = document.querySelector('[data-role="motivo-irregular"]')?.value || '';

    if (!motivoIrregular || motivoIrregular.trim() === '') {
      alert('Por favor, proporciona el motivo del corte irregular.');
      return;
    }

    payload.motivo_irregular = motivoIrregular.trim();
  }

  try {
    const response = await fetch('/api/caja/postcortes/', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!data.ok) {
      throw new Error(data.detail || data.error || 'Error al crear postcorte');
    }

    // Handle response
    handlePostcorteResponse(data);

  } catch (error) {
    console.error('Error creando postcorte:', error);
    alert('Error al crear postcorte: ' + error.message);
  }
}
```

---

### 3. Manejar la respuesta del backend

El backend puede retornar `requiere_aprobacion: true` en la respuesta. El wizard debe mostrar un mensaje apropiado.

**Agregar función**:

```javascript
function handlePostcorteResponse(data) {
  if (data.requiere_aprobacion === true) {
    // Irregular postcorte created, pending approval
    alert(
      '✓ Postcorte enviado a aprobación.\n\n' +
      'Un supervisor revisará este corte y te notificará cuando sea aprobado o rechazado.'
    );

    // Close modal
    const modal = document.getElementById('czModalPrecorte');
    if (modal) {
      const bsModal = bootstrap.Modal.getInstance(modal);
      if (bsModal) {
        bsModal.hide();
      }
    }

    // Refresh table or redirect
    if (typeof refreshSesionesTable === 'function') {
      refreshSesionesTable();
    } else {
      window.location.reload();
    }

  } else {
    // Normal postcorte, session closed
    alert('✓ Postcorte validado correctamente.\n\nLa sesión ha sido cerrada.');

    // Close modal
    const modal = document.getElementById('czModalPrecorte');
    if (modal) {
      const bsModal = bootstrap.Modal.getInstance(modal);
      if (bsModal) {
        bsModal.hide();
      }
    }

    // Refresh table or redirect
    if (typeof refreshSesionesTable === 'function') {
      refreshSesionesTable();
    } else {
      window.location.reload();
    }
  }
}
```

---

### 4. Limpiar campos al cerrar modal

Asegurarse de que los campos adicionales se limpien cuando se cierra el modal.

**Agregar en la función de limpieza del wizard**:

```javascript
function resetWizard() {
  // Existing cleanup code...

  // Hide irregular postcorte banner
  const banner = document.querySelector('[data-role="banner-corte-irregular"]');
  if (banner) {
    banner.classList.add('d-none');
  }

  // Hide motivo_irregular field
  const motivoContainer = document.querySelector('[data-role="motivo-irregular-container"]');
  if (motivoContainer) {
    motivoContainer.classList.add('d-none');
  }

  // Clear motivo_irregular value
  const motivoField = document.querySelector('[data-role="motivo-irregular"]');
  if (motivoField) {
    motivoField.value = '';
  }

  // Reset button
  const btnValidar = document.querySelector('[data-role="btn-validar"]');
  if (btnValidar) {
    btnValidar.textContent = 'Validar y cerrar';
    btnValidar.classList.remove('btn-warning');
    btnValidar.classList.add('btn-success');
  }

  // Reset state
  state.requiereAprobacion = false;
}
```

---

## Flujo Completo

```
1. Usuario abre wizard para sesión con skipped_precorte=true
   ↓
2. Wizard carga Step 1 (declaración efectivo)
   ↓
3. Wizard carga Step 2 (conciliación con POS)
   ↓
4. Wizard carga Step 3 (postcorte)
   → checkSkippedPrecorte() detecta flag
   → Muestra banner warning
   → Muestra campo motivo_irregular
   → Cambia botón a "Enviar a Aprobación"
   ↓
5. Usuario completa motivo_irregular y hace clic en botón
   → Valida que motivo_irregular no esté vacío
   → POST /api/caja/postcortes/ con payload incluyendo motivo_irregular
   ↓
6. Backend crea postcorte con requiere_aprobacion=true
   → Backend crea alertas para supervisores
   → Backend responde con ok=true, requiere_aprobacion=true
   ↓
7. Frontend maneja respuesta
   → Muestra mensaje "Enviado a aprobación"
   → Cierra modal
   → Refresca tabla
```

---

## Testing

### Caso 1: Corte Normal

1. Crear sesión sin skipped_precorte
2. Completar wizard normalmente
3. En Step 3, verificar:
   - Banner irregular NO visible
   - Campo motivo_irregular NO visible
   - Botón dice "Validar y cerrar" (verde)

### Caso 2: Corte Irregular

1. Crear sesión con skipped_precorte=true
2. Completar wizard
3. En Step 3, verificar:
   - Banner irregular VISIBLE
   - Campo motivo_irregular VISIBLE y obligatorio
   - Botón dice "Enviar a Aprobación" (amarillo)
4. Intentar enviar sin llenar motivo → Debe mostrar alerta
5. Llenar motivo y enviar → Debe crear postcorte pendiente aprobación

---

## Archivos Relacionados

- **Vista modal**: `resources/views/caja/_wizard_modals.blade.php`
- **Controlador**: `app/Http/Controllers/Api/Caja/PostcorteController.php`
- **Servicio de alertas**: `app/Services/Caja/AlertasService.php`
- **Documentación**: `docs/CajaChica/Corte de Caja/PLAN_REGULARIZACION_CORTES.md`

---

**Creado por**: Claude Code
**Fecha**: 2025-11-11
