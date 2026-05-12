# DICCIONARIO DE DATOS AUTO-GENERADO (selemti)

### TABLA: selemti.alert_events
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('alert_events_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `snapshot_at` | `timestamp without time zone` | `NO` | `NULL` |
| `old_portion_cost` | `numeric` | `YES` | `NULL` |
| `new_portion_cost` | `numeric` | `YES` | `NULL` |
| `delta_pct` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `handled` | `boolean` | `NO` | `false` |
| `assigned_to` | `bigint` | `YES` | `NULL` |
| `acknowledged_at` | `timestamp with time zone` | `YES` | `NULL` |
| `resolution_notes` | `text` | `YES` | `NULL` |
| `severity` | `character varying` | `NO` | `'medium'::character varying` |

### TABLA: selemti.alert_rules
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('alert_rules_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `YES` | `NULL` |
| `category_id` | `bigint` | `YES` | `NULL` |
| `threshold_pct` | `numeric` | `NO` | `10.0` |
| `active` | `boolean` | `NO` | `true` |
| `notes` | `text` | `YES` | `NULL` |
| `scope` | `character varying` | `NO` | `'global'::character varying` |
| `threshold_numeric` | `numeric` | `YES` | `NULL` |
| `threshold_percent` | `numeric` | `YES` | `NULL` |
| `notification_channels` | `jsonb` | `YES` | `NULL` |

### TABLA: selemti.alertas_cortes
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('alertas_cortes_id_seq'::regclass)` |
| `postcorte_id` | `bigint` | `YES` | `NULL` |
| `sesion_id` | `bigint` | `YES` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `destinatario_id` | `integer` | `YES` | `NULL` |
| `leida` | `boolean` | `YES` | `false` |
| `creada_en` | `timestamp with time zone` | `YES` | `now()` |
| `leida_en` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.almacen
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `text` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |

### TABLA: selemti.audit_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('audit_log_id_seq'::regclass)` |
| `timestamp` | `timestamp without time zone` | `NO` | `now()` |
| `user_id` | `bigint` | `NO` | `NULL` |
| `accion` | `character varying` | `NO` | `NULL` |
| `entidad` | `character varying` | `NO` | `NULL` |
| `entidad_id` | `bigint` | `NO` | `NULL` |
| `motivo` | `text` | `YES` | `NULL` |
| `evidencia_url` | `text` | `YES` | `NULL` |
| `payload_json` | `jsonb` | `YES` | `NULL` |

### TABLA: selemti.audit_log_global
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('audit_log_global_id_seq'::regclass)` |
| `schema_name` | `text` | `NO` | `NULL` |
| `table_name` | `text` | `NO` | `NULL` |
| `operation` | `text` | `NO` | `NULL` |
| `record_id` | `text` | `YES` | `NULL` |
| `old_data` | `jsonb` | `YES` | `NULL` |
| `new_data` | `jsonb` | `YES` | `NULL` |
| `changed_by_user_id` | `bigint` | `YES` | `NULL` |
| `changed_at` | `timestamp without time zone` | `YES` | `now()` |
| `ip_address` | `inet` | `YES` | `NULL` |
| `user_agent` | `text` | `YES` | `NULL` |

### TABLA: selemti.auditoria
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('auditoria_id_seq'::regclass)` |
| `quien` | `integer` | `YES` | `NULL` |
| `que` | `text` | `NO` | `NULL` |
| `payload` | `jsonb` | `YES` | `NULL` |
| `creado_en` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.backup_tickets_cierre_masivo_20251112_112653
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `YES` | `NULL` |
| `global_id` | `character varying` | `YES` | `NULL` |
| `create_date` | `timestamp without time zone` | `YES` | `NULL` |
| `closing_date` | `timestamp without time zone` | `YES` | `NULL` |
| `active_date` | `timestamp without time zone` | `YES` | `NULL` |
| `deliveery_date` | `timestamp without time zone` | `YES` | `NULL` |
| `creation_hour` | `integer` | `YES` | `NULL` |
| `paid` | `boolean` | `YES` | `NULL` |
| `voided` | `boolean` | `YES` | `NULL` |
| `void_reason` | `character varying` | `YES` | `NULL` |
| `wasted` | `boolean` | `YES` | `NULL` |
| `refunded` | `boolean` | `YES` | `NULL` |
| `settled` | `boolean` | `YES` | `NULL` |
| `drawer_resetted` | `boolean` | `YES` | `NULL` |
| `sub_total` | `double precision` | `YES` | `NULL` |
| `total_discount` | `double precision` | `YES` | `NULL` |
| `total_tax` | `double precision` | `YES` | `NULL` |
| `total_price` | `double precision` | `YES` | `NULL` |
| `paid_amount` | `double precision` | `YES` | `NULL` |
| `due_amount` | `double precision` | `YES` | `NULL` |
| `advance_amount` | `double precision` | `YES` | `NULL` |
| `adjustment_amount` | `double precision` | `YES` | `NULL` |
| `number_of_guests` | `integer` | `YES` | `NULL` |
| `status` | `character varying` | `YES` | `NULL` |
| `bar_tab` | `boolean` | `YES` | `NULL` |
| `is_tax_exempt` | `boolean` | `YES` | `NULL` |
| `is_re_opened` | `boolean` | `YES` | `NULL` |
| `service_charge` | `double precision` | `YES` | `NULL` |
| `delivery_charge` | `double precision` | `YES` | `NULL` |
| `customer_id` | `integer` | `YES` | `NULL` |
| `delivery_address` | `character varying` | `YES` | `NULL` |
| `customer_pickeup` | `boolean` | `YES` | `NULL` |
| `delivery_extra_info` | `character varying` | `YES` | `NULL` |
| `ticket_type` | `character varying` | `YES` | `NULL` |
| `shift_id` | `integer` | `YES` | `NULL` |
| `owner_id` | `integer` | `YES` | `NULL` |
| `driver_id` | `integer` | `YES` | `NULL` |
| `gratuity_id` | `integer` | `YES` | `NULL` |
| `void_by_user` | `integer` | `YES` | `NULL` |
| `terminal_id` | `integer` | `YES` | `NULL` |
| `folio_date` | `date` | `YES` | `NULL` |
| `branch_key` | `text` | `YES` | `NULL` |
| `daily_folio` | `integer` | `YES` | `NULL` |
| `backup_timestamp` | `timestamp with time zone` | `YES` | `NULL` |
| `backup_user_id` | `integer` | `YES` | `NULL` |
| `backup_user_name` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.backup_tickets_cierre_masivo_20251112_121131
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `YES` | `NULL` |
| `global_id` | `character varying` | `YES` | `NULL` |
| `create_date` | `timestamp without time zone` | `YES` | `NULL` |
| `closing_date` | `timestamp without time zone` | `YES` | `NULL` |
| `active_date` | `timestamp without time zone` | `YES` | `NULL` |
| `deliveery_date` | `timestamp without time zone` | `YES` | `NULL` |
| `creation_hour` | `integer` | `YES` | `NULL` |
| `paid` | `boolean` | `YES` | `NULL` |
| `voided` | `boolean` | `YES` | `NULL` |
| `void_reason` | `character varying` | `YES` | `NULL` |
| `wasted` | `boolean` | `YES` | `NULL` |
| `refunded` | `boolean` | `YES` | `NULL` |
| `settled` | `boolean` | `YES` | `NULL` |
| `drawer_resetted` | `boolean` | `YES` | `NULL` |
| `sub_total` | `double precision` | `YES` | `NULL` |
| `total_discount` | `double precision` | `YES` | `NULL` |
| `total_tax` | `double precision` | `YES` | `NULL` |
| `total_price` | `double precision` | `YES` | `NULL` |
| `paid_amount` | `double precision` | `YES` | `NULL` |
| `due_amount` | `double precision` | `YES` | `NULL` |
| `advance_amount` | `double precision` | `YES` | `NULL` |
| `adjustment_amount` | `double precision` | `YES` | `NULL` |
| `number_of_guests` | `integer` | `YES` | `NULL` |
| `status` | `character varying` | `YES` | `NULL` |
| `bar_tab` | `boolean` | `YES` | `NULL` |
| `is_tax_exempt` | `boolean` | `YES` | `NULL` |
| `is_re_opened` | `boolean` | `YES` | `NULL` |
| `service_charge` | `double precision` | `YES` | `NULL` |
| `delivery_charge` | `double precision` | `YES` | `NULL` |
| `customer_id` | `integer` | `YES` | `NULL` |
| `delivery_address` | `character varying` | `YES` | `NULL` |
| `customer_pickeup` | `boolean` | `YES` | `NULL` |
| `delivery_extra_info` | `character varying` | `YES` | `NULL` |
| `ticket_type` | `character varying` | `YES` | `NULL` |
| `shift_id` | `integer` | `YES` | `NULL` |
| `owner_id` | `integer` | `YES` | `NULL` |
| `driver_id` | `integer` | `YES` | `NULL` |
| `gratuity_id` | `integer` | `YES` | `NULL` |
| `void_by_user` | `integer` | `YES` | `NULL` |
| `terminal_id` | `integer` | `YES` | `NULL` |
| `folio_date` | `date` | `YES` | `NULL` |
| `branch_key` | `text` | `YES` | `NULL` |
| `daily_folio` | `integer` | `YES` | `NULL` |
| `backup_timestamp` | `timestamp with time zone` | `YES` | `NULL` |
| `backup_user_id` | `integer` | `YES` | `NULL` |
| `backup_user_name` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.backup_tickets_cierre_masivo_20251112_121211
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `YES` | `NULL` |
| `global_id` | `character varying` | `YES` | `NULL` |
| `create_date` | `timestamp without time zone` | `YES` | `NULL` |
| `closing_date` | `timestamp without time zone` | `YES` | `NULL` |
| `active_date` | `timestamp without time zone` | `YES` | `NULL` |
| `deliveery_date` | `timestamp without time zone` | `YES` | `NULL` |
| `creation_hour` | `integer` | `YES` | `NULL` |
| `paid` | `boolean` | `YES` | `NULL` |
| `voided` | `boolean` | `YES` | `NULL` |
| `void_reason` | `character varying` | `YES` | `NULL` |
| `wasted` | `boolean` | `YES` | `NULL` |
| `refunded` | `boolean` | `YES` | `NULL` |
| `settled` | `boolean` | `YES` | `NULL` |
| `drawer_resetted` | `boolean` | `YES` | `NULL` |
| `sub_total` | `double precision` | `YES` | `NULL` |
| `total_discount` | `double precision` | `YES` | `NULL` |
| `total_tax` | `double precision` | `YES` | `NULL` |
| `total_price` | `double precision` | `YES` | `NULL` |
| `paid_amount` | `double precision` | `YES` | `NULL` |
| `due_amount` | `double precision` | `YES` | `NULL` |
| `advance_amount` | `double precision` | `YES` | `NULL` |
| `adjustment_amount` | `double precision` | `YES` | `NULL` |
| `number_of_guests` | `integer` | `YES` | `NULL` |
| `status` | `character varying` | `YES` | `NULL` |
| `bar_tab` | `boolean` | `YES` | `NULL` |
| `is_tax_exempt` | `boolean` | `YES` | `NULL` |
| `is_re_opened` | `boolean` | `YES` | `NULL` |
| `service_charge` | `double precision` | `YES` | `NULL` |
| `delivery_charge` | `double precision` | `YES` | `NULL` |
| `customer_id` | `integer` | `YES` | `NULL` |
| `delivery_address` | `character varying` | `YES` | `NULL` |
| `customer_pickeup` | `boolean` | `YES` | `NULL` |
| `delivery_extra_info` | `character varying` | `YES` | `NULL` |
| `ticket_type` | `character varying` | `YES` | `NULL` |
| `shift_id` | `integer` | `YES` | `NULL` |
| `owner_id` | `integer` | `YES` | `NULL` |
| `driver_id` | `integer` | `YES` | `NULL` |
| `gratuity_id` | `integer` | `YES` | `NULL` |
| `void_by_user` | `integer` | `YES` | `NULL` |
| `terminal_id` | `integer` | `YES` | `NULL` |
| `folio_date` | `date` | `YES` | `NULL` |
| `branch_key` | `text` | `YES` | `NULL` |
| `daily_folio` | `integer` | `YES` | `NULL` |
| `backup_timestamp` | `timestamp with time zone` | `YES` | `NULL` |
| `backup_user_id` | `integer` | `YES` | `NULL` |
| `backup_user_name` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.bkp_reversion_postcorte
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `YES` | `NULL` |
| `sesion_id` | `bigint` | `YES` | `NULL` |
| `sistema_efectivo_esperado` | `numeric` | `YES` | `NULL` |
| `declarado_efectivo` | `numeric` | `YES` | `NULL` |
| `diferencia_efectivo` | `numeric` | `YES` | `NULL` |
| `veredicto_efectivo` | `text` | `YES` | `NULL` |
| `sistema_tarjetas` | `numeric` | `YES` | `NULL` |
| `declarado_tarjetas` | `numeric` | `YES` | `NULL` |
| `diferencia_tarjetas` | `numeric` | `YES` | `NULL` |
| `veredicto_tarjetas` | `text` | `YES` | `NULL` |
| `creado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `creado_por` | `integer` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `sistema_transferencias` | `numeric` | `YES` | `NULL` |
| `declarado_transferencias` | `numeric` | `YES` | `NULL` |
| `diferencia_transferencias` | `numeric` | `YES` | `NULL` |
| `veredicto_transferencias` | `text` | `YES` | `NULL` |
| `validado` | `boolean` | `YES` | `NULL` |
| `validado_por` | `integer` | `YES` | `NULL` |
| `validado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `requiere_aprobacion` | `boolean` | `YES` | `NULL` |
| `aprobado_por` | `integer` | `YES` | `NULL` |
| `aprobado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `motivo_irregular` | `text` | `YES` | `NULL` |
| `rechazado` | `boolean` | `YES` | `NULL` |
| `motivo_rechazo` | `text` | `YES` | `NULL` |
| `total_ventas_brutas` | `numeric` | `YES` | `NULL` |
| `total_ventas_netas` | `numeric` | `YES` | `NULL` |
| `total_descuentos_drawer` | `numeric` | `YES` | `NULL` |
| `total_descuentos_reales` | `numeric` | `YES` | `NULL` |
| `diferencia_descuentos` | `numeric` | `YES` | `NULL` |
| `porcentaje_error_descuentos` | `numeric` | `YES` | `NULL` |
| `calidad_reporte_descuentos` | `text` | `YES` | `NULL` |

### TABLA: selemti.bodega
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('bodega_id_seq'::regclass)` |
| `sucursal_id` | `bigint` | `NO` | `NULL` |
| `codigo` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |

### TABLA: selemti.cache
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `key` | `character varying` | `NO` | `NULL` |
| `value` | `text` | `NO` | `NULL` |
| `expiration` | `integer` | `NO` | `NULL` |

### TABLA: selemti.cache_locks
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `key` | `character varying` | `NO` | `NULL` |
| `owner` | `character varying` | `NO` | `NULL` |
| `expiration` | `integer` | `NO` | `NULL` |

### TABLA: selemti.caja_fondo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('caja_fondo_id_seq'::regclass)` |
| `sucursal_id` | `integer` | `NO` | `NULL` |
| `fecha` | `date` | `NO` | `NULL` |
| `monto_inicial` | `numeric` | `NO` | `NULL` |
| `moneda` | `character varying` | `YES` | `'MXN'::character varying` |
| `estado` | `character varying` | `NO` | `'ABIERTO'::character varying` |
| `creado_por` | `integer` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.caja_fondo_adj
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('caja_fondo_adj_id_seq'::regclass)` |
| `mov_id` | `bigint` | `YES` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `archivo_url` | `text` | `NO` | `NULL` |
| `observaciones` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.caja_fondo_arqueo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('caja_fondo_arqueo_id_seq'::regclass)` |
| `fondo_id` | `bigint` | `YES` | `NULL` |
| `fecha_cierre` | `timestamp without time zone` | `NO` | `now()` |
| `efectivo_contado` | `numeric` | `NO` | `NULL` |
| `diferencia` | `numeric` | `NO` | `NULL` |
| `observaciones` | `text` | `YES` | `NULL` |
| `cerrado_por` | `integer` | `NO` | `NULL` |

### TABLA: selemti.caja_fondo_mov
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('caja_fondo_mov_id_seq'::regclass)` |
| `fondo_id` | `bigint` | `YES` | `NULL` |
| `fecha_hora` | `timestamp without time zone` | `NO` | `now()` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `concepto` | `text` | `NO` | `NULL` |
| `proveedor_id` | `integer` | `YES` | `NULL` |
| `monto` | `numeric` | `NO` | `NULL` |
| `metodo` | `character varying` | `NO` | `'EFECTIVO'::character varying` |
| `requiere_comprobante` | `boolean` | `YES` | `false` |
| `estatus` | `character varying` | `NO` | `'CAPTURADO'::character varying` |
| `creado_por` | `integer` | `NO` | `NULL` |
| `aprobado_por` | `integer` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.caja_fondo_usuario
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `fondo_id` | `bigint` | `NO` | `NULL` |
| `user_id` | `integer` | `NO` | `NULL` |
| `rol` | `character varying` | `NO` | `NULL` |

### TABLA: selemti.cash_fund_arqueos
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cash_fund_arqueos_id_seq'::regclass)` |
| `cash_fund_id` | `bigint` | `NO` | `NULL` |
| `monto_esperado` | `numeric` | `NO` | `NULL` |
| `monto_contado` | `numeric` | `NO` | `NULL` |
| `diferencia` | `numeric` | `NO` | `NULL` |
| `observaciones` | `text` | `YES` | `NULL` |
| `created_by_user_id` | `bigint` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.cash_fund_movement_audit_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cash_fund_movement_audit_log_id_seq'::regclass)` |
| `movement_id` | `bigint` | `NO` | `NULL` |
| `action` | `character varying` | `NO` | `NULL` |
| `field_changed` | `character varying` | `YES` | `NULL` |
| `old_value` | `text` | `YES` | `NULL` |
| `new_value` | `text` | `YES` | `NULL` |
| `observaciones` | `text` | `YES` | `NULL` |
| `changed_by_user_id` | `integer` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.cash_fund_movements
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cash_fund_movements_id_seq'::regclass)` |
| `cash_fund_id` | `bigint` | `NO` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `concepto` | `text` | `NO` | `NULL` |
| `proveedor_id` | `integer` | `YES` | `NULL` |
| `monto` | `numeric` | `NO` | `NULL` |
| `metodo` | `character varying` | `NO` | `NULL` |
| `estatus` | `character varying` | `NO` | `'APROBADO'::character varying` |
| `requiere_comprobante` | `boolean` | `NO` | `false` |
| `tiene_comprobante` | `boolean` | `NO` | `false` |
| `adjunto_path` | `character varying` | `YES` | `NULL` |
| `created_by_user_id` | `bigint` | `NO` | `NULL` |
| `approved_by_user_id` | `bigint` | `YES` | `NULL` |
| `approved_at` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.cash_funds
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cash_funds_id_seq'::regclass)` |
| `sucursal_id` | `integer` | `NO` | `NULL` |
| `fecha` | `date` | `NO` | `NULL` |
| `monto_inicial` | `numeric` | `NO` | `NULL` |
| `moneda` | `character varying` | `NO` | `'MXN'::character varying` |
| `estado` | `character varying` | `NO` | `'ABIERTO'::character varying` |
| `responsable_user_id` | `bigint` | `NO` | `NULL` |
| `created_by_user_id` | `bigint` | `NO` | `NULL` |
| `closed_at` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |
| `descripcion` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.cat_almacenes
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cat_almacenes_id_seq'::regclass)` |
| `clave` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.cat_proveedores
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cat_proveedores_id_seq'::regclass)` |
| `rfc` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `telefono` | `character varying` | `YES` | `NULL` |
| `email` | `character varying` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |
| `razon_social` | `character varying` | `YES` | `NULL` |
| `tipo_comprobante` | `character varying` | `YES` | `NULL` |
| `uso_cfdi` | `character varying` | `YES` | `NULL` |
| `metodo_pago` | `character varying` | `YES` | `NULL` |
| `forma_pago` | `character varying` | `YES` | `NULL` |
| `regimen_fiscal` | `character varying` | `YES` | `NULL` |
| `contacto_nombre` | `character varying` | `YES` | `NULL` |
| `contacto_email` | `character varying` | `YES` | `NULL` |
| `contacto_telefono` | `character varying` | `YES` | `NULL` |
| `direccion` | `character varying` | `YES` | `NULL` |
| `ciudad` | `character varying` | `YES` | `NULL` |
| `estado` | `character varying` | `YES` | `NULL` |
| `pais` | `character varying` | `YES` | `NULL` |
| `cp` | `character varying` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |

### TABLA: selemti.cat_sucursales
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cat_sucursales_id_seq'::regclass)` |
| `clave` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `ubicacion` | `character varying` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.cat_unidades
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cat_unidades_id_seq'::regclass)` |
| `clave` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.cat_uom_conversion
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cat_uom_conversion_id_seq'::regclass)` |
| `origen_id` | `bigint` | `NO` | `NULL` |
| `destino_id` | `bigint` | `NO` | `NULL` |
| `factor` | `numeric` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |
| `is_exact` | `boolean` | `YES` | `true` |
| `scope` | `character varying` | `YES` | `'global'::character varying` |
| `notes` | `text` | `YES` | `NULL` |

### TABLA: selemti.conciliacion
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('conciliacion_id_seq'::regclass)` |
| `postcorte_id` | `bigint` | `NO` | `NULL` |
| `conciliado_por` | `integer` | `YES` | `NULL` |
| `conciliado_en` | `timestamp with time zone` | `YES` | `now()` |
| `estatus` | `text` | `NO` | `'EN_REVISION'::text` |
| `notas` | `text` | `YES` | `NULL` |

### TABLA: selemti.conversiones_unidad_legacy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('conversiones_unidad_id_seq'::regclass)` |
| `unidad_origen_id` | `integer` | `NO` | `NULL` |
| `unidad_destino_id` | `integer` | `NO` | `NULL` |
| `factor_conversion` | `numeric` | `NO` | `NULL` |
| `formula_directa` | `text` | `YES` | `NULL` |
| `precision_estimada` | `numeric` | `YES` | `1.0` |
| `activo` | `boolean` | `YES` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.cost_layer
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('cost_layer_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `batch_id` | `bigint` | `YES` | `NULL` |
| `ts_in` | `timestamp without time zone` | `NO` | `NULL` |
| `qty_in` | `numeric` | `NO` | `NULL` |
| `qty_left` | `numeric` | `NO` | `NULL` |
| `unit_cost` | `numeric` | `NO` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `source_ref` | `text` | `YES` | `NULL` |
| `source_id` | `bigint` | `YES` | `NULL` |

### TABLA: selemti.failed_jobs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('failed_jobs_id_seq'::regclass)` |
| `uuid` | `character varying` | `NO` | `NULL` |
| `connection` | `text` | `NO` | `NULL` |
| `queue` | `text` | `NO` | `NULL` |
| `payload` | `text` | `NO` | `NULL` |
| `exception` | `text` | `NO` | `NULL` |
| `failed_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.formas_pago
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('formas_pago_id_seq'::regclass)` |
| `codigo` | `text` | `NO` | `NULL` |
| `payment_type` | `text` | `YES` | `NULL` |
| `transaction_type` | `text` | `YES` | `NULL` |
| `payment_sub_type` | `text` | `YES` | `NULL` |
| `custom_name` | `text` | `YES` | `NULL` |
| `custom_ref` | `text` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `prioridad` | `integer` | `NO` | `100` |
| `creado_en` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.hist_cost_insumo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('hist_cost_insumo_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `fecha_efectiva` | `date` | `NO` | `NULL` |
| `costo_wac` | `numeric` | `YES` | `NULL` |
| `costo_peps` | `numeric` | `YES` | `NULL` |
| `costo_ueps` | `numeric` | `YES` | `NULL` |
| `costo_std` | `numeric` | `YES` | `NULL` |
| `algoritmo_principal` | `text` | `YES` | `'WAC'::text` |
| `valid_from` | `date` | `NO` | `('now'::text)::date` |
| `valid_to` | `date` | `YES` | `NULL` |
| `sys_from` | `timestamp without time zone` | `NO` | `now()` |
| `sys_to` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.hist_cost_receta
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('hist_cost_receta_id_seq'::regclass)` |
| `receta_version_id` | `bigint` | `NO` | `NULL` |
| `fecha_calculo` | `date` | `NO` | `NULL` |
| `costo_total` | `numeric` | `YES` | `NULL` |
| `costo_porcion` | `numeric` | `YES` | `NULL` |
| `algoritmo_utilizado` | `text` | `YES` | `'WAC'::text` |
| `valid_from` | `date` | `NO` | `('now'::text)::date` |
| `valid_to` | `date` | `YES` | `NULL` |
| `sys_from` | `timestamp without time zone` | `NO` | `now()` |
| `sys_to` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.historial_costos_item
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('historial_costos_item_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `fecha_efectiva` | `date` | `NO` | `NULL` |
| `fecha_registro` | `timestamp without time zone` | `YES` | `now()` |
| `costo_anterior` | `numeric` | `YES` | `NULL` |
| `costo_nuevo` | `numeric` | `YES` | `NULL` |
| `tipo_cambio` | `character varying` | `YES` | `NULL` |
| `referencia_id` | `integer` | `YES` | `NULL` |
| `referencia_tipo` | `character varying` | `YES` | `NULL` |
| `usuario_id` | `integer` | `YES` | `NULL` |
| `valid_from` | `date` | `NO` | `NULL` |
| `valid_to` | `date` | `YES` | `NULL` |
| `sys_from` | `timestamp without time zone` | `NO` | `now()` |
| `sys_to` | `timestamp without time zone` | `YES` | `NULL` |
| `costo_wac` | `numeric` | `YES` | `NULL` |
| `costo_peps` | `numeric` | `YES` | `NULL` |
| `costo_ueps` | `numeric` | `YES` | `NULL` |
| `costo_estandar` | `numeric` | `YES` | `NULL` |
| `algoritmo_principal` | `character varying` | `YES` | `'WAC'::character varying` |
| `version_datos` | `integer` | `YES` | `1` |
| `recalculado` | `boolean` | `YES` | `false` |
| `fuente_datos` | `character varying` | `YES` | `NULL` |
| `metadata_calculo` | `json` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.historial_costos_receta
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('historial_costos_receta_id_seq'::regclass)` |
| `receta_version_id` | `integer` | `NO` | `NULL` |
| `fecha_calculo` | `date` | `NO` | `NULL` |
| `costo_total` | `numeric` | `YES` | `NULL` |
| `costo_porcion` | `numeric` | `YES` | `NULL` |
| `algoritmo_utilizado` | `character varying` | `YES` | `NULL` |
| `version_datos` | `integer` | `YES` | `1` |
| `metadata_calculo` | `json` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `valid_from` | `date` | `NO` | `NULL` |
| `valid_to` | `date` | `YES` | `NULL` |
| `sys_from` | `timestamp without time zone` | `NO` | `now()` |
| `sys_to` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.insumo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('insumo_id_seq'::regclass)` |
| `sku` | `text` | `YES` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `um_id` | `integer` | `NO` | `NULL` |
| `perecible` | `boolean` | `NO` | `false` |
| `merma_pct` | `numeric` | `NO` | `0.000` |
| `activo` | `boolean` | `NO` | `true` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `codigo` | `character varying` | `YES` | `NULL` |
| `categoria_codigo` | `character varying` | `YES` | `NULL` |
| `subcategoria_codigo` | `character varying` | `YES` | `NULL` |
| `consecutivo` | `integer` | `YES` | `NULL` |
| `codigo_alterno` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.insumo_presentacion
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('insumo_presentacion_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `proveedor_id` | `integer` | `YES` | `NULL` |
| `um_compra_id` | `integer` | `NO` | `NULL` |
| `factor_a_um` | `numeric` | `NO` | `1.0` |
| `costo_ultimo` | `numeric` | `NO` | `0.0` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.insumo_proveedor_presentacion
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('insumo_proveedor_presentacion_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `proveedor_id` | `text` | `NO` | `NULL` |
| `uom_compra_id` | `integer` | `NO` | `NULL` |
| `cantidad_en_uom_compra` | `numeric` | `NO` | `1` |
| `uom_base_id` | `integer` | `NO` | `NULL` |
| `factor_a_base` | `numeric` | `NO` | `1` |
| `precio_compra` | `numeric` | `YES` | `NULL` |
| `moneda` | `character` | `NO` | `'MXN'::bpchar` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp with time zone` | `NO` | `now()` |
| `updated_at` | `timestamp with time zone` | `NO` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.inv_consumo_pos
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inv_consumo_pos_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `ticket_item_id` | `bigint` | `YES` | `NULL` |
| `sucursal_id` | `integer` | `NO` | `NULL` |
| `terminal_id` | `integer` | `NO` | `NULL` |
| `estado` | `character varying` | `NO` | `'PENDIENTE'::character varying` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `requiere_reproceso` | `boolean` | `NO` | `true` |
| `procesado` | `boolean` | `NO` | `false` |
| `fecha_proceso` | `timestamp without time zone` | `YES` | `NULL` |
| `revertido` | `boolean` | `NO` | `false` |

### TABLA: selemti.inv_consumo_pos_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inv_consumo_pos_det_id_seq'::regclass)` |
| `consumo_id` | `bigint` | `YES` | `NULL` |
| `mp_id` | `integer` | `NO` | `NULL` |
| `uom_id` | `integer` | `YES` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `factor` | `numeric` | `NO` | `1` |
| `origen` | `character varying` | `NO` | `NULL` |
| `requiere_reproceso` | `boolean` | `NO` | `true` |
| `procesado` | `boolean` | `NO` | `false` |
| `fecha_proceso` | `timestamp without time zone` | `YES` | `NULL` |
| `revertido` | `boolean` | `NO` | `false` |

### TABLA: selemti.inv_consumo_pos_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inv_consumo_pos_log_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `accion` | `character varying` | `NO` | `NULL` |
| `registrado_en` | `timestamp with time zone` | `NO` | `now()` |
| `payload` | `jsonb` | `YES` | `NULL` |

### TABLA: selemti.inv_stock_policy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inv_stock_policy_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `NO` | `NULL` |
| `min_qty` | `numeric` | `NO` | `'0'::numeric` |
| `max_qty` | `numeric` | `NO` | `'0'::numeric` |
| `reorder_qty` | `numeric` | `NO` | `'0'::numeric` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.inventory_batch
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('inventory_batch_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `lote_proveedor` | `character varying` | `NO` | `NULL` |
| `fecha_recepcion` | `date` | `NO` | `NULL` |
| `fecha_caducidad` | `date` | `NO` | `NULL` |
| `temperatura_recepcion` | `numeric` | `YES` | `NULL` |
| `documento_url` | `character varying` | `YES` | `NULL` |
| `cantidad_original` | `numeric` | `NO` | `NULL` |
| `cantidad_actual` | `numeric` | `NO` | `NULL` |
| `estado` | `character varying` | `YES` | `'ACTIVO'::character varying` |
| `ubicacion_id` | `character varying` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `unit_cost` | `numeric` | `NO` | `'0'::numeric` |

### TABLA: selemti.inventory_count_lines
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inventory_count_lines_id_seq'::regclass)` |
| `inventory_count_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `inventory_batch_id` | `bigint` | `YES` | `NULL` |
| `qty_teorica` | `numeric` | `NO` | `'0'::numeric` |
| `qty_contada` | `numeric` | `NO` | `'0'::numeric` |
| `qty_variacion` | `numeric` | `NO` | `'0'::numeric` |
| `uom` | `character varying` | `NO` | `NULL` |
| `motivo` | `character varying` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.inventory_counts
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inventory_counts_id_seq'::regclass)` |
| `folio` | `character varying` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `almacen_id` | `character varying` | `YES` | `NULL` |
| `programado_para` | `timestamp with time zone` | `YES` | `NULL` |
| `iniciado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `cerrado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'BORRADOR'::character varying` |
| `creado_por` | `bigint` | `YES` | `NULL` |
| `cerrado_por` | `bigint` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `total_items` | `numeric` | `NO` | `'0'::numeric` |
| `total_variacion` | `numeric` | `NO` | `'0'::numeric` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.inventory_snapshot
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `snapshot_date` | `date` | `NO` | `NULL` |
| `branch_id` | `text` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `teorico_qty` | `numeric` | `NO` | `NULL` |
| `fisico_qty` | `numeric` | `YES` | `NULL` |
| `teorico_cost` | `numeric` | `YES` | `NULL` |
| `valor_teorico` | `numeric` | `YES` | `NULL` |
| `variance_qty` | `numeric` | `YES` | `NULL` |
| `variance_cost` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `NO` | `now()` |
| `updated_at` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.inventory_wastes
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('inventory_wastes_id_seq'::regclass)` |
| `production_order_id` | `bigint` | `YES` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `inventory_batch_id` | `bigint` | `YES` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `motivo` | `character varying` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `almacen_id` | `character varying` | `YES` | `NULL` |
| `user_id` | `bigint` | `YES` | `NULL` |
| `ref_tipo` | `character varying` | `YES` | `NULL` |
| `ref_id` | `bigint` | `YES` | `NULL` |
| `registrado_en` | `timestamp with time zone` | `NO` | `now()` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.item_categories
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('item_categories_id_seq'::regclass)` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `slug` | `character varying` | `YES` | `NULL` |
| `codigo` | `character varying` | `YES` | `NULL` |
| `descripcion` | `text` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `prefijo` | `character varying` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.item_category_counters
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `category_id` | `bigint` | `NO` | `NULL` |
| `last_val` | `bigint` | `NO` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.item_vendor
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `item_id` | `text` | `NO` | `NULL` |
| `vendor_id` | `text` | `NO` | `NULL` |
| `presentacion` | `text` | `NO` | `NULL` |
| `unidad_presentacion_id` | `integer` | `NO` | `NULL` |
| `factor_a_canonica` | `numeric` | `NO` | `NULL` |
| `costo_ultimo` | `numeric` | `NO` | `NULL` |
| `moneda` | `text` | `NO` | `'MXN'::text` |
| `lead_time_dias` | `integer` | `YES` | `NULL` |
| `codigo_proveedor` | `text` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |
| `preferente` | `boolean` | `YES` | `false` |
| `vendor_sku` | `character varying` | `YES` | `NULL` |
| `vendor_descripcion` | `character varying` | `YES` | `NULL` |
| `currency_code` | `character varying` | `YES` | `NULL` |
| `lead_time_days` | `integer` | `YES` | `NULL` |
| `min_order_qty` | `numeric` | `YES` | `NULL` |
| `pack_qty` | `numeric` | `YES` | `NULL` |
| `pack_uom` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.item_vendor_prices
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('item_vendor_prices_id_seq'::regclass)` |
| `item_id` | `bigint` | `NO` | `NULL` |
| `vendor_id` | `bigint` | `NO` | `NULL` |
| `price` | `numeric` | `NO` | `NULL` |
| `currency_code` | `character varying` | `YES` | `'MXN'::character varying` |
| `pack_qty` | `numeric` | `NO` | `1` |
| `pack_uom` | `character varying` | `NO` | `NULL` |
| `notes` | `text` | `YES` | `NULL` |
| `source` | `character varying` | `YES` | `NULL` |
| `effective_from` | `timestamp without time zone` | `NO` | `now()` |
| `effective_to` | `timestamp without time zone` | `YES` | `NULL` |
| `created_by` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.items
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `descripcion` | `text` | `YES` | `NULL` |
| `categoria_id` | `character varying` | `NO` | `NULL` |
| `unidad_medida` | `character varying` | `NO` | `'PZ'::character varying` |
| `perishable` | `boolean` | `YES` | `false` |
| `temperatura_min` | `integer` | `YES` | `NULL` |
| `temperatura_max` | `integer` | `YES` | `NULL` |
| `costo_promedio` | `numeric` | `YES` | `0.00` |
| `activo` | `boolean` | `YES` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `unidad_medida_id` | `integer` | `YES` | `NULL` |
| `factor_conversion` | `numeric` | `YES` | `1.0` |
| `unidad_compra_id` | `integer` | `YES` | `NULL` |
| `factor_compra` | `numeric` | `YES` | `1.0` |
| `tipo` | `USER-DEFINED` | `YES` | `NULL` |
| `unidad_salida_id` | `integer` | `YES` | `NULL` |
| `category_id` | `bigint` | `YES` | `NULL` |
| `item_code` | `character varying` | `YES` | `NULL` |
| `es_producible` | `boolean` | `NO` | `false` |
| `es_consumible_operativo` | `boolean` | `NO` | `false` |
| `es_empaque_to_go` | `boolean` | `NO` | `false` |

### TABLA: selemti.job_batches
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `character varying` | `NO` | `NULL` |
| `name` | `character varying` | `NO` | `NULL` |
| `total_jobs` | `integer` | `NO` | `NULL` |
| `pending_jobs` | `integer` | `NO` | `NULL` |
| `failed_jobs` | `integer` | `NO` | `NULL` |
| `failed_job_ids` | `text` | `NO` | `NULL` |
| `options` | `text` | `YES` | `NULL` |
| `cancelled_at` | `integer` | `YES` | `NULL` |
| `created_at` | `integer` | `NO` | `NULL` |
| `finished_at` | `integer` | `YES` | `NULL` |

### TABLA: selemti.job_recalc_queue
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('job_recalc_queue_id_seq'::regclass)` |
| `scope_type` | `text` | `NO` | `NULL` |
| `scope_from` | `date` | `YES` | `NULL` |
| `scope_to` | `date` | `YES` | `NULL` |
| `item_id` | `character varying` | `YES` | `NULL` |
| `receta_id` | `character varying` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `reason` | `text` | `YES` | `NULL` |
| `created_ts` | `timestamp without time zone` | `NO` | `now()` |
| `status` | `text` | `NO` | `'PENDING'::text` |
| `result` | `json` | `YES` | `NULL` |

### TABLA: selemti.jobs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('jobs_id_seq'::regclass)` |
| `queue` | `character varying` | `NO` | `NULL` |
| `payload` | `text` | `NO` | `NULL` |
| `attempts` | `smallint` | `NO` | `NULL` |
| `reserved_at` | `integer` | `YES` | `NULL` |
| `available_at` | `integer` | `NO` | `NULL` |
| `created_at` | `integer` | `NO` | `NULL` |

### TABLA: selemti.labor_roles
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('labor_roles_id_seq'::regclass)` |
| `clave` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `rate_per_hour` | `numeric` | `NO` | `'0'::numeric` |
| `activo` | `boolean` | `NO` | `true` |
| `descripcion` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.lote
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('lote_id_seq'::regclass)` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `proveedor_id` | `integer` | `YES` | `NULL` |
| `codigo` | `text` | `YES` | `NULL` |
| `caducidad` | `date` | `YES` | `NULL` |
| `estado` | `USER-DEFINED` | `NO` | `'ACTIVO'::lote_estado` |
| `creado_ts` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.menu_engineering_snapshots
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('menu_engineering_snapshots_id_seq'::regclass)` |
| `menu_item_id` | `bigint` | `NO` | `NULL` |
| `period_start` | `date` | `NO` | `NULL` |
| `period_end` | `date` | `NO` | `NULL` |
| `units_sold` | `integer` | `NO` | `NULL` |
| `net_sales` | `numeric` | `NO` | `'0'::numeric` |
| `food_cost` | `numeric` | `NO` | `'0'::numeric` |
| `contribution` | `numeric` | `NO` | `'0'::numeric` |
| `avg_price` | `numeric` | `NO` | `'0'::numeric` |
| `avg_cost` | `numeric` | `NO` | `'0'::numeric` |
| `margin_pct` | `numeric` | `NO` | `'0'::numeric` |
| `popularity_index` | `numeric` | `NO` | `'0'::numeric` |
| `classification` | `character varying` | `YES` | `NULL` |
| `metadata` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.menu_item_sync_map
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('menu_item_sync_map_id_seq'::regclass)` |
| `menu_item_id` | `bigint` | `NO` | `NULL` |
| `pos_identifier` | `character varying` | `NO` | `NULL` |
| `channel` | `character varying` | `NO` | `'pos'::character varying` |
| `metadata` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.menu_items
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('menu_items_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `YES` | `NULL` |
| `plu` | `character varying` | `NO` | `NULL` |
| `name` | `character varying` | `NO` | `NULL` |
| `category` | `character varying` | `YES` | `NULL` |
| `active` | `boolean` | `NO` | `true` |
| `metadata` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.merma
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('merma_id_seq'::regclass)` |
| `ts` | `timestamp without time zone` | `NO` | `now()` |
| `tipo` | `USER-DEFINED` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `batch_id` | `bigint` | `YES` | `NULL` |
| `op_id` | `bigint` | `YES` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `um_id` | `integer` | `NO` | `NULL` |
| `usuario_id` | `bigint` | `YES` | `NULL` |
| `motivo` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.migrations
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('migrations_id_seq'::regclass)` |
| `migration` | `character varying` | `NO` | `NULL` |
| `batch` | `integer` | `NO` | `NULL` |

### TABLA: selemti.model_has_permissions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `permission_id` | `bigint` | `NO` | `NULL` |
| `model_type` | `character varying` | `NO` | `NULL` |
| `model_id` | `bigint` | `NO` | `NULL` |

### TABLA: selemti.model_has_roles
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `role_id` | `bigint` | `NO` | `NULL` |
| `model_type` | `character varying` | `NO` | `NULL` |
| `model_id` | `bigint` | `NO` | `NULL` |

### TABLA: selemti.modificadores_pos
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('modificadores_pos_id_seq'::regclass)` |
| `codigo_pos` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `tipo` | `character varying` | `YES` | `NULL` |
| `precio_extra` | `numeric` | `YES` | `NULL` |
| `receta_modificador_id` | `character varying` | `YES` | `NULL` |
| `activo` | `boolean` | `YES` | `true` |

### TABLA: selemti.mov_inv
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('mov_inv_id_seq'::regclass)` |
| `ts` | `timestamp without time zone` | `NO` | `now()` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `lote_id` | `integer` | `YES` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `qty_original` | `numeric` | `YES` | `NULL` |
| `uom_original_id` | `integer` | `YES` | `NULL` |
| `costo_unit` | `numeric` | `YES` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `ref_tipo` | `character varying` | `YES` | `NULL` |
| `ref_id` | `bigint` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `usuario_id` | `integer` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.op_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('op_cab_id_seq'::regclass)` |
| `sucursal_id` | `bigint` | `NO` | `NULL` |
| `receta_version_id` | `bigint` | `NO` | `NULL` |
| `cantidad_objetivo` | `numeric` | `NO` | `NULL` |
| `um_salida_id` | `integer` | `NO` | `NULL` |
| `estado` | `USER-DEFINED` | `NO` | `'ABIERTA'::op_estado` |
| `ts_apertura` | `timestamp without time zone` | `NO` | `now()` |
| `ts_cierre` | `timestamp without time zone` | `YES` | `NULL` |
| `usuario_abre` | `bigint` | `YES` | `NULL` |
| `usuario_cierra` | `bigint` | `YES` | `NULL` |
| `lote_salida_id` | `bigint` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.op_insumo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('op_insumo_id_seq'::regclass)` |
| `op_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `qty_teorica` | `numeric` | `NO` | `NULL` |
| `qty_real` | `numeric` | `YES` | `NULL` |
| `um_id` | `integer` | `NO` | `NULL` |
| `batch_id` | `bigint` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.op_produccion_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('op_produccion_cab_id_seq'::regclass)` |
| `receta_version_id` | `integer` | `NO` | `NULL` |
| `cantidad_planeada` | `numeric` | `NO` | `NULL` |
| `cantidad_real` | `numeric` | `YES` | `NULL` |
| `fecha_produccion` | `date` | `NO` | `NULL` |
| `estado` | `character varying` | `YES` | `'PENDIENTE'::character varying` |
| `lote_resultado` | `character varying` | `YES` | `NULL` |
| `usuario_responsable` | `integer` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.op_yield
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `op_id` | `bigint` | `NO` | `NULL` |
| `cantidad_real` | `numeric` | `NO` | `NULL` |
| `merma_real` | `numeric` | `NO` | `NULL` |
| `evidencia_url` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |

### TABLA: selemti.overhead_definitions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('overhead_definitions_id_seq'::regclass)` |
| `clave` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `tipo` | `character varying` | `NO` | `'fixed_per_batch'::character varying` |
| `tasa` | `numeric` | `NO` | `'0'::numeric` |
| `activo` | `boolean` | `NO` | `true` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.param_sucursal
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('param_sucursal_id_seq'::regclass)` |
| `sucursal_id` | `text` | `NO` | `NULL` |
| `consumo` | `USER-DEFINED` | `NO` | `'FEFO'::consumo_policy` |
| `tolerancia_precorte_pct` | `numeric` | `YES` | `0.02` |
| `tolerancia_corte_abs` | `numeric` | `YES` | `50.0` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |
| `updated_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.password_reset_tokens
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `email` | `character varying` | `NO` | `NULL` |
| `token` | `character varying` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.perdida_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('perdida_log_id_seq'::regclass)` |
| `ts` | `timestamp without time zone` | `NO` | `now()` |
| `item_id` | `text` | `NO` | `NULL` |
| `lote_id` | `bigint` | `YES` | `NULL` |
| `sucursal_id` | `text` | `YES` | `NULL` |
| `clase` | `USER-DEFINED` | `NO` | `NULL` |
| `motivo` | `text` | `YES` | `NULL` |
| `qty_canonica` | `numeric` | `NO` | `NULL` |
| `qty_original` | `numeric` | `YES` | `NULL` |
| `uom_original_id` | `integer` | `YES` | `NULL` |
| `evidencia_url` | `text` | `YES` | `NULL` |
| `usuario_id` | `integer` | `YES` | `NULL` |
| `ref_tipo` | `text` | `YES` | `NULL` |
| `ref_id` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.permissions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('permissions_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `NULL` |
| `guard_name` | `character varying` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.personal_access_tokens
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('personal_access_tokens_id_seq'::regclass)` |
| `tokenable_type` | `character varying` | `NO` | `NULL` |
| `tokenable_id` | `bigint` | `NO` | `NULL` |
| `name` | `character varying` | `NO` | `NULL` |
| `token` | `character varying` | `NO` | `NULL` |
| `abilities` | `text` | `YES` | `NULL` |
| `last_used_at` | `timestamp without time zone` | `YES` | `NULL` |
| `expires_at` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.pos_map
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `pos_system` | `text` | `NO` | `NULL` |
| `plu` | `text` | `NO` | `NULL` |
| `tipo` | `text` | `NO` | `NULL` |
| `receta_id` | `text` | `YES` | `NULL` |
| `receta_version_id` | `integer` | `YES` | `NULL` |
| `valid_from` | `date` | `NO` | `NULL` |
| `valid_to` | `date` | `YES` | `NULL` |
| `sys_from` | `timestamp without time zone` | `NO` | `now()` |
| `sys_to` | `timestamp without time zone` | `YES` | `NULL` |
| `meta` | `json` | `YES` | `NULL` |
| `vigente_desde` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.pos_modifiers_map
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `NO` | `gen_random_uuid()` |
| `pos_modifier_code` | `text` | `NO` | `NULL` |
| `name` | `text` | `YES` | `NULL` |
| `effect` | `USER-DEFINED` | `NO` | `NULL` |
| `linked_recipe_id` | `uuid` | `YES` | `NULL` |
| `linked_recipe_version_id` | `uuid` | `YES` | `NULL` |
| `delta_qty_canonical` | `numeric` | `YES` | `NULL` |
| `canonical_uom_id` | `uuid` | `YES` | `NULL` |
| `delta_cost` | `numeric` | `YES` | `NULL` |
| `active` | `boolean` | `NO` | `true` |
| `valid_from` | `date` | `NO` | `('now'::text)::date` |
| `valid_to` | `date` | `YES` | `NULL` |
| `notes` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `NO` | `now()` |
| `updated_at` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.pos_reprocess_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('pos_reprocess_log_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `user_id` | `bigint` | `NO` | `NULL` |
| `reprocessed_at` | `timestamp without time zone` | `NO` | `now()` |
| `motivo` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.pos_reverse_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('pos_reverse_log_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `user_id` | `bigint` | `NO` | `NULL` |
| `reversed_at` | `timestamp without time zone` | `NO` | `now()` |
| `motivo` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.pos_sync_batches
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('pos_sync_batches_id_seq'::regclass)` |
| `source_system` | `character varying` | `NO` | `NULL` |
| `status` | `character varying` | `NO` | `'pending'::character varying` |
| `started_at` | `timestamp with time zone` | `YES` | `NULL` |
| `finished_at` | `timestamp with time zone` | `YES` | `NULL` |
| `rows_processed` | `integer` | `NO` | `NULL` |
| `rows_successful` | `integer` | `NO` | `NULL` |
| `rows_failed` | `integer` | `NO` | `NULL` |
| `metadata` | `jsonb` | `YES` | `NULL` |
| `errors` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.pos_sync_logs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('pos_sync_logs_id_seq'::regclass)` |
| `batch_id` | `bigint` | `NO` | `NULL` |
| `external_id` | `character varying` | `YES` | `NULL` |
| `action` | `character varying` | `NO` | `NULL` |
| `status` | `character varying` | `NO` | `NULL` |
| `payload` | `jsonb` | `YES` | `NULL` |
| `message` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.postcorte
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('postcorte_id_seq'::regclass)` |
| `sesion_id` | `bigint` | `NO` | `NULL` |
| `sistema_efectivo_esperado` | `numeric` | `NO` | `NULL` |
| `declarado_efectivo` | `numeric` | `NO` | `NULL` |
| `diferencia_efectivo` | `numeric` | `NO` | `NULL` |
| `veredicto_efectivo` | `text` | `NO` | `'CUADRA'::text` |
| `sistema_tarjetas` | `numeric` | `NO` | `NULL` |
| `declarado_tarjetas` | `numeric` | `NO` | `NULL` |
| `diferencia_tarjetas` | `numeric` | `NO` | `NULL` |
| `veredicto_tarjetas` | `text` | `NO` | `'CUADRA'::text` |
| `creado_en` | `timestamp with time zone` | `NO` | `now()` |
| `creado_por` | `integer` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `sistema_transferencias` | `numeric` | `NO` | `NULL` |
| `declarado_transferencias` | `numeric` | `NO` | `NULL` |
| `diferencia_transferencias` | `numeric` | `NO` | `NULL` |
| `veredicto_transferencias` | `text` | `NO` | `'CUADRA'::text` |
| `validado` | `boolean` | `NO` | `false` |
| `validado_por` | `integer` | `YES` | `NULL` |
| `validado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `requiere_aprobacion` | `boolean` | `YES` | `false` |
| `aprobado_por` | `integer` | `YES` | `NULL` |
| `aprobado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `motivo_irregular` | `text` | `YES` | `NULL` |
| `rechazado` | `boolean` | `YES` | `false` |
| `motivo_rechazo` | `text` | `YES` | `NULL` |

### TABLA: selemti.precorte
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('precorte_id_seq'::regclass)` |
| `sesion_id` | `bigint` | `NO` | `NULL` |
| `declarado_efectivo` | `numeric` | `NO` | `NULL` |
| `declarado_otros` | `numeric` | `NO` | `NULL` |
| `estatus` | `text` | `NO` | `'PENDIENTE'::text` |
| `creado_en` | `timestamp with time zone` | `NO` | `now()` |
| `creado_por` | `integer` | `YES` | `NULL` |
| `ip_cliente` | `inet` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |

### TABLA: selemti.precorte_efectivo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('precorte_efectivo_id_seq'::regclass)` |
| `precorte_id` | `bigint` | `NO` | `NULL` |
| `denominacion` | `numeric` | `NO` | `NULL` |
| `cantidad` | `integer` | `NO` | `NULL` |
| `subtotal` | `numeric` | `NO` | `NULL` |

### TABLA: selemti.precorte_otros
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('precorte_otros_id_seq'::regclass)` |
| `precorte_id` | `bigint` | `NO` | `NULL` |
| `tipo` | `text` | `NO` | `NULL` |
| `monto` | `numeric` | `NO` | `NULL` |
| `referencia` | `text` | `YES` | `NULL` |
| `evidencia_url` | `text` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `creado_en` | `timestamp with time zone` | `NO` | `now()` |

### TABLA: selemti.prod_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('prod_cab_id_seq'::regclass)` |
| `sol_id` | `bigint` | `YES` | `NULL` |
| `fecha_programada` | `date` | `NO` | `NULL` |
| `estado` | `character varying` | `NO` | `'PROGRAMADA'::character varying` |
| `creada_por` | `integer` | `NO` | `NULL` |
| `aprobada_por` | `integer` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.prod_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('prod_det_id_seq'::regclass)` |
| `prod_id` | `bigint` | `YES` | `NULL` |
| `sr_id` | `integer` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `rendimiento` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.production_order_inputs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('production_order_inputs_id_seq'::regclass)` |
| `production_order_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `inventory_batch_id` | `bigint` | `YES` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.production_order_outputs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('production_order_outputs_id_seq'::regclass)` |
| `production_order_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `inventory_batch_id` | `bigint` | `YES` | `NULL` |
| `lote_producido` | `character varying` | `YES` | `NULL` |
| `fecha_caducidad` | `date` | `YES` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.production_orders
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('production_orders_id_seq'::regclass)` |
| `folio` | `character varying` | `YES` | `NULL` |
| `recipe_id` | `bigint` | `YES` | `NULL` |
| `item_id` | `character varying` | `YES` | `NULL` |
| `qty_programada` | `numeric` | `NO` | `'0'::numeric` |
| `qty_producida` | `numeric` | `NO` | `'0'::numeric` |
| `qty_merma` | `numeric` | `NO` | `'0'::numeric` |
| `uom_base` | `character varying` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `almacen_id` | `character varying` | `YES` | `NULL` |
| `programado_para` | `timestamp with time zone` | `YES` | `NULL` |
| `iniciado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `cerrado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'BORRADOR'::character varying` |
| `creado_por` | `bigint` | `YES` | `NULL` |
| `aprobado_por` | `bigint` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.proveedor
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `rfc` | `text` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |

### TABLA: selemti.purchase_documents
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_documents_id_seq'::regclass)` |
| `request_id` | `bigint` | `YES` | `NULL` |
| `quote_id` | `bigint` | `YES` | `NULL` |
| `order_id` | `bigint` | `YES` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `file_url` | `character varying` | `NO` | `NULL` |
| `uploaded_by` | `bigint` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_order_lines
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_order_lines_id_seq'::regclass)` |
| `order_id` | `bigint` | `NO` | `NULL` |
| `request_line_id` | `bigint` | `YES` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `precio_unitario` | `numeric` | `NO` | `NULL` |
| `descuento` | `numeric` | `NO` | `'0'::numeric` |
| `impuestos` | `numeric` | `NO` | `'0'::numeric` |
| `total` | `numeric` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_orders
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_orders_id_seq'::regclass)` |
| `folio` | `character varying` | `YES` | `NULL` |
| `quote_id` | `bigint` | `YES` | `NULL` |
| `vendor_id` | `bigint` | `NO` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'BORRADOR'::character varying` |
| `fecha_promesa` | `date` | `YES` | `NULL` |
| `subtotal` | `numeric` | `NO` | `'0'::numeric` |
| `descuento` | `numeric` | `NO` | `'0'::numeric` |
| `impuestos` | `numeric` | `NO` | `'0'::numeric` |
| `total` | `numeric` | `NO` | `'0'::numeric` |
| `creado_por` | `bigint` | `NO` | `NULL` |
| `aprobado_por` | `bigint` | `YES` | `NULL` |
| `aprobado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_request_lines
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_request_lines_id_seq'::regclass)` |
| `request_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `fecha_requerida` | `date` | `YES` | `NULL` |
| `preferred_vendor_id` | `bigint` | `YES` | `NULL` |
| `last_price` | `numeric` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'PENDIENTE'::character varying` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_requests
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_requests_id_seq'::regclass)` |
| `folio` | `character varying` | `YES` | `NULL` |
| `sucursal_id` | `character varying` | `YES` | `NULL` |
| `created_by` | `bigint` | `NO` | `NULL` |
| `requested_by` | `bigint` | `YES` | `NULL` |
| `requested_at` | `timestamp with time zone` | `NO` | `now()` |
| `estado` | `character varying` | `NO` | `'BORRADOR'::character varying` |
| `importe_estimado` | `numeric` | `NO` | `'0'::numeric` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |
| `fecha_requerida` | `date` | `YES` | `NULL` |
| `almacen_destino_id` | `bigint` | `YES` | `NULL` |
| `justificacion` | `text` | `YES` | `NULL` |
| `urgente` | `boolean` | `NO` | `false` |
| `origen_suggestion_id` | `bigint` | `YES` | `NULL` |

### TABLA: selemti.purchase_suggestion_lines
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_suggestion_lines_id_seq'::regclass)` |
| `suggestion_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `stock_actual` | `numeric` | `NO` | `'0'::numeric` |
| `stock_min` | `numeric` | `NO` | `NULL` |
| `stock_max` | `numeric` | `NO` | `NULL` |
| `reorder_point` | `numeric` | `YES` | `NULL` |
| `consumo_promedio_diario` | `numeric` | `NO` | `'0'::numeric` |
| `dias_cobertura_actual` | `integer` | `NO` | `NULL` |
| `demanda_proyectada` | `numeric` | `NO` | `'0'::numeric` |
| `qty_sugerida` | `numeric` | `NO` | `NULL` |
| `qty_ajustada` | `numeric` | `YES` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `costo_unitario_estimado` | `numeric` | `YES` | `NULL` |
| `costo_total_linea` | `numeric` | `YES` | `NULL` |
| `proveedor_sugerido_id` | `bigint` | `YES` | `NULL` |
| `ultimo_precio_compra` | `numeric` | `YES` | `NULL` |
| `fecha_ultima_compra` | `date` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_suggestions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_suggestions_id_seq'::regclass)` |
| `folio` | `character varying` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `YES` | `NULL` |
| `almacen_id` | `bigint` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'PENDIENTE'::character varying` |
| `prioridad` | `character varying` | `NO` | `'NORMAL'::character varying` |
| `origen` | `character varying` | `NO` | `'AUTO'::character varying` |
| `total_items` | `integer` | `NO` | `NULL` |
| `total_estimado` | `numeric` | `NO` | `'0'::numeric` |
| `sugerido_en` | `timestamp without time zone` | `NO` | `now()` |
| `sugerido_por_user_id` | `bigint` | `YES` | `NULL` |
| `revisado_por_user_id` | `bigint` | `YES` | `NULL` |
| `revisado_en` | `timestamp without time zone` | `YES` | `NULL` |
| `convertido_a_request_id` | `bigint` | `YES` | `NULL` |
| `convertido_en` | `timestamp without time zone` | `YES` | `NULL` |
| `dias_analisis` | `integer` | `NO` | `7` |
| `consumo_promedio_calculado` | `boolean` | `NO` | `true` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_vendor_quote_lines
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_vendor_quote_lines_id_seq'::regclass)` |
| `quote_id` | `bigint` | `NO` | `NULL` |
| `request_line_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `qty_oferta` | `numeric` | `NO` | `NULL` |
| `uom_oferta` | `character varying` | `NO` | `NULL` |
| `precio_unitario` | `numeric` | `NO` | `NULL` |
| `pack_size` | `numeric` | `NO` | `'1'::numeric` |
| `pack_uom` | `character varying` | `YES` | `NULL` |
| `monto_total` | `numeric` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.purchase_vendor_quotes
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('purchase_vendor_quotes_id_seq'::regclass)` |
| `request_id` | `bigint` | `NO` | `NULL` |
| `vendor_id` | `bigint` | `NO` | `NULL` |
| `folio_proveedor` | `character varying` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'RECIBIDA'::character varying` |
| `enviada_en` | `timestamp with time zone` | `NO` | `now()` |
| `recibida_en` | `timestamp with time zone` | `YES` | `NULL` |
| `subtotal` | `numeric` | `NO` | `'0'::numeric` |
| `descuento` | `numeric` | `NO` | `'0'::numeric` |
| `impuestos` | `numeric` | `NO` | `'0'::numeric` |
| `total` | `numeric` | `NO` | `'0'::numeric` |
| `capturada_por` | `bigint` | `YES` | `NULL` |
| `aprobada_por` | `bigint` | `YES` | `NULL` |
| `aprobada_en` | `timestamp with time zone` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.recalc_log
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recalc_log_id_seq'::regclass)` |
| `job_id` | `bigint` | `YES` | `NULL` |
| `step` | `text` | `YES` | `NULL` |
| `started_ts` | `timestamp without time zone` | `YES` | `NULL` |
| `ended_ts` | `timestamp without time zone` | `YES` | `NULL` |
| `ok` | `boolean` | `YES` | `NULL` |
| `details` | `json` | `YES` | `NULL` |

### TABLA: selemti.recepcion_adjuntos
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recepcion_adjuntos_id_seq'::regclass)` |
| `recepcion_id` | `bigint` | `NO` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `file_url` | `character varying` | `NO` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `uploaded_by` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.recepcion_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recepcion_cab_id_seq'::regclass)` |
| `sucursal_id` | `bigint` | `NO` | `NULL` |
| `proveedor_id` | `integer` | `YES` | `NULL` |
| `oc_ref` | `text` | `YES` | `NULL` |
| `ts` | `timestamp without time zone` | `NO` | `now()` |
| `usuario_id` | `bigint` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `almacen_id` | `character varying` | `YES` | `NULL` |
| `numero_recepcion` | `character varying` | `YES` | `NULL` |
| `fecha_recepcion` | `date` | `YES` | `NULL` |
| `estado` | `character varying` | `YES` | `NULL` |
| `total_presentaciones` | `numeric` | `YES` | `NULL` |
| `total_canonico` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |
| `validada_por` | `bigint` | `YES` | `NULL` |
| `validada_at` | `timestamp without time zone` | `YES` | `NULL` |
| `posteada_por` | `bigint` | `YES` | `NULL` |
| `posteada_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.recepcion_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recepcion_det_id_seq'::regclass)` |
| `recepcion_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `bodega_id` | `bigint` | `NO` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `um_id` | `integer` | `NO` | `NULL` |
| `costo_unit` | `numeric` | `NO` | `NULL` |
| `batch_id` | `bigint` | `YES` | `NULL` |
| `temperatura` | `numeric` | `YES` | `NULL` |
| `doc_url` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.receta
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('receta_id_seq'::regclass)` |
| `codigo` | `text` | `YES` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `porciones` | `numeric` | `NO` | `1.0` |
| `pvp_objetivo` | `numeric` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `meta` | `jsonb` | `YES` | `NULL` |

### TABLA: selemti.receta_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `character varying` | `NO` | `NULL` |
| `nombre_plato` | `character varying` | `NO` | `NULL` |
| `codigo_plato_pos` | `character varying` | `YES` | `NULL` |
| `categoria_plato` | `character varying` | `YES` | `NULL` |
| `porciones_standard` | `integer` | `YES` | `1` |
| `instrucciones_preparacion` | `text` | `YES` | `NULL` |
| `tiempo_preparacion_min` | `integer` | `YES` | `NULL` |
| `costo_standard_porcion` | `numeric` | `YES` | `NULL` |
| `precio_venta_sugerido` | `numeric` | `YES` | `NULL` |
| `activo` | `boolean` | `YES` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.receta_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('receta_det_id_seq'::regclass)` |
| `receta_version_id` | `integer` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `unidad_medida` | `character varying` | `NO` | `NULL` |
| `merma_porcentaje` | `numeric` | `YES` | `NULL` |
| `instrucciones_especificas` | `text` | `YES` | `NULL` |
| `orden` | `integer` | `YES` | `1` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.receta_insumo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('receta_insumo_id_seq'::regclass)` |
| `receta_version_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |

### TABLA: selemti.receta_shadow
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('receta_shadow_id_seq'::regclass)` |
| `codigo_plato_pos` | `character varying` | `NO` | `NULL` |
| `nombre_plato` | `character varying` | `NO` | `NULL` |
| `estado` | `character varying` | `YES` | `'INFERIDA'::character varying` |
| `confianza` | `numeric` | `YES` | `0.0` |
| `total_ventas_analizadas` | `integer` | `YES` | `NULL` |
| `fecha_primer_venta` | `date` | `YES` | `NULL` |
| `fecha_ultima_venta` | `date` | `YES` | `NULL` |
| `frecuencia_dias` | `numeric` | `YES` | `NULL` |
| `ingredientes_inferidos` | `json` | `YES` | `NULL` |
| `usuario_validador` | `integer` | `YES` | `NULL` |
| `fecha_validacion` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.receta_version
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('receta_version_id_seq'::regclass)` |
| `receta_id` | `character varying` | `NO` | `NULL` |
| `version` | `integer` | `NO` | `1` |
| `descripcion_cambios` | `text` | `YES` | `NULL` |
| `fecha_efectiva` | `date` | `NO` | `NULL` |
| `version_publicada` | `boolean` | `YES` | `false` |
| `usuario_publicador` | `integer` | `YES` | `NULL` |
| `fecha_publicacion` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.recipe_cost_history
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_cost_history_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `recipe_version_id` | `bigint` | `YES` | `NULL` |
| `snapshot_at` | `timestamp without time zone` | `NO` | `NULL` |
| `currency_code` | `character varying` | `YES` | `'MXN'::character varying` |
| `batch_cost` | `numeric` | `YES` | `NULL` |
| `portion_cost` | `numeric` | `YES` | `NULL` |
| `batch_size` | `numeric` | `YES` | `NULL` |
| `yield_portions` | `numeric` | `YES` | `NULL` |
| `notes` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.recipe_cost_snapshots
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_cost_snapshots_id_seq'::regclass)` |
| `recipe_id` | `character varying` | `NO` | `NULL` |
| `snapshot_date` | `timestamp without time zone` | `NO` | `NULL` |
| `cost_total` | `numeric` | `NO` | `NULL` |
| `cost_per_portion` | `numeric` | `NO` | `NULL` |
| `portions` | `numeric` | `NO` | `1` |
| `cost_breakdown` | `jsonb` | `NO` | `'[]'::jsonb` |
| `reason` | `character varying` | `NO` | `NULL` |
| `created_by_user_id` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.recipe_extended_cost_history
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_extended_cost_history_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `snapshot_at` | `timestamp with time zone` | `NO` | `now()` |
| `mp_batch_cost` | `numeric` | `NO` | `'0'::numeric` |
| `labor_batch_cost` | `numeric` | `NO` | `'0'::numeric` |
| `overhead_batch_cost` | `numeric` | `NO` | `'0'::numeric` |
| `total_batch_cost` | `numeric` | `NO` | `'0'::numeric` |
| `portion_cost` | `numeric` | `NO` | `'0'::numeric` |
| `yield_portions` | `numeric` | `NO` | `'0'::numeric` |
| `breakdown` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.recipe_labor_steps
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_labor_steps_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `labor_role_id` | `bigint` | `YES` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `duracion_minutos` | `numeric` | `NO` | `'0'::numeric` |
| `costo_manual` | `numeric` | `YES` | `NULL` |
| `orden` | `integer` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.recipe_overhead_allocations
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_overhead_allocations_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `overhead_id` | `bigint` | `NO` | `NULL` |
| `valor` | `numeric` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.recipe_version_items
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_version_items_id_seq'::regclass)` |
| `recipe_version_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `uom_receta` | `character varying` | `NO` | `NULL` |

### TABLA: selemti.recipe_versions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('recipe_versions_id_seq'::regclass)` |
| `recipe_id` | `bigint` | `NO` | `NULL` |
| `version_no` | `integer` | `NO` | `NULL` |
| `notes` | `text` | `YES` | `NULL` |
| `valid_from` | `timestamp without time zone` | `NO` | `now()` |
| `valid_to` | `timestamp without time zone` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.replenishment_suggestions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('replenishment_suggestions_id_seq'::regclass)` |
| `folio` | `character varying` | `YES` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `prioridad` | `character varying` | `NO` | `'NORMAL'::character varying` |
| `origen` | `character varying` | `NO` | `'AUTO'::character varying` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `YES` | `NULL` |
| `almacen_id` | `bigint` | `YES` | `NULL` |
| `stock_actual` | `numeric` | `NO` | `NULL` |
| `stock_min` | `numeric` | `NO` | `NULL` |
| `stock_max` | `numeric` | `NO` | `NULL` |
| `qty_sugerida` | `numeric` | `NO` | `NULL` |
| `qty_aprobada` | `numeric` | `YES` | `NULL` |
| `uom` | `character varying` | `NO` | `NULL` |
| `consumo_promedio_diario` | `numeric` | `YES` | `NULL` |
| `dias_stock_restante` | `integer` | `YES` | `NULL` |
| `fecha_agotamiento_estimada` | `date` | `YES` | `NULL` |
| `estado` | `character varying` | `NO` | `'PENDIENTE'::character varying` |
| `purchase_request_id` | `bigint` | `YES` | `NULL` |
| `production_order_id` | `bigint` | `YES` | `NULL` |
| `sugerido_en` | `timestamp with time zone` | `NO` | `now()` |
| `revisado_en` | `timestamp with time zone` | `YES` | `NULL` |
| `revisado_por` | `bigint` | `YES` | `NULL` |
| `convertido_en` | `timestamp with time zone` | `YES` | `NULL` |
| `caduca_en` | `timestamp with time zone` | `YES` | `NULL` |
| `motivo` | `text` | `YES` | `NULL` |
| `motivo_rechazo` | `text` | `YES` | `NULL` |
| `notas` | `text` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.report_definitions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('report_definitions_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `NULL` |
| `slug` | `character varying` | `NO` | `NULL` |
| `category` | `character varying` | `YES` | `NULL` |
| `config` | `jsonb` | `NO` | `NULL` |
| `is_system` | `boolean` | `NO` | `false` |
| `created_by` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.report_favorites
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('report_favorites_id_seq'::regclass)` |
| `user_id` | `bigint` | `NO` | `NULL` |
| `report_key` | `character varying` | `NO` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.report_runs
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('report_runs_id_seq'::regclass)` |
| `report_id` | `bigint` | `NO` | `NULL` |
| `requested_by` | `bigint` | `YES` | `NULL` |
| `status` | `character varying` | `NO` | `'pending'::character varying` |
| `filters` | `jsonb` | `YES` | `NULL` |
| `result_meta` | `jsonb` | `YES` | `NULL` |
| `storage_path` | `character varying` | `YES` | `NULL` |
| `queued_at` | `timestamp with time zone` | `YES` | `NULL` |
| `started_at` | `timestamp with time zone` | `YES` | `NULL` |
| `finished_at` | `timestamp with time zone` | `YES` | `NULL` |
| `created_at` | `timestamp with time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp with time zone` | `YES` | `NULL` |

### TABLA: selemti.rol
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('rol_id_seq'::regclass)` |
| `codigo` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |

### TABLA: selemti.role_has_permissions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `permission_id` | `bigint` | `NO` | `NULL` |
| `role_id` | `bigint` | `NO` | `NULL` |

### TABLA: selemti.roles
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('roles_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `NULL` |
| `guard_name` | `character varying` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |
| `display_name` | `character varying` | `YES` | `NULL` |
| `description` | `text` | `YES` | `NULL` |
| `color` | `character varying` | `YES` | `NULL` |

### TABLA: selemti.sesion_cajon
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('sesion_cajon_id_seq'::regclass)` |
| `sucursal` | `text` | `YES` | `NULL` |
| `terminal_id` | `integer` | `NO` | `NULL` |
| `terminal_nombre` | `text` | `YES` | `NULL` |
| `cajero_usuario_id` | `integer` | `NO` | `NULL` |
| `apertura_ts` | `timestamp with time zone` | `NO` | `now()` |
| `cierre_ts` | `timestamp with time zone` | `YES` | `NULL` |
| `estatus` | `text` | `NO` | `'ACTIVA'::text` |
| `opening_float` | `numeric` | `NO` | `NULL` |
| `closing_float` | `numeric` | `YES` | `NULL` |
| `dah_evento_id` | `integer` | `YES` | `NULL` |
| `skipped_precorte` | `boolean` | `NO` | `false` |

### TABLA: selemti.sessions
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `character varying` | `NO` | `NULL` |
| `user_id` | `bigint` | `YES` | `NULL` |
| `ip_address` | `character varying` | `YES` | `NULL` |
| `user_agent` | `text` | `YES` | `NULL` |
| `payload` | `text` | `NO` | `NULL` |
| `last_activity` | `integer` | `NO` | `NULL` |

### TABLA: selemti.sol_prod_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('sol_prod_cab_id_seq'::regclass)` |
| `sucursal_id` | `integer` | `NO` | `NULL` |
| `fecha` | `date` | `NO` | `('now'::text)::date` |
| `estado` | `character varying` | `NO` | `'SOLICITADA'::character varying` |
| `solicitada_por` | `integer` | `NO` | `NULL` |
| `autorizada_por` | `integer` | `YES` | `NULL` |
| `observaciones` | `text` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.sol_prod_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('sol_prod_det_id_seq'::regclass)` |
| `sol_id` | `bigint` | `YES` | `NULL` |
| `plu` | `integer` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `cantidad_autorizada` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.stock_policy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('stock_policy_id_seq'::regclass)` |
| `item_id` | `text` | `NO` | `NULL` |
| `sucursal_id` | `text` | `NO` | `NULL` |
| `almacen_id` | `text` | `YES` | `NULL` |
| `min_qty` | `numeric` | `NO` | `NULL` |
| `max_qty` | `numeric` | `NO` | `NULL` |
| `reorder_lote` | `numeric` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.sucursal
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |

### TABLA: selemti.sucursal_almacen_terminal
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('sucursal_almacen_terminal_id_seq'::regclass)` |
| `sucursal_id` | `text` | `NO` | `NULL` |
| `almacen_id` | `text` | `NO` | `NULL` |
| `terminal_id` | `integer` | `YES` | `NULL` |
| `location` | `text` | `YES` | `NULL` |
| `descripcion` | `text` | `YES` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |

### TABLA: selemti.ticket_det_consumo
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('ticket_det_consumo_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `ticket_det_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `text` | `NO` | `NULL` |
| `lote_id` | `bigint` | `YES` | `NULL` |
| `qty_canonica` | `numeric` | `NO` | `NULL` |
| `qty_original` | `numeric` | `YES` | `NULL` |
| `uom_original_id` | `integer` | `YES` | `NULL` |
| `sucursal_id` | `text` | `YES` | `NULL` |
| `ref_tipo` | `text` | `YES` | `NULL` |
| `ref_id` | `bigint` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.ticket_item_modifiers
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('ticket_item_modifiers_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `ticket_item_id` | `bigint` | `NO` | `NULL` |
| `sucursal_id` | `bigint` | `YES` | `NULL` |
| `terminal_id` | `bigint` | `YES` | `NULL` |
| `procesado` | `boolean` | `NO` | `false` |
| `fecha_proceso` | `timestamp without time zone` | `YES` | `NULL` |
| `pos_code` | `character varying` | `YES` | `NULL` |
| `recipe_version_id` | `bigint` | `YES` | `NULL` |
| `precio_extra` | `numeric` | `NO` | `'0'::numeric` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.ticket_venta_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('ticket_venta_cab_id_seq'::regclass)` |
| `numero_ticket` | `character varying` | `NO` | `NULL` |
| `fecha_venta` | `timestamp without time zone` | `NO` | `now()` |
| `sucursal_id` | `character varying` | `NO` | `NULL` |
| `terminal_id` | `integer` | `YES` | `NULL` |
| `total_venta` | `numeric` | `YES` | `NULL` |
| `estado` | `character varying` | `YES` | `'ABIERTO'::character varying` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.ticket_venta_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('ticket_venta_det_id_seq'::regclass)` |
| `ticket_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `precio_unitario` | `numeric` | `NO` | `NULL` |
| `subtotal` | `numeric` | `NO` | `NULL` |
| `receta_version_id` | `integer` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `receta_shadow_id` | `integer` | `YES` | `NULL` |
| `reprocesado` | `boolean` | `YES` | `false` |
| `version_reproceso` | `integer` | `YES` | `1` |
| `modificadores_aplicados` | `json` | `YES` | `NULL` |

### TABLA: selemti.transfer_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('transfer_cab_id_seq'::regclass)` |
| `origen_almacen_id` | `integer` | `NO` | `NULL` |
| `destino_almacen_id` | `integer` | `NO` | `NULL` |
| `estado` | `character varying` | `NO` | `'CREADA'::character varying` |
| `creada_por` | `integer` | `NO` | `NULL` |
| `despachada_por` | `integer` | `YES` | `NULL` |
| `recibida_por` | `integer` | `YES` | `NULL` |
| `guia` | `character varying` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.transfer_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('transfer_det_id_seq'::regclass)` |
| `transfer_id` | `bigint` | `YES` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `cantidad` | `numeric` | `NO` | `NULL` |
| `cantidad_despachada` | `numeric` | `YES` | `NULL` |
| `cantidad_recibida` | `numeric` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.traspaso_cab
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('traspaso_cab_id_seq'::regclass)` |
| `from_bodega_id` | `bigint` | `NO` | `NULL` |
| `to_bodega_id` | `bigint` | `NO` | `NULL` |
| `ts` | `timestamp without time zone` | `NO` | `now()` |
| `usuario_id` | `bigint` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |
| `validada_por` | `bigint` | `YES` | `NULL` |
| `validada_at` | `timestamp without time zone` | `YES` | `NULL` |
| `posteada_por` | `bigint` | `YES` | `NULL` |
| `posteada_at` | `timestamp without time zone` | `YES` | `NULL` |
| `estado` | `character varying` | `YES` | `'SOLICITADA'::character varying` |
| `despachada_por` | `integer` | `YES` | `NULL` |
| `despachada_at` | `timestamp without time zone` | `YES` | `NULL` |
| `guia` | `character varying` | `YES` | `NULL` |
| `recibida_por` | `integer` | `YES` | `NULL` |
| `recibida_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.traspaso_det
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('traspaso_det_id_seq'::regclass)` |
| `traspaso_id` | `bigint` | `NO` | `NULL` |
| `item_id` | `character varying` | `NO` | `NULL` |
| `batch_id` | `bigint` | `YES` | `NULL` |
| `qty` | `numeric` | `NO` | `NULL` |
| `um_id` | `integer` | `NO` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |
| `updated_at` | `timestamp without time zone` | `YES` | `now()` |
| `deleted_at` | `timestamp without time zone` | `YES` | `NULL` |
| `cantidad_despachada` | `numeric` | `YES` | `NULL` |
| `cantidad_recibida` | `numeric` | `YES` | `NULL` |

### TABLA: selemti.unidad_medida_legacy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('unidad_medida_id_seq'::regclass)` |
| `codigo` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `tipo` | `text` | `NO` | `NULL` |
| `es_base` | `boolean` | `NO` | `false` |
| `factor_a_base` | `numeric` | `NO` | `1.0` |
| `decimales` | `integer` | `NO` | `2` |

### TABLA: selemti.unidades_medida_legacy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('unidades_medida_id_seq'::regclass)` |
| `codigo` | `character varying` | `NO` | `NULL` |
| `nombre` | `character varying` | `NO` | `NULL` |
| `tipo` | `character varying` | `NO` | `NULL` |
| `categoria` | `character varying` | `YES` | `NULL` |
| `es_base` | `boolean` | `YES` | `false` |
| `factor_conversion_base` | `numeric` | `YES` | `1.0` |
| `decimales` | `integer` | `YES` | `2` |
| `created_at` | `timestamp without time zone` | `YES` | `now()` |

### TABLA: selemti.uom_conversion_legacy
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('uom_conversion_id_seq'::regclass)` |
| `origen_id` | `integer` | `NO` | `NULL` |
| `destino_id` | `integer` | `NO` | `NULL` |
| `factor` | `numeric` | `NO` | `NULL` |

### TABLA: selemti.user_roles
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `user_id` | `integer` | `NO` | `NULL` |
| `role_id` | `character varying` | `NO` | `NULL` |
| `assigned_at` | `timestamp without time zone` | `YES` | `now()` |
| `assigned_by` | `integer` | `YES` | `NULL` |

### TABLA: selemti.users
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('users_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `NULL` |
| `email` | `character varying` | `NO` | `NULL` |
| `email_verified_at` | `timestamp without time zone` | `YES` | `NULL` |
| `password` | `character varying` | `NO` | `NULL` |
| `remember_token` | `character varying` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `YES` | `NULL` |
| `updated_at` | `timestamp without time zone` | `YES` | `NULL` |

### TABLA: selemti.usuario
| Columna | Tipo | Null | Default |
| :--- | :--- | :--- | :--- |
| `id` | `bigint` | `NO` | `nextval('usuario_id_seq'::regclass)` |
| `username` | `text` | `NO` | `NULL` |
| `nombre` | `text` | `NO` | `NULL` |
| `email` | `text` | `YES` | `NULL` |
| `rol_id` | `integer` | `NO` | `NULL` |
| `activo` | `boolean` | `NO` | `true` |
| `password_hash` | `text` | `YES` | `NULL` |
| `floreant_user_id` | `integer` | `YES` | `NULL` |
| `meta` | `jsonb` | `YES` | `NULL` |
| `created_at` | `timestamp without time zone` | `NO` | `now()` |

## FUNCIONES PL/pgSQL
- **fn_dah_corregido**
- **audit_trigger_func**
- **cerrar_lote_preparado**
- **fn_after_price_insert_alert**
- **fn_assign_item_code**
- **fn_confirmar_consumo_ticket**
- **fn_dah_after_insert_refuerzo**
- **fn_dah_after_insert_safe**
- **fn_fondo_actual**
- **fn_gen_cat_codigo**
- **fn_item_unit_cost_at**
- **fn_ivp_upsert_close_prev**
- **fn_normalizar_forma_pago**
- **fn_precorte_after_insert**
- **fn_precorte_after_update_aprobado**
- **fn_precorte_efectivo_bi**
- **fn_recipe_cost_at**
- **fn_recipes_using_item**
- **fn_reparar_sesion_apertura**
- **fn_reversar_consumo_ticket**
- **fn_slug**
- **fn_terminal_bu_snapshot_cierre**
- **fn_tx_after_insert_forma_pago**
- **fn_uom_factor**
- **inferir_recetas_de_ventas**
- **ingesta_ticket**
- **fn_dah_after_insert**
- **recalcular_costos_periodo**
- **refresh_materialized_views**
- **registrar_consumo_porcionado**
- **reprocesar_costos_historicos**
- **set_timestamp_ipp**
- **sp_snapshot_recipe_cost**
- **tg_invshot_autofill**
- **trg_ticket_inventory_consumption**
- **update_updated_at_column**
- **fn_dah_robusto**
- **fn_dah_simple**
- **fn_generar_postcorte**
- **fn_postcorte_after_insert**
- **fn_expandir_consumo_ticket**

## TRIGGERS
- **update_recepcion_cab_updated_at** en tabla **recepcion_cab**
- **trg_postcorte_after_insert** en tabla **postcorte**
- **trg_item_categories_autocode** en tabla **item_categories**
- **trg_items_assign_code** en tabla **items**
- **update_hist_cost_insumo_updated_at** en tabla **hist_cost_insumo**
- **update_insumo_presentacion_updated_at** en tabla **insumo_presentacion**
- **trg_invshot_biur** en tabla **inventory_snapshot**
- **trg_ipp_set_timestamp** en tabla **insumo_proveedor_presentacion**
- **update_insumo_proveedor_presentacion_updated_at** en tabla **insumo_proveedor_presentacion**
- **update_merma_updated_at** en tabla **merma**
- **trg_ivp_after_insert** en tabla **item_vendor_prices**
- **trg_ivp_close_prev** en tabla **item_vendor_prices**
- **update_op_cab_updated_at** en tabla **op_cab**
- **update_op_insumo_updated_at** en tabla **op_insumo**
- **trg_precorte_after_insert** en tabla **precorte**
- **trg_precorte_efectivo_bi** en tabla **precorte_efectivo**
- **update_recepcion_det_updated_at** en tabla **recepcion_det**
- **update_traspaso_cab_updated_at** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_a_478407** en tabla **users**
- **RI_ConstraintTrigger_a_478408** en tabla **users**
- **RI_ConstraintTrigger_a_478412** en tabla **postcorte**
- **RI_ConstraintTrigger_a_478413** en tabla **postcorte**
- **RI_ConstraintTrigger_c_478424** en tabla **almacen**
- **RI_ConstraintTrigger_c_478425** en tabla **almacen**
- **RI_ConstraintTrigger_c_478409** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_c_478410** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_c_478414** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_c_478415** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_a_478422** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478423** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478432** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478433** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_c_478429** en tabla **audit_log_global**
- **RI_ConstraintTrigger_c_478430** en tabla **audit_log_global**
- **RI_ConstraintTrigger_c_478434** en tabla **bodega**
- **RI_ConstraintTrigger_c_478435** en tabla **bodega**
- **RI_ConstraintTrigger_a_478437** en tabla **caja_fondo_mov**
- **RI_ConstraintTrigger_a_478438** en tabla **caja_fondo_mov**
- **RI_ConstraintTrigger_a_478442** en tabla **caja_fondo**
- **RI_ConstraintTrigger_a_478443** en tabla **caja_fondo**
- **RI_ConstraintTrigger_a_478447** en tabla **caja_fondo**
- **RI_ConstraintTrigger_a_478448** en tabla **caja_fondo**
- **RI_ConstraintTrigger_c_478439** en tabla **caja_fondo_adj**
- **RI_ConstraintTrigger_c_478440** en tabla **caja_fondo_adj**
- **RI_ConstraintTrigger_c_478444** en tabla **caja_fondo_arqueo**
- **RI_ConstraintTrigger_c_478445** en tabla **caja_fondo_arqueo**
- **update_traspaso_det_updated_at** en tabla **traspaso_det**
- **RI_ConstraintTrigger_a_478492** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478493** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478507** en tabla **postcorte**
- **RI_ConstraintTrigger_a_478508** en tabla **postcorte**
- **RI_ConstraintTrigger_a_478452** en tabla **caja_fondo**
- **RI_ConstraintTrigger_a_478453** en tabla **caja_fondo**
- **RI_ConstraintTrigger_c_478449** en tabla **caja_fondo_mov**
- **RI_ConstraintTrigger_c_478450** en tabla **caja_fondo_mov**
- **RI_ConstraintTrigger_c_478454** en tabla **caja_fondo_usuario**
- **RI_ConstraintTrigger_c_478455** en tabla **caja_fondo_usuario**
- **RI_ConstraintTrigger_a_478457** en tabla **cash_funds**
- **RI_ConstraintTrigger_a_478458** en tabla **cash_funds**
- **RI_ConstraintTrigger_c_478459** en tabla **cash_fund_arqueos**
- **RI_ConstraintTrigger_c_478460** en tabla **cash_fund_arqueos**
- **RI_ConstraintTrigger_c_478464** en tabla **cash_fund_arqueos**
- **RI_ConstraintTrigger_c_478465** en tabla **cash_fund_arqueos**
- **RI_ConstraintTrigger_c_478494** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478472** en tabla **cash_funds**
- **RI_ConstraintTrigger_a_478473** en tabla **cash_funds**
- **RI_ConstraintTrigger_c_478484** en tabla **cash_funds**
- **RI_ConstraintTrigger_c_478469** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_c_478470** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_c_478474** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_c_478475** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_c_478495** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_c_478499** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478500** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478504** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478505** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478479** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_c_478480** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_a_478497** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478498** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478502** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478503** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478512** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478513** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_c_478509** en tabla **conciliacion**
- **RI_ConstraintTrigger_c_478510** en tabla **conciliacion**
- **RI_ConstraintTrigger_a_478517** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478518** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478557** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478558** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478567** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478568** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478537** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478538** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478542** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478543** en tabla **cat_unidades**
- **RI_ConstraintTrigger_c_478539** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478540** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478544** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_c_478545** en tabla **cat_uom_conversion**
- **RI_ConstraintTrigger_a_478522** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478523** en tabla **inventory_batch**
- **RI_ConstraintTrigger_c_478514** en tabla **conversiones_unidad_legacy**
- **RI_ConstraintTrigger_c_478515** en tabla **conversiones_unidad_legacy**
- **RI_ConstraintTrigger_c_478519** en tabla **conversiones_unidad_legacy**
- **RI_ConstraintTrigger_c_478520** en tabla **conversiones_unidad_legacy**
- **RI_ConstraintTrigger_a_478527** en tabla **items**
- **RI_ConstraintTrigger_a_478528** en tabla **items**
- **RI_ConstraintTrigger_a_478547** en tabla **items**
- **RI_ConstraintTrigger_a_478548** en tabla **items**
- **RI_ConstraintTrigger_a_478552** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478553** en tabla **receta_cab**
- **RI_ConstraintTrigger_c_478524** en tabla **cost_layer**
- **RI_ConstraintTrigger_c_478525** en tabla **cost_layer**
- **RI_ConstraintTrigger_c_478529** en tabla **cost_layer**
- **RI_ConstraintTrigger_c_478530** en tabla **cost_layer**
- **RI_ConstraintTrigger_c_478549** en tabla **inventory_snapshot**
- **RI_ConstraintTrigger_c_478550** en tabla **inventory_snapshot**
- **RI_ConstraintTrigger_c_478554** en tabla **pos_map**
- **RI_ConstraintTrigger_c_478555** en tabla **pos_map**
- **RI_ConstraintTrigger_a_478572** en tabla **purchase_requests**
- **RI_ConstraintTrigger_a_478573** en tabla **purchase_requests**
- **RI_ConstraintTrigger_c_478559** en tabla **purchase_requests**
- **RI_ConstraintTrigger_c_478560** en tabla **purchase_requests**
- **RI_ConstraintTrigger_c_478564** en tabla **purchase_requests**
- **RI_ConstraintTrigger_a_478562** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_a_478563** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478569** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478570** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478574** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478575** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478624** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_478625** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_478629** en tabla **hist_cost_insumo**
- **RI_ConstraintTrigger_c_478630** en tabla **hist_cost_insumo**
- **RI_ConstraintTrigger_a_478597** en tabla **cat_proveedores**
- **RI_ConstraintTrigger_a_478598** en tabla **cat_proveedores**
- **RI_ConstraintTrigger_a_478607** en tabla **cat_proveedores**
- **RI_ConstraintTrigger_a_478608** en tabla **cat_proveedores**
- **RI_ConstraintTrigger_a_478612** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478613** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478592** en tabla **items**
- **RI_ConstraintTrigger_a_478593** en tabla **items**
- **RI_ConstraintTrigger_a_478627** en tabla **items**
- **RI_ConstraintTrigger_a_478628** en tabla **items**
- **RI_ConstraintTrigger_a_478637** en tabla **items**
- **RI_ConstraintTrigger_c_478634** en tabla **hist_cost_receta**
- **RI_ConstraintTrigger_c_478635** en tabla **hist_cost_receta**
- **RI_ConstraintTrigger_a_478632** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478633** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478642** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478643** en tabla **receta_version**
- **RI_ConstraintTrigger_c_478639** en tabla **historial_costos_item**
- **RI_ConstraintTrigger_c_478640** en tabla **historial_costos_item**
- **RI_ConstraintTrigger_c_478609** en tabla **purchase_orders**
- **RI_ConstraintTrigger_c_478610** en tabla **purchase_orders**
- **RI_ConstraintTrigger_a_478622** en tabla **ticket_venta_cab**
- **RI_ConstraintTrigger_a_478623** en tabla **ticket_venta_cab**
- **RI_ConstraintTrigger_c_478614** en tabla **recipe_cost_snapshots**
- **RI_ConstraintTrigger_c_478615** en tabla **recipe_cost_snapshots**
- **RI_ConstraintTrigger_a_478602** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_a_478603** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478579** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478580** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478584** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478585** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478594** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478595** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478599** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478600** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478604** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478605** en tabla **purchase_suggestion_lines**
- **RI_ConstraintTrigger_c_478619** en tabla **recipe_cost_snapshots**
- **RI_ConstraintTrigger_c_478620** en tabla **recipe_cost_snapshots**
- **RI_ConstraintTrigger_c_478684** en tabla **inventory_batch**
- **RI_ConstraintTrigger_c_478685** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478692** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478693** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478707** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478708** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478652** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478653** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478647** en tabla **items**
- **RI_ConstraintTrigger_a_478648** en tabla **items**
- **RI_ConstraintTrigger_a_478657** en tabla **items**
- **RI_ConstraintTrigger_a_478658** en tabla **items**
- **RI_ConstraintTrigger_c_478644** en tabla **historial_costos_receta**
- **RI_ConstraintTrigger_c_478645** en tabla **historial_costos_receta**
- **RI_ConstraintTrigger_c_478664** en tabla **insumo**
- **RI_ConstraintTrigger_c_478665** en tabla **insumo**
- **RI_ConstraintTrigger_a_478687** en tabla **proveedor**
- **RI_ConstraintTrigger_a_478688** en tabla **proveedor**
- **RI_ConstraintTrigger_a_478662** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478663** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_c_478649** en tabla **insumo_presentacion**
- **RI_ConstraintTrigger_c_478650** en tabla **insumo_presentacion**
- **RI_ConstraintTrigger_c_478674** en tabla **inv_stock_policy**
- **RI_ConstraintTrigger_c_478675** en tabla **inv_stock_policy**
- **RI_ConstraintTrigger_c_478654** en tabla **insumo_presentacion**
- **RI_ConstraintTrigger_c_478655** en tabla **insumo_presentacion**
- **RI_ConstraintTrigger_c_478659** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478660** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478669** en tabla **inv_consumo_pos_det**
- **RI_ConstraintTrigger_c_478670** en tabla **inv_consumo_pos_det**
- **RI_ConstraintTrigger_c_478689** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478690** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478694** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478679** en tabla **inv_stock_policy**
- **RI_ConstraintTrigger_c_478680** en tabla **inv_stock_policy**
- **RI_ConstraintTrigger_a_478667** en tabla **inv_consumo_pos**
- **RI_ConstraintTrigger_a_478668** en tabla **inv_consumo_pos**
- **RI_ConstraintTrigger_c_478704** en tabla **item_vendor**
- **RI_ConstraintTrigger_c_478705** en tabla **item_vendor**
- **RI_ConstraintTrigger_a_478727** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478728** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478717** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478718** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478712** en tabla **item_categories**
- **RI_ConstraintTrigger_a_478713** en tabla **item_categories**
- **RI_ConstraintTrigger_a_478722** en tabla **items**
- **RI_ConstraintTrigger_a_478723** en tabla **items**
- **RI_ConstraintTrigger_a_478757** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478758** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478737** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478738** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478767** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478768** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478772** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478773** en tabla **receta_version**
- **RI_ConstraintTrigger_c_478709** en tabla **item_vendor**
- **RI_ConstraintTrigger_c_478710** en tabla **item_vendor**
- **RI_ConstraintTrigger_c_478724** en tabla **lote**
- **RI_ConstraintTrigger_c_478725** en tabla **lote**
- **RI_ConstraintTrigger_c_478729** en tabla **merma**
- **RI_ConstraintTrigger_c_478730** en tabla **merma**
- **RI_ConstraintTrigger_a_478752** en tabla **roles**
- **RI_ConstraintTrigger_a_478753** en tabla **roles**
- **RI_ConstraintTrigger_c_478749** en tabla **model_has_permissions**
- **RI_ConstraintTrigger_c_478750** en tabla **model_has_permissions**
- **RI_ConstraintTrigger_c_478764** en tabla **mov_inv**
- **RI_ConstraintTrigger_c_478734** en tabla **merma**
- **RI_ConstraintTrigger_c_478735** en tabla **merma**
- **RI_ConstraintTrigger_c_478739** en tabla **merma**
- **RI_ConstraintTrigger_c_478765** en tabla **mov_inv**
- **RI_ConstraintTrigger_c_478769** en tabla **mov_inv**
- **RI_ConstraintTrigger_a_478747** en tabla **permissions**
- **RI_ConstraintTrigger_a_478748** en tabla **permissions**
- **RI_ConstraintTrigger_c_478770** en tabla **mov_inv**
- **RI_ConstraintTrigger_c_478754** en tabla **model_has_roles**
- **RI_ConstraintTrigger_c_478755** en tabla **model_has_roles**
- **RI_ConstraintTrigger_c_478759** en tabla **modificadores_pos**
- **RI_ConstraintTrigger_c_478760** en tabla **modificadores_pos**
- **RI_ConstraintTrigger_c_478799** en tabla **op_insumo**
- **RI_ConstraintTrigger_c_478800** en tabla **op_insumo**
- **RI_ConstraintTrigger_a_478777** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478778** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478837** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478838** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478817** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478818** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478802** en tabla **items**
- **RI_ConstraintTrigger_a_478803** en tabla **items**
- **RI_ConstraintTrigger_a_478827** en tabla **items**
- **RI_ConstraintTrigger_a_478828** en tabla **items**
- **RI_ConstraintTrigger_a_478797** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478798** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478832** en tabla **inventory_batch**
- **RI_ConstraintTrigger_c_478804** en tabla **op_insumo**
- **RI_ConstraintTrigger_c_478805** en tabla **op_insumo**
- **RI_ConstraintTrigger_a_478782** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478783** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478812** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478813** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_478807** en tabla **op_cab**
- **RI_ConstraintTrigger_a_478808** en tabla **op_cab**
- **RI_ConstraintTrigger_a_478822** en tabla **op_cab**
- **RI_ConstraintTrigger_a_478823** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478824** en tabla **op_yield**
- **RI_ConstraintTrigger_c_478825** en tabla **op_yield**
- **RI_ConstraintTrigger_c_478809** en tabla **op_insumo**
- **RI_ConstraintTrigger_c_478810** en tabla **op_insumo**
- **RI_ConstraintTrigger_c_478819** en tabla **op_produccion_cab**
- **RI_ConstraintTrigger_c_478820** en tabla **op_produccion_cab**
- **RI_ConstraintTrigger_c_478829** en tabla **perdida_log**
- **RI_ConstraintTrigger_c_478830** en tabla **perdida_log**
- **RI_ConstraintTrigger_c_478834** en tabla **perdida_log**
- **RI_ConstraintTrigger_c_478835** en tabla **perdida_log**
- **RI_ConstraintTrigger_a_478882** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478883** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478842** en tabla **users**
- **RI_ConstraintTrigger_a_478843** en tabla **users**
- **RI_ConstraintTrigger_a_478887** en tabla **users**
- **RI_ConstraintTrigger_a_478888** en tabla **users**
- **RI_ConstraintTrigger_c_478844** en tabla **postcorte**
- **RI_ConstraintTrigger_c_478845** en tabla **postcorte**
- **RI_ConstraintTrigger_c_478849** en tabla **postcorte**
- **RI_ConstraintTrigger_c_478850** en tabla **postcorte**
- **RI_ConstraintTrigger_a_478897** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478898** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478902** en tabla **items**
- **RI_ConstraintTrigger_a_478903** en tabla **items**
- **RI_ConstraintTrigger_a_478892** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478893** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_478877** en tabla **job_recalc_queue**
- **RI_ConstraintTrigger_a_478878** en tabla **job_recalc_queue**
- **RI_ConstraintTrigger_c_478839** en tabla **perdida_log**
- **RI_ConstraintTrigger_c_478840** en tabla **perdida_log**
- **RI_ConstraintTrigger_c_478854** en tabla **precorte_efectivo**
- **RI_ConstraintTrigger_a_478852** en tabla **precorte**
- **RI_ConstraintTrigger_a_478853** en tabla **precorte**
- **RI_ConstraintTrigger_a_478857** en tabla **precorte**
- **RI_ConstraintTrigger_c_478855** en tabla **precorte_efectivo**
- **RI_ConstraintTrigger_c_478859** en tabla **precorte_otros**
- **RI_ConstraintTrigger_c_478860** en tabla **precorte_otros**
- **RI_ConstraintTrigger_a_478867** en tabla **sol_prod_cab**
- **RI_ConstraintTrigger_a_478868** en tabla **sol_prod_cab**
- **RI_ConstraintTrigger_c_478874** en tabla **prod_det**
- **RI_ConstraintTrigger_c_478875** en tabla **prod_det**
- **RI_ConstraintTrigger_a_478872** en tabla **prod_cab**
- **RI_ConstraintTrigger_a_478873** en tabla **prod_cab**
- **RI_ConstraintTrigger_c_478869** en tabla **prod_cab**
- **RI_ConstraintTrigger_c_478870** en tabla **prod_cab**
- **RI_ConstraintTrigger_c_478879** en tabla **recalc_log**
- **RI_ConstraintTrigger_c_478880** en tabla **recalc_log**
- **RI_ConstraintTrigger_c_478884** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478885** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478889** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478890** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478894** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478895** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478899** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478900** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478954** en tabla **audit_log**
- **RI_ConstraintTrigger_c_478955** en tabla **audit_log**
- **RI_ConstraintTrigger_a_478962** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_a_478963** en tabla **cash_fund_movements**
- **RI_ConstraintTrigger_a_478912** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478913** en tabla **cat_unidades**
- **RI_ConstraintTrigger_c_478959** en tabla **cash_fund_movement_audit_log**
- **RI_ConstraintTrigger_c_478960** en tabla **cash_fund_movement_audit_log**
- **RI_ConstraintTrigger_c_478964** en tabla **cash_fund_movement_audit_log**
- **RI_ConstraintTrigger_c_478965** en tabla **cash_fund_movement_audit_log**
- **RI_ConstraintTrigger_a_478937** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478938** en tabla **receta_cab**
- **RI_ConstraintTrigger_a_478917** en tabla **items**
- **RI_ConstraintTrigger_a_478918** en tabla **items**
- **RI_ConstraintTrigger_a_478927** en tabla **items**
- **RI_ConstraintTrigger_a_478967** en tabla **menu_items**
- **RI_ConstraintTrigger_a_478968** en tabla **menu_items**
- **RI_ConstraintTrigger_a_478922** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478923** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478932** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478933** en tabla **receta_version**
- **RI_ConstraintTrigger_a_478942** en tabla **permissions**
- **RI_ConstraintTrigger_a_478943** en tabla **permissions**
- **RI_ConstraintTrigger_a_478947** en tabla **roles**
- **RI_ConstraintTrigger_a_478948** en tabla **roles**
- **RI_ConstraintTrigger_a_478907** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_a_478908** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478919** en tabla **receta_det**
- **RI_ConstraintTrigger_c_478920** en tabla **receta_det**
- **RI_ConstraintTrigger_c_478904** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478905** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478909** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478910** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478914** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478915** en tabla **recepcion_det**
- **RI_ConstraintTrigger_c_478924** en tabla **receta_det**
- **RI_ConstraintTrigger_c_478925** en tabla **receta_det**
- **RI_ConstraintTrigger_c_478929** en tabla **receta_insumo**
- **RI_ConstraintTrigger_c_478930** en tabla **receta_insumo**
- **RI_ConstraintTrigger_c_478934** en tabla **receta_insumo**
- **RI_ConstraintTrigger_c_478935** en tabla **receta_insumo**
- **RI_ConstraintTrigger_c_478944** en tabla **role_has_permissions**
- **RI_ConstraintTrigger_c_478945** en tabla **role_has_permissions**
- **RI_ConstraintTrigger_c_478949** en tabla **role_has_permissions**
- **RI_ConstraintTrigger_c_478950** en tabla **role_has_permissions**
- **RI_ConstraintTrigger_a_479012** en tabla **items**
- **RI_ConstraintTrigger_a_479013** en tabla **items**
- **RI_ConstraintTrigger_a_479027** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_479028** en tabla **unidades_medida_legacy**
- **RI_ConstraintTrigger_a_478972** en tabla **menu_items**
- **RI_ConstraintTrigger_a_478973** en tabla **menu_items**
- **RI_ConstraintTrigger_a_479022** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_479023** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_479017** en tabla **items**
- **RI_ConstraintTrigger_a_479018** en tabla **items**
- **RI_ConstraintTrigger_c_478969** en tabla **menu_engineering_snapshots**
- **RI_ConstraintTrigger_c_478970** en tabla **menu_engineering_snapshots**
- **RI_ConstraintTrigger_c_478974** en tabla **menu_item_sync_map**
- **RI_ConstraintTrigger_c_478975** en tabla **menu_item_sync_map**
- **RI_ConstraintTrigger_a_478977** en tabla **pos_sync_batches**
- **RI_ConstraintTrigger_a_478978** en tabla **pos_sync_batches**
- **RI_ConstraintTrigger_c_478979** en tabla **pos_sync_logs**
- **RI_ConstraintTrigger_c_478980** en tabla **pos_sync_logs**
- **RI_ConstraintTrigger_a_479007** en tabla **sol_prod_cab**
- **RI_ConstraintTrigger_a_479008** en tabla **sol_prod_cab**
- **RI_ConstraintTrigger_c_478984** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478985** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_a_478992** en tabla **report_definitions**
- **RI_ConstraintTrigger_a_478993** en tabla **report_definitions**
- **RI_ConstraintTrigger_a_479032** en tabla **receta_shadow**
- **RI_ConstraintTrigger_a_479033** en tabla **receta_shadow**
- **RI_ConstraintTrigger_c_478989** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478990** en tabla **recepcion_cab**
- **RI_ConstraintTrigger_c_478994** en tabla **report_runs**
- **RI_ConstraintTrigger_c_478995** en tabla **report_runs**
- **RI_ConstraintTrigger_c_479009** en tabla **sol_prod_det**
- **RI_ConstraintTrigger_c_479010** en tabla **sol_prod_det**
- **RI_ConstraintTrigger_c_479014** en tabla **stock_policy**
- **RI_ConstraintTrigger_c_479015** en tabla **stock_policy**
- **RI_ConstraintTrigger_c_479019** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_479020** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_478999** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479024** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_479025** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_479029** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_479000** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479004** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479005** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_a_479057** en tabla **users**
- **RI_ConstraintTrigger_a_479047** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_479048** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_479077** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_479078** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_479067** en tabla **items**
- **RI_ConstraintTrigger_a_479068** en tabla **items**
- **RI_ConstraintTrigger_a_479062** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_479063** en tabla **inventory_batch**
- **RI_ConstraintTrigger_a_479037** en tabla **receta_version**
- **RI_ConstraintTrigger_a_479038** en tabla **receta_version**
- **RI_ConstraintTrigger_a_479092** en tabla **rol**
- **RI_ConstraintTrigger_a_479082** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_479083** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_479087** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_a_479093** en tabla **rol**
- **RI_ConstraintTrigger_a_479042** en tabla **transfer_cab**
- **RI_ConstraintTrigger_a_479043** en tabla **transfer_cab**
- **RI_ConstraintTrigger_c_479034** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_479035** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_479039** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_479040** en tabla **ticket_venta_det**
- **RI_ConstraintTrigger_c_479044** en tabla **transfer_det**
- **RI_ConstraintTrigger_c_479045** en tabla **transfer_det**
- **RI_ConstraintTrigger_c_479094** en tabla **usuario**
- **RI_ConstraintTrigger_c_479095** en tabla **usuario**
- **RI_ConstraintTrigger_a_479072** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_a_479073** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479049** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479050** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479084** en tabla **uom_conversion_legacy**
- **RI_ConstraintTrigger_c_479085** en tabla **uom_conversion_legacy**
- **RI_ConstraintTrigger_c_479089** en tabla **uom_conversion_legacy**
- **RI_ConstraintTrigger_c_479090** en tabla **uom_conversion_legacy**
- **RI_ConstraintTrigger_c_479064** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479065** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479069** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479070** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479074** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479075** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479079** en tabla **traspaso_det**
- **RI_ConstraintTrigger_c_479080** en tabla **traspaso_det**
- **RI_ConstraintTrigger_a_478417** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478418** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478847** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478848** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478862** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478863** en tabla **sesion_cajon**
- **RI_ConstraintTrigger_a_478427** en tabla **users**
- **RI_ConstraintTrigger_a_478428** en tabla **users**
- **RI_ConstraintTrigger_a_478462** en tabla **users**
- **RI_ConstraintTrigger_a_478463** en tabla **users**
- **RI_ConstraintTrigger_a_478467** en tabla **users**
- **RI_ConstraintTrigger_a_478468** en tabla **users**
- **RI_ConstraintTrigger_a_478477** en tabla **users**
- **RI_ConstraintTrigger_a_478478** en tabla **users**
- **RI_ConstraintTrigger_a_478482** en tabla **users**
- **RI_ConstraintTrigger_a_478483** en tabla **users**
- **RI_ConstraintTrigger_a_478487** en tabla **users**
- **RI_ConstraintTrigger_a_478488** en tabla **users**
- **RI_ConstraintTrigger_a_478582** en tabla **users**
- **RI_ConstraintTrigger_a_478583** en tabla **users**
- **RI_ConstraintTrigger_a_478587** en tabla **users**
- **RI_ConstraintTrigger_a_478588** en tabla **users**
- **RI_ConstraintTrigger_a_478617** en tabla **users**
- **RI_ConstraintTrigger_a_478618** en tabla **users**
- **RI_ConstraintTrigger_a_478742** en tabla **users**
- **RI_ConstraintTrigger_a_478743** en tabla **users**
- **RI_ConstraintTrigger_a_478787** en tabla **users**
- **RI_ConstraintTrigger_a_478788** en tabla **users**
- **RI_ConstraintTrigger_a_478792** en tabla **users**
- **RI_ConstraintTrigger_a_478793** en tabla **users**
- **RI_ConstraintTrigger_a_478952** en tabla **users**
- **RI_ConstraintTrigger_a_478953** en tabla **users**
- **RI_ConstraintTrigger_a_478957** en tabla **users**
- **RI_ConstraintTrigger_a_478958** en tabla **users**
- **RI_ConstraintTrigger_a_478982** en tabla **users**
- **RI_ConstraintTrigger_a_478983** en tabla **users**
- **RI_ConstraintTrigger_a_478987** en tabla **users**
- **RI_ConstraintTrigger_a_478988** en tabla **users**
- **RI_ConstraintTrigger_a_478997** en tabla **users**
- **RI_ConstraintTrigger_a_478998** en tabla **users**
- **RI_ConstraintTrigger_a_479002** en tabla **users**
- **RI_ConstraintTrigger_a_479003** en tabla **users**
- **RI_ConstraintTrigger_a_479058** en tabla **users**
- **RI_ConstraintTrigger_c_478419** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_c_478420** en tabla **alertas_cortes**
- **RI_ConstraintTrigger_a_478532** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478533** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478577** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478578** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478677** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_a_478678** en tabla **cat_sucursales**
- **RI_ConstraintTrigger_c_478485** en tabla **cash_funds**
- **RI_ConstraintTrigger_c_478489** en tabla **cash_funds**
- **RI_ConstraintTrigger_c_478490** en tabla **cash_funds**
- **RI_ConstraintTrigger_a_479052** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_479053** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_c_478534** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_c_478535** en tabla **cat_almacenes**
- **RI_ConstraintTrigger_a_478697** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478698** en tabla **cat_unidades**
- **RI_ConstraintTrigger_a_478672** en tabla **items**
- **RI_ConstraintTrigger_a_478673** en tabla **items**
- **RI_ConstraintTrigger_a_478638** en tabla **items**
- **RI_ConstraintTrigger_a_478682** en tabla **items**
- **RI_ConstraintTrigger_a_478683** en tabla **items**
- **RI_ConstraintTrigger_a_478702** en tabla **items**
- **RI_ConstraintTrigger_a_478703** en tabla **items**
- **RI_ConstraintTrigger_a_478732** en tabla **items**
- **RI_ConstraintTrigger_a_478733** en tabla **items**
- **RI_ConstraintTrigger_a_478762** en tabla **items**
- **RI_ConstraintTrigger_a_478763** en tabla **items**
- **RI_ConstraintTrigger_a_478928** en tabla **items**
- **RI_ConstraintTrigger_c_478714** en tabla **items**
- **RI_ConstraintTrigger_c_478715** en tabla **items**
- **RI_ConstraintTrigger_c_478719** en tabla **items**
- **RI_ConstraintTrigger_c_478720** en tabla **items**
- **RI_ConstraintTrigger_a_478833** en tabla **inventory_batch**
- **RI_ConstraintTrigger_c_478939** en tabla **receta_version**
- **RI_ConstraintTrigger_c_478940** en tabla **receta_version**
- **RI_ConstraintTrigger_a_479088** en tabla **unidad_medida_legacy**
- **RI_ConstraintTrigger_c_478695** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478699** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478700** en tabla **insumo_proveedor_presentacion**
- **RI_ConstraintTrigger_c_478740** en tabla **merma**
- **RI_ConstraintTrigger_c_478744** en tabla **merma**
- **RI_ConstraintTrigger_c_478745** en tabla **merma**
- **RI_ConstraintTrigger_c_478774** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478775** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478779** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478780** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478784** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478785** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478789** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478790** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478794** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478795** en tabla **op_cab**
- **RI_ConstraintTrigger_c_478814** en tabla **op_insumo**
- **RI_ConstraintTrigger_c_478815** en tabla **op_insumo**
- **RI_ConstraintTrigger_a_478858** en tabla **precorte**
- **RI_ConstraintTrigger_c_478864** en tabla **precorte**
- **RI_ConstraintTrigger_c_478865** en tabla **precorte**
- **trg_precorte_after_update_aprobado** en tabla **precorte**
- **RI_ConstraintTrigger_c_478565** en tabla **purchase_requests**
- **RI_ConstraintTrigger_c_478589** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_478590** en tabla **purchase_suggestions**
- **RI_ConstraintTrigger_c_479030** en tabla **ticket_det_consumo**
- **RI_ConstraintTrigger_c_479054** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479055** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479059** en tabla **traspaso_cab**
- **RI_ConstraintTrigger_c_479060** en tabla **traspaso_cab**
