VIEW ? FIELD MATRIX

Fecha: 20251017-0256

Metodolog�a
- Extracci�n de atributos name="..." en inputs/select/textarea.
- Extracci�n de wire:model / x-model en vistas Livewire.
- Inferencia de tipo (texto, num�rico, fecha, dinero) por patr�n (type=, step, nombre) y validadores (required, maxlength, min/max si presentes).
- Mapeo heur�stico a columnas BD por nombre (Data Dictionary) y convenci�n.

Resumen por vista

1) resources/views/auth/login.blade.php
- Campos:
  - login (texto, required) ? BD: users.email (o users.name) � Comentario: depende de guard (login/email)
  - password (password, required) ? BD: users.password (hash)

2) resources/views/login.blade.php
- Campos:
  - username (texto) ? BD: users.email/users.name � Comentario: pantalla alternativa
  - password (password) ? BD: users.password
  - remember (checkbox) ? BD: sessions/remember_token (no directo)

3) resources/views/profile/partials/update-profile-information-form.blade.php
- name (texto, required) ? BD: users.name
- email (email, required) ? BD: users.email

4) resources/views/profile/partials/update-password-form.blade.php
- current_password (password, required) ? Validaci�n runtime � no persiste
- password (password, required) ? BD: users.password
- password_confirmation (password, required) ? Validaci�n

5) resources/views/auth/register.blade.php
- name (texto, required) ? BD: users.name
- email (email, required) ? BD: users.email
- password (password, required) ? BD: users.password
- password_confirmation (password, required) ? Validaci�n

6) Caja: resources/views/caja/cortes.blade.php
- No tiene name=; usa hidden id=filtroFecha (sin name). JS consume id/inputs de _wizard_modals.
- GAP: Campos del wizard se definen en parcial _wizard_modals.php con ids (declCredito, declDebito, declTransfer) sin name.
  - Sugerencia: a�adir name="decl_credito", name="decl_debito", name="decl_transfer" para facilitar submit progresivo.

7) Caja: resources/views/caja/_wizard_modals.php (PHP)
- Inputs (por id, no name):
  - declCredito (num�rico dinero) ? BD: selemti.precorte_otros (tipo 'CREDITO')
  - declDebito (num�rico dinero) ? BD: selemti.precorte_otros (tipo 'DEBITO')
  - declTransfer (num�rico dinero) ? BD: selemti.precorte_otros (tipo 'TRANSFER')
  - tablaDenomsBody (cantidad por denominaci�n) ? BD: selemti.precorte_efectivo (denominacion, cantidad, subtotal)
  - notasPaso1 (texto) ? BD: selemti.precorte.notas
  - precorteId (hidden) ? BD: selemti.precorte.id
- Validadores inferidos: valores >= 0; step 0.01; required si se exige completar todos.
- GAPs:
  - Sin name= � dificultan validaci�n server-side tradicional.
  - Tipos monetarios: asegurar DECIMAL(12,2) en BD; UI est� alineado como dinero.

8) Livewire: resources/views/inventory/receptions-create.blade.php
- wire:model:
  - supplier_id (select) ? BD: selemti.proveedor.id � requerido
  - branch_id (texto) ? BD: selemti.sucursal.id (si num�rico) o clave; aclarar tipo
  - warehouse_id (texto) ? BD: selemti.almacen.id (si num�rico) o clave
  - lines[].item_id (select) ? BD: selemti.item.id � requerido
  - lines[].qty_pack (num�rico) ? BD: selemti.recepcion_det.qty_pack (sugerido)
  - lines[].uom_purchase (select) ? BD: selemti.unidades_medida.id
  - lines[].pack_size (num�rico) ? BD: selemti.recepcion_det.pack_size (sugerido)
  - lines[].uom_base (select) ? BD: selemti.unidades_medida.id
  - lines[].lot (texto) ? BD: selemti.lote.lote (o equivalente)
  - lines[].exp_date (fecha) ? BD: selemti.lote.exp_date
  - lines[].temp (num�rico) ? BD: selemti.lote.temp (si aplica)
  - lines[].evidence (texto/archivo) ? BD: URL evidencia
- Validadores inferidos: supplier_id/item_id required; qty_pack/pack_size min>0; exp_date fecha v�lida.
- GAPs propuestos:
  - Definir estructuras BD para recepciones si faltan (cabecera/detalle); alinear nombres.

9) Livewire Cat�logos (muestras)
- unidades-index: wire:model (search, clave, nombre, activo) ? BD: selemti.unidades_medida (clave,nombre,activo)
- uom-conversion-index: origen_id, destino_id, factor ? BD: conversion_unidad
- stock-policy-index: item_id, sucursal_id, min_qty, max_qty, reorder_qty, activo ? BD: stock_policy

Matriz por vista (extractos)
- auth/login.blade.php
  - login ? users.email|name � requerido � texto
  - password ? users.password � requerido � password
- caja/_wizard_modals.php
  - declCredito ? selemti.precorte_otros.monto (tipo=CREDITO) � num�rico dinero
  - declDebito ? selemti.precorte_otros.monto (tipo=DEBITO) � num�rico dinero
  - declTransfer ? selemti.precorte_otros.monto (tipo=TRANSFER) � num�rico dinero
  - denoms (varios) ? selemti.precorte_efectivo.{denominacion,cantidad,subtotal}
  - notasPaso1 ? selemti.precorte.notas � texto
- inventory/receptions-create.blade.php
  - supplier_id ? selemti.proveedor.id � requerido
  - lines[].item_id ? selemti.item.id � requerido
  - lines[].qty_pack ? recepcion_det.qty_pack � num�rico
  - lines[].exp_date ? lote.exp_date � fecha

GAPs consolidados
- Inputs sin columna equivalente: revisar recepciones (temp, evidence), branch_id/warehouse_id si son claves externas reales.
- Columnas sin UI: verificar selemti.postcorte.veredictos/notas/validado; si faltan en UI postcorte, a�adir.
- Tipos no alineados: asegurar que montos son DECIMAL en BD (evitar double precision); UI ya trata dinero.

Sugerencias
- A�adir name= a inputs del wizard para mejorar validaci�n/submit tradicional.
- Crear FormRequests para Precorte/Postcorte con reglas: denoms >0, montos >=0, notas max len.
- Completar UI de postcorte con veredictos/notas/validado si falta.
