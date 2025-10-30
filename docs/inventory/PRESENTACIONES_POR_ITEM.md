Objetivo

Administrar UOM alternas por ítem (presentaciones de compra/almacén/cocina) y sus factores hacia base.

UI (CRUD simple)

Lista de presentaciones del ítem:

uom_code (único por ítem)

descripcion

factor_total

activo

Crear/Editar:

uom_code (texto corto sin espacios, p. ej. CAJA_12x1.2L)

descripcion (ej. “Caja 12×1.2L”)

factor_total (numérico > 0; 6 decimales)

activo (bool)

Validaciones:

unique (insumo_id, uom_code)

factor_total > 0

Si la presentación representa enteros (p.ej. “Caja”), marcar flag integer_only (opcional), para forzar cantidad entera en capturas que usen esa UOM.