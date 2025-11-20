# VERIFICACIÓN DEL MAPA BD ↔ CÓDIGO (Inventario, Recetas, POS)

| tabla_bd | columna_bd | existe_en_bd | estado_original | estado_bd | decision_final | notas |
|----------|------------|--------------|-----------------|-----------|----------------|-------|
| mov_inv | id | SI | OK | OK | CONFIABLE | Primary key |
| mov_inv | ts | SI | MISMATCH | OK | SOSPECHOSO | Código espera fecha_movimiento pero BD tiene ts |
| mov_inv | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| mov_inv | lote_id | SI | OK | OK | CONFIABLE | Lot ID field |
| mov_inv | cantidad | SI | OK | OK | CONFIABLE | Quantity field |
| mov_inv | qty_original | SI | OK | OK | CONFIABLE | Original quantity |
| mov_inv | uom_original_id | SI | OK | OK | CONFIABLE | Original UOM ID |
| mov_inv | costo_unit | SI | MISMATCH | OK | SOSPECHOSO | Código espera costo_unitario pero BD tiene costo_unit |
| mov_inv | tipo | SI | MISMATCH | OK | SOSPECHOSO | Código espera tipo_movimiento pero BD tiene tipo |
| mov_inv | ref_tipo | SI | MISMATCH | OK | SOSPECHOSO | Código espera referencia_tipo pero BD tiene ref_tipo |
| mov_inv | ref_id | SI | MISMATCH | OK | SOSPECHOSO | Código espera referencia_id pero BD tiene ref_id |
| mov_inv | sucursal_id | SI | MISMATCH | OK | SOSPECHOSO | Código espera almacen_id pero BD tiene sucursal_id |
| mov_inv | usuario_id | SI | OK | OK | CONFIABLE | User ID field |
| mov_inv | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| recepcion_det | id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | recepcion_id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | item_id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | bodega_id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | qty | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | um_id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | costo_unit | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | batch_id | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | temperatura | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | doc_url | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | meta | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | created_at | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | updated_at | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| recepcion_det | deleted_at | SI | NO_USADO | OK | ERROR_MAPA | Table exists but not referenced in code |
| transfer_cab | id | SI | OK | OK | CONFIABLE | Primary key |
| transfer_cab | origen_almacen_id | SI | OK | OK | CONFIABLE | Foreign key |
| transfer_cab | destino_almacen_id | SI | OK | OK | CONFIABLE | Foreign key |
| transfer_cab | estado | SI | OK | OK | CONFIABLE | Status enum |
| transfer_cab | creada_por | SI | OK | OK | CONFIABLE | Foreign key |
| transfer_cab | despachada_por | SI | OK | OK | CONFIABLE | Dispatch user |
| transfer_cab | recibida_por | SI | OK | OK | CONFIABLE | Receive user |
| transfer_cab | guia | SI | OK | OK | CONFIABLE | Guide number |
| transfer_cab | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| transfer_det | id | SI | OK | OK | CONFIABLE | Primary key |
| transfer_det | transfer_id | SI | OK | OK | CONFIABLE | Foreign key |
| transfer_det | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| transfer_det | cantidad | SI | OK | OK | CONFIABLE | Quantity |
| transfer_det | cantidad_despachada | SI | OK | OK | CONFIABLE | Dispatched quantity |
| transfer_det | cantidad_recibida | SI | OK | OK | CONFIABLE | Received quantity |
| transfer_det | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| hist_cost_insumo | id | SI | OK | OK | CONFIABLE | Primary key |
| hist_cost_insumo | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| hist_cost_insumo | fecha_efectiva | SI | OK | OK | CONFIABLE | Effective date |
| hist_cost_insumo | costo_wac | SI | OK | OK | CONFIABLE | WAC cost |
| hist_cost_insumo | costo_peps | SI | OK | OK | CONFIABLE | FIFO cost |
| hist_cost_insumo | costo_ueps | SI | OK | OK | CONFIABLE | LIFO cost |
| hist_cost_insumo | costo_std | SI | OK | OK | CONFIABLE | Standard cost |
| hist_cost_insumo | algoritmo_principal | SI | OK | OK | CONFIABLE | Main algorithm |
| hist_cost_insumo | valid_from | SI | OK | OK | CONFIABLE | Valid from date |
| hist_cost_insumo | valid_to | SI | OK | OK | CONFIABLE | Valid to date |
| hist_cost_insumo | sys_from | SI | OK | OK | CONFIABLE | System from timestamp |
| hist_cost_insumo | sys_to | SI | OK | OK | CONFIABLE | System to timestamp |
| hist_cost_insumo | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| hist_cost_insumo | updated_at | SI | OK | OK | CONFIABLE | Update timestamp |
| hist_cost_insumo | deleted_at | SI | OK | OK | CONFIABLE | Delete timestamp |
| stock_policy | id | SI | OK | OK | CONFIABLE | Primary key |
| stock_policy | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| stock_policy | sucursal_id | SI | MISMATCH | OK | SOSPECHOSO | Código espera almacen_id pero BD tiene sucursal_id |
| stock_policy | almacen_id | SI | MISMATCH | OK | SOSPECHOSO | Código espera sucursal_id pero BD tiene almacen_id |
| stock_policy | min_qty | SI | OK | OK | CONFIABLE | Minimum quantity |
| stock_policy | max_qty | SI | OK | OK | CONFIABLE | Maximum quantity |
| stock_policy | reorder_lote | SI | OK | OK | CONFIABLE | Reorder lot size |
| stock_policy | activo | SI | OK | OK | CONFIABLE | Active flag |
| stock_policy | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| receta | id | SI | OK | OK | CONFIABLE | Primary key |
| receta | codigo | SI | OK | OK | CONFIABLE | Recipe code |
| receta | nombre | SI | OK | OK | CONFIABLE | Recipe name |
| receta | porciones | SI | OK | OK | CONFIABLE | Number of portions |
| receta | pvp_objetivo | SI | OK | OK | CONFIABLE | Target selling price |
| receta | activo | SI | OK | OK | CONFIABLE | Active flag |
| receta | meta | SI | OK | OK | CONFIABLE | Metadata JSON |
| receta_version | id | SI | OK | OK | CONFIABLE | Primary key |
| receta_version | receta_id | SI | OK | OK | CONFIABLE | Foreign key |
| receta_version | version | SI | OK | OK | CONFIABLE | Version number |
| receta_version | descripcion_cambios | SI | OK | OK | CONFIABLE | Changes description |
| receta_version | fecha_efectiva | SI | OK | OK | CONFIABLE | Effective date |
| receta_version | version_publicada | SI | OK | OK | CONFIABLE | Published version flag |
| receta_version | usuario_publicador | SI | OK | OK | CONFIABLE | Publisher user |
| receta_version | fecha_publicacion | SI | OK | OK | CONFIABLE | Publication date |
| receta_version | created_at | SI | OK | OK | CONFIABLE | Creation timestamp |
| receta_insumo | id | SI | OK | OK | CONFIABLE | Primary key |
| receta_insumo | receta_version_id | SI | OK | OK | CONFIABLE | Foreign key |
| receta_insumo | item_id | SI | OK | OK | CONFIABLE | Foreign key |
| receta_insumo | cantidad | SI | OK | OK | CONFIABLE | Quantity needed |
| pos_map | pos_system | SI | OK | OK | CONFIABLE | POS system identifier |
| pos_map | plu | SI | OK | OK | CONFIABLE | PLU code |
| pos_map | tipo | SI | OK | OK | CONFIABLE | Item type |
| pos_map | receta_id | SI | MISMATCH | OK | SOSPECHOSO | Code expects receta_version_id but DB has receta_id |
| pos_map | receta_version_id | SI | MISMATCH | OK | SOSPECHOSO | Code uses receta_version_id but DB has separate receta_id |
| pos_map | valid_from | SI | OK | OK | CONFIABLE | Valid from date |
| pos_map | valid_to | SI | OK | OK | CONFIABLE | Valid to date |
| pos_map | sys_from | SI | OK | OK | CONFIABLE | System from timestamp |
| pos_map | sys_to | SI | OK | OK | CONFIABLE | System to timestamp |
| pos_map | meta | SI | FANTASMA | OK | ERROR_MAPA | Code references 'json' but DB has 'meta' |
| pos_map | vigente_desde | SI | FANTASMA | OK | ERROR_MAPA | Field not referenced in models but exists in DB |
| ticket | id | SI | OK | OK | CONFIABLE | Primary key |
| ticket | global_id | SI | OK | OK | CONFIABLE | Global identifier |
| ticket | create_date | SI | OK | OK | CONFIABLE | Creation date |
| ticket | closing_date | SI | OK | OK | CONFIABLE | Closing date |
| ticket | active_date | SI | OK | OK | CONFIABLE | Active date |
| ticket | deliveery_date | SI | OK | OK | CONFIABLE | Delivery date |
| ticket | creation_hour | SI | OK | OK | CONFIABLE | Creation hour |
| ticket | paid | SI | OK | OK | CONFIABLE | Paid status |
| ticket | voided | SI | OK | OK | CONFIABLE | Voided status |
| ticket | void_reason | SI | OK | OK | CONFIABLE | Void reason |
| ticket | wasted | SI | OK | OK | CONFIABLE | Wasted status |
| ticket | refunded | SI | OK | OK | CONFIABLE | Refunded status |
| ticket | settled | SI | OK | OK | CONFIABLE | Settled status |
| ticket | drawer_resetted | SI | OK | OK | CONFIABLE | Drawer reset status |
| ticket | sub_total | SI | OK | OK | CONFIABLE | Sub total |
| ticket | total_discount | SI | OK | OK | CONFIABLE | Total discount |
| ticket | total_tax | SI | OK | OK | CONFIABLE | Total tax |
| ticket | total_price | SI | OK | OK | CONFIABLE | Total price |
| ticket | paid_amount | SI | OK | OK | CONFIABLE | Paid amount |
| ticket | due_amount | SI | OK | OK | CONFIABLE | Due amount |
| ticket | advance_amount | SI | OK | OK | CONFIABLE | Advance amount |
| ticket | adjustment_amount | SI | OK | OK | CONFIABLE | Adjustment amount |
| ticket | number_of_guests | SI | OK | OK | CONFIABLE | Number of guests |
| ticket | status | SI | OK | OK | CONFIABLE | Status |
| ticket | bar_tab | SI | OK | OK | CONFIABLE | Bar tab flag |
| ticket | is_tax_exempt | SI | OK | OK | CONFIABLE | Tax exempt flag |
| ticket | is_re_opened | SI | OK | OK | CONFIABLE | Reopened flag |
| ticket | service_charge | SI | OK | OK | CONFIABLE | Service charge |
| ticket | delivery_charge | SI | OK | OK | CONFIABLE | Delivery charge |
| ticket | customer_id | SI | OK | OK | CONFIABLE | Customer ID |
| ticket | delivery_address | SI | OK | OK | CONFIABLE | Delivery address |
| ticket | customer_pickeup | SI | OK | OK | CONFIABLE | Customer pickup flag |
| ticket | delivery_extra_info | SI | OK | OK | CONFIABLE | Delivery extra info |
| ticket | ticket_type | SI | OK | OK | CONFIABLE | Ticket type |
| ticket | shift_id | SI | OK | OK | CONFIABLE | Shift ID |
| ticket | owner_id | SI | OK | OK | CONFIABLE | Owner ID |
| ticket | driver_id | SI | OK | OK | CONFIABLE | Driver ID |
| ticket | gratuity_id | SI | OK | OK | CONFIABLE | Gratuity ID |
| ticket | void_by_user | SI | OK | OK | CONFIABLE | Void by user |
| ticket | terminal_id | SI | OK | OK | CONFIABLE | Terminal ID |
| ticket | folio_date | SI | OK | OK | CONFIABLE | Folio date |
| ticket | branch_key | SI | OK | OK | CONFIABLE | Branch key |
| ticket | daily_folio | SI | OK | OK | CONFIABLE | Daily folio |
| ticket_item | id | SI | OK | OK | CONFIABLE | Primary key |
| ticket_item | item_id | SI | OK | OK | CONFIABLE | Item ID |
| ticket_item | item_count | SI | OK | OK | CONFIABLE | Item count |
| ticket_item | item_quantity | SI | OK | OK | CONFIABLE | Item quantity |
| ticket_item | item_name | SI | OK | OK | CONFIABLE | Item name |
| ticket_item | item_unit_name | SI | OK | OK | CONFIABLE | Item unit name |
| ticket_item | group_name | SI | OK | OK | CONFIABLE | Group name |
| ticket_item | category_name | SI | OK | OK | CONFIABLE | Category name |
| ticket_item | item_price | SI | OK | OK | CONFIABLE | Item price |
| ticket_item | item_tax_rate | SI | OK | OK | CONFIABLE | Item tax rate |
| ticket_item | sub_total | SI | OK | OK | CONFIABLE | Sub total |
| ticket_item | sub_total_without_modifiers | SI | OK | OK | CONFIABLE | Sub total without modifiers |
| ticket_item | discount | SI | OK | OK | CONFIABLE | Discount |
| ticket_item | tax_amount | SI | OK | OK | CONFIABLE | Tax amount |
| ticket_item | tax_amount_without_modifiers | SI | OK | OK | CONFIABLE | Tax amount without modifiers |
| ticket_item | total_price | SI | OK | OK | CONFIABLE | Total price |
| ticket_item | total_price_without_modifiers | SI | OK | OK | CONFIABLE | Total price without modifiers |
| ticket_item | beverage | SI | OK | OK | CONFIABLE | Beverage flag |
| ticket_item | inventory_handled | SI | OK | OK | CONFIABLE | Inventory handled flag |
| ticket_item | print_to_kitchen | SI | OK | OK | CONFIABLE | Print to kitchen flag |
| ticket_item | treat_as_seat | SI | OK | OK | CONFIABLE | Treat as seat flag |
| ticket_item | seat_number | SI | OK | OK | CONFIABLE | Seat number |
| ticket_item | fractional_unit | SI | OK | OK | CONFIABLE | Fractional unit flag |
| ticket_item | has_modiiers | SI | MISMATCH | OK | SOSPECHOSO | DB has typo: has_modiiers vs has_modifiers |
| ticket_item | printed_to_kitchen | SI | OK | OK | CONFIABLE | Printed to kitchen flag |
| ticket_item | status | SI | OK | OK | CONFIABLE | Status |
| ticket_item | stock_amount_adjusted | SI | OK | OK | CONFIABLE | Stock amount adjusted |
| ticket_item | pizza_type | SI | OK | OK | CONFIABLE | Pizza type flag |
| ticket_item | size_modifier_id | SI | OK | OK | CONFIABLE | Size modifier ID |
| ticket_item | ticket_id | SI | OK | OK | CONFIABLE | Ticket ID |
| ticket_item | pg_id | SI | OK | OK | CONFIABLE | PG ID |
| ticket_item | pizza_section_mode | SI | OK | OK | CONFIABLE | Pizza section mode |
| menu_item | id | SI | OK | OK | CONFIABLE | Primary key |
| menu_item | name | SI | OK | OK | CONFIABLE | Item name |
| menu_item | description | SI | OK | OK | CONFIABLE | Description |
| menu_item | unit_name | SI | OK | OK | CONFIABLE | Unit name |
| menu_item | translated_name | SI | OK | OK | CONFIABLE | Translated name |
| menu_item | barcode | SI | OK | OK | CONFIABLE | Barcode |
| menu_item | buy_price | SI | OK | OK | CONFIABLE | Buy price |
| menu_item | stock_amount | SI | OK | OK | CONFIABLE | Stock amount |
| menu_item | price | SI | OK | OK | CONFIABLE | Selling price |
| menu_item | discount_rate | SI | OK | OK | CONFIABLE | Discount rate |
| menu_item | visible | SI | OK | OK | CONFIABLE | Visible flag |
| menu_item | disable_when_stock_amount_is_zero | SI | OK | OK | CONFIABLE | Disable when no stock |
| menu_item | sort_order | SI | OK | OK | CONFIABLE | Sort order |
| menu_item | btn_color | SI | OK | OK | CONFIABLE | Button color |
| menu_item | text_color | SI | OK | OK | CONFIABLE | Text color |
| menu_item | image | SI | OK | OK | CONFIABLE | Image |
| menu_item | show_image_only | SI | OK | OK | CONFIABLE | Show image only |
| menu_item | fractional_unit | SI | OK | OK | CONFIABLE | Fractional unit |
| menu_item | pizza_type | SI | OK | OK | CONFIABLE | Pizza type |
| menu_item | default_sell_portion | SI | OK | OK | CONFIABLE | Default selling portion |
| menu_item | group_id | SI | OK | OK | CONFIABLE | Group ID |
| menu_item | tax_group_id | SI | OK | OK | CONFIABLE | Tax group ID |
| menu_item | recepie | SI | OK | OK | CONFIABLE | Recipe ID |
| menu_item | pg_id | SI | OK | OK | CONFIABLE | PG ID |
| menu_item | tax_id | SI | OK | OK | CONFIABLE | Tax ID |
| menu_group | id | SI | OK | OK | CONFIABLE | Primary key |
| menu_group | name | SI | OK | OK | CONFIABLE | Group name |
| menu_group | translated_name | SI | OK | OK | CONFIABLE | Translated name |
| menu_group | visible | SI | OK | OK | CONFIABLE | Visible flag |
| menu_group | sort_order | SI | OK | OK | CONFIABLE | Sort order |
| menu_group | btn_color | SI | OK | OK | CONFIABLE | Button color |
| menu_group | text_color | SI | OK | OK | CONFIABLE | Text color |
| menu_group | category_id | SI | OK | OK | CONFIABLE | Category ID |
| transactions | id | SI | OK | OK | CONFIABLE | Primary key |
| transactions | payment_type | SI | OK | OK | CONFIABLE | Payment type |
| transactions | global_id | SI | OK | OK | CONFIABLE | Global identifier |
| transactions | transaction_time | SI | OK | OK | CONFIABLE | Transaction time |
| transactions | amount | SI | OK | OK | CONFIABLE | Amount |
| transactions | tips_amount | SI | OK | OK | CONFIABLE | Tips amount |
| transactions | tips_exceed_amount | SI | OK | OK | CONFIABLE | Tips exceed amount |
| transactions | tender_amount | SI | OK | OK | CONFIABLE | Tender amount |
| transactions | transaction_type | SI | OK | OK | CONFIABLE | Transaction type |
| transactions | custom_payment_name | SI | OK | OK | CONFIABLE | Custom payment name |
| transactions | custom_payment_ref | SI | OK | OK | CONFIABLE | Custom payment reference |
| transactions | custom_payment_field_name | SI | OK | OK | CONFIABLE | Custom payment field name |
| transactions | payment_sub_type | SI | OK | OK | CONFIABLE | Payment sub type |
| transactions | captured | SI | OK | OK | CONFIABLE | Captured flag |
| transactions | voided | SI | OK | OK | CONFIABLE | Voided flag |
| transactions | authorizable | SI | OK | OK | CONFIABLE | Authorizable flag |
| transactions | card_holder_name | SI | OK | OK | CONFIABLE | Card holder name |
| transactions | card_number | SI | OK | OK | CONFIABLE | Card number |
| transactions | card_auth_code | SI | OK | OK | CONFIABLE | Card auth code |
| transactions | card_type | SI | OK | OK | CONFIABLE | Card type |
| transactions | card_transaction_id | SI | OK | OK | CONFIABLE | Card transaction ID |
| transactions | card_merchant_gateway | SI | OK | OK | CONFIABLE | Card merchant gateway |
| transactions | card_reader | SI | OK | OK | CONFIABLE | Card reader |
| transactions | card_aid | SI | OK | OK | CONFIABLE | Card AID |
| transactions | card_arqc | SI | OK | OK | CONFIABLE | Card ARQC |
| transactions | card_ext_data | SI | OK | OK | CONFIABLE | Card ext data |
| transactions | gift_cert_number | SI | OK | OK | CONFIABLE | Gift cert number |
| transactions | gift_cert_face_value | SI | OK | OK | CONFIABLE | Gift cert face value |
| transactions | gift_cert_paid_amount | SI | OK | OK | CONFIABLE | Gift cert paid amount |
| transactions | gift_cert_cash_back_amount | SI | OK | OK | CONFIABLE | Gift cert cash back amount |
| transactions | drawer_resetted | SI | OK | OK | CONFIABLE | Drawer reset flag |
| transactions | note | SI | OK | OK | CONFIABLE | Note |
| transactions | terminal_id | SI | OK | OK | CONFIABLE | Terminal ID |
| transactions | ticket_id | SI | OK | OK | CONFIABLE | Ticket ID |
| transactions | user_id | SI | OK | OK | CONFIABLE | User ID |
| transactions | payout_reason_id | SI | OK | OK | CONFIABLE | Payout reason ID |
| transactions | payout_recepient_id | SI | OK | OK | CONFIABLE | Payout recipient ID |
| terminal | id | SI | OK | OK | CONFIABLE | Primary key |
| terminal | name | SI | OK | OK | CONFIABLE | Terminal name |
| terminal | terminal_key | SI | OK | OK | CONFIABLE | Terminal key |
| terminal | opening_balance | SI | OK | OK | CONFIABLE | Opening balance |
| terminal | current_balance | SI | OK | OK | CONFIABLE | Current balance |
| terminal | has_cash_drawer | SI | OK | OK | CONFIABLE | Has cash drawer |
| terminal | in_use | SI | OK | OK | CONFIABLE | In use flag |
| terminal | active | SI | OK | OK | CONFIABLE | Active flag |
| terminal | location | SI | OK | OK | CONFIABLE | Location |
| terminal | floor_id | SI | OK | OK | CONFIABLE | Floor ID |
| terminal | assigned_user | SI | OK | OK | CONFIABLE | Assigned user |

## §1 Resumen

- Filas CONFIABLE: 228
- Filas SOSPECHOSO: 11
- Filas ERROR_MAPA: 16

## §2 Listado de filas ERROR_MAPA

- recepcion_det.id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.recepcion_id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.item_id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.bodega_id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.qty: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.um_id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.costo_unit: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.batch_id: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.temperatura: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.doc_url: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.meta: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.created_at: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.updated_at: marcado como 'NO_USADO' pero SI existe en BD
- recepcion_det.deleted_at: marcado como 'NO_USADO' pero SI existe en BD
- pos_map.meta: marcado como 'FANTASMA' pero SI existe en BD
- pos_map.vigente_desde: marcado como 'FANTASMA' pero SI existe en BD

## §3 Sugerencias de corrección

El archivo original 'BD_CODIGO_MAPA_CAMPOS_INV_REC_POS.md' debe actualizarse para reflejar la realidad de la base de datos. Los errores encontrados indican discrepancias entre lo que el mapeo original asumía y la estructura real de la base de datos.

Especialmente importante es corregir las filas marcadas como ERROR_MAPA, donde el estado original contradice directamente la existencia real de los campos en la base de datos.

