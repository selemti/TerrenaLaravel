Data Dictionary (Compact) — public

Fecha: 2025-10-17 08:41

search_path sesión: selemti, public

## public.action_history — ~ 36562 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - action_time: timestamp without time zone, yes
  - action_name: character varying, yes
  - description: character varying, yes
  - user_id: integer, yes
- FKs detalle
  - user_id ? public.users

## public.attendence_history — ~ 8 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - clock_in_time: timestamp without time zone, yes
  - clock_out_time: timestamp without time zone, yes
  - clock_in_hour: smallint, yes
  - clock_out_hour: smallint, yes
  - clocked_out: boolean, yes
  - user_id: integer, yes
  - shift_id: integer, yes
  - terminal_id: integer, yes
- FKs detalle
  - shift_id ? public.shift
  - terminal_id ? public.terminal
  - user_id ? public.users

## public.cash_drawer — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - terminal_id: integer, yes
- FKs detalle
  - terminal_id ? public.terminal

## public.cash_drawer_reset_history — ~ 70 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - reset_time: timestamp without time zone, yes
  - user_id: integer, yes
- FKs detalle
  - user_id ? public.users

## public.cooking_instruction — ~ 17 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - description: character varying, yes

## public.coupon_and_discount — ~ 6 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - type: integer, yes
  - barcode: character varying, yes
  - qualification_type: integer, yes
  - apply_to_all: boolean, yes
  - minimum_buy: integer, yes
  - maximum_off: integer, yes
  - value: double precision, yes
  - expiry_date: timestamp without time zone, yes
  - enabled: boolean, yes
  - auto_apply: boolean, yes
  - modifiable: boolean, yes
  - never_expire: boolean, yes
  - uuid: character varying, yes

## public.currency — ~ 5 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - code: character varying, yes
  - name: character varying, yes
  - symbol: character varying, yes
  - exchange_rate: double precision, yes
  - decimal_places: integer, yes
  - tolerance: double precision, yes
  - buy_price: double precision, yes
  - sales_price: double precision, yes
  - main: boolean, yes

## public.currency_balance — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - balance: double precision, yes
  - currency_id: integer, yes
  - cash_drawer_id: integer, yes
  - dpr_id: integer, yes
- FKs detalle
  - dpr_id ? public.drawer_pull_report
  - cash_drawer_id ? public.cash_drawer
  - currency_id ? public.currency

## public.custom_payment — ~ 1 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - required_ref_number: boolean, yes
  - ref_number_field_name: character varying, yes

## public.customer — ~ 0 filas

- Flags: sin_timestamps

- PK: auto_id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - auto_id: integer, no
  - loyalty_no: character varying, yes
  - loyalty_point: integer, yes
  - social_security_number: character varying, yes
  - picture: bytea, yes
  - homephone_no: character varying, yes
  - mobile_no: character varying, yes
  - workphone_no: character varying, yes
  - email: character varying, yes
  - salutation: character varying, yes
  - first_name: character varying, yes
  - last_name: character varying, yes
  - name: character varying, yes
  - dob: character varying, yes
  - ssn: character varying, yes
  - address: character varying, yes
  - city: character varying, yes
  - state: character varying, yes
  - zip_code: character varying, yes
  - country: character varying, yes
  - vip: boolean, yes
  - credit_limit: double precision, yes
  - credit_spent: double precision, yes
  - credit_card_no: character varying, yes
  - note: character varying, yes

## public.customer_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.customer

## public.daily_folio_counter — ~ 21 filas

- Flags: sin_timestamps

- PK: folio_date, branch_key
- FKs: N/A
- Columnas (nombre: tipo, null)
  - folio_date: date, no
  - branch_key: text, no
  - last_value: integer, no

## public.data_update_info — ~ 1 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - last_update_time: timestamp without time zone, yes

## public.delivery_address — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - address: character varying, yes
  - phone_extension: character varying, yes
  - room_no: character varying, yes
  - distance: double precision, yes
  - customer_id: integer, yes
- FKs detalle
  - customer_id ? public.customer

## public.delivery_charge — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - zip_code: character varying, yes
  - start_range: double precision, yes
  - end_range: double precision, yes
  - charge_amount: double precision, yes

## public.delivery_configuration — ~ 1 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - unit_name: character varying, yes
  - unit_symbol: character varying, yes
  - charge_by_zip_code: boolean, yes

## public.delivery_instruction — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - notes: character varying, yes
  - customer_no: integer, yes
- FKs detalle
  - customer_no ? public.customer

## public.drawer_assigned_history — ~ 141 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - time: timestamp without time zone, yes
  - operation: character varying, yes
  - a_user: integer, yes
- FKs detalle
  - a_user ? public.users

## public.drawer_pull_report — ~ 70 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - report_time: timestamp without time zone, yes
  - reg: character varying, yes
  - ticket_count: integer, yes
  - begin_cash: double precision, yes
  - net_sales: double precision, yes
  - sales_tax: double precision, yes
  - cash_tax: double precision, yes
  - total_revenue: double precision, yes
  - gross_receipts: double precision, yes
  - giftcertreturncount: integer, yes
  - giftcertreturnamount: double precision, yes
  - giftcertchangeamount: double precision, yes
  - cash_receipt_no: integer, yes
  - cash_receipt_amount: double precision, yes
  - credit_card_receipt_no: integer, yes
  - credit_card_receipt_amount: double precision, yes
  - debit_card_receipt_no: integer, yes
  - debit_card_receipt_amount: double precision, yes
  - refund_receipt_count: integer, yes
  - refund_amount: double precision, yes
  - receipt_differential: double precision, yes
  - cash_back: double precision, yes
  - cash_tips: double precision, yes
  - charged_tips: double precision, yes
  - tips_paid: double precision, yes
  - tips_differential: double precision, yes
  - pay_out_no: integer, yes
  - pay_out_amount: double precision, yes
  - drawer_bleed_no: integer, yes
  - drawer_bleed_amount: double precision, yes
  - drawer_accountable: double precision, yes
  - cash_to_deposit: double precision, yes
  - variance: double precision, yes
  - delivery_charge: double precision, yes
  - totalvoidwst: double precision, yes
  - totalvoid: double precision, yes
  - totaldiscountcount: integer, yes
  - totaldiscountamount: double precision, yes
  - totaldiscountsales: double precision, yes
  - totaldiscountguest: integer, yes
  - totaldiscountpartysize: integer, yes
  - totaldiscountchecksize: integer, yes
  - totaldiscountpercentage: double precision, yes
  - totaldiscountratio: double precision, yes
  - user_id: integer, yes
  - terminal_id: integer, yes
- FKs detalle
  - terminal_id ? public.terminal
  - user_id ? public.users

## public.drawer_pull_report_voidtickets — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - dpreport_id: integer, no
  - code: integer, yes
  - reason: character varying, yes
  - hast: character varying, yes
  - quantity: integer, yes
  - amount: double precision, yes
- FKs detalle
  - dpreport_id ? public.drawer_pull_report

## public.employee_in_out_history — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - out_time: timestamp without time zone, yes
  - in_time: timestamp without time zone, yes
  - out_hour: smallint, yes
  - in_hour: smallint, yes
  - clock_out: boolean, yes
  - user_id: integer, yes
  - shift_id: integer, yes
  - terminal_id: integer, yes
- FKs detalle
  - terminal_id ? public.terminal
  - user_id ? public.users
  - shift_id ? public.shift

## public.global_config — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - pos_key: character varying, yes
  - pos_value: character varying, yes

## public.gratuity — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - amount: double precision, yes
  - paid: boolean, yes
  - refunded: boolean, yes
  - ticket_id: integer, yes
  - owner_id: integer, yes
  - terminal_id: integer, yes
- FKs detalle
  - terminal_id ? public.terminal
  - owner_id ? public.users
  - ticket_id ? public.ticket

## public.group_taxes — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - group_id: character varying, no
  - elt: integer, no
- FKs detalle
  - group_id ? public.tax_group
  - elt ? public.tax

## public.guest_check_print — ~ 95 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - ticket_id: integer, yes
  - table_no: character varying, yes
  - ticket_total: double precision, yes
  - print_time: timestamp without time zone, yes
  - user_id: integer, yes
- FKs detalle
  - user_id ? public.users

## public.inventory_group — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - visible: boolean, yes

## public.inventory_item — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 5
- Columnas (nombre: tipo, null)
  - id: integer, no
  - create_time: timestamp without time zone, yes
  - last_update_date: timestamp without time zone, yes
  - name: character varying, yes
  - package_barcode: character varying, yes
  - unit_barcode: character varying, yes
  - unit_per_package: double precision, yes
  - sort_order: integer, yes
  - package_reorder_level: integer, yes
  - package_replenish_level: integer, yes
  - description: character varying, yes
  - average_package_price: double precision, yes
  - total_unit_packages: double precision, yes
  - total_recepie_units: double precision, yes
  - unit_purchase_price: double precision, yes
  - unit_selling_price: double precision, yes
  - visible: boolean, yes
  - punit_id: integer, yes
  - recipe_unit_id: integer, yes
  - item_group_id: integer, yes
  - item_location_id: integer, yes
  - item_vendor_id: integer, yes
  - total_packages: integer, yes
- FKs detalle
  - item_vendor_id ? public.inventory_vendor
  - punit_id ? public.packaging_unit
  - recipe_unit_id ? public.packaging_unit
  - item_location_id ? public.inventory_location
  - item_group_id ? public.inventory_group

## public.inventory_location — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - sort_order: integer, yes
  - visible: boolean, yes
  - warehouse_id: integer, yes
- FKs detalle
  - warehouse_id ? public.inventory_warehouse

## public.inventory_meta_code — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - type: character varying, yes
  - code_text: character varying, yes
  - code_no: integer, yes
  - description: character varying, yes

## public.inventory_transaction — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 5
- Columnas (nombre: tipo, null)
  - id: integer, no
  - transaction_date: timestamp without time zone, yes
  - unit_quantity: double precision, yes
  - unit_price: double precision, yes
  - remark: character varying, yes
  - tran_type: integer, yes
  - reference_id: integer, yes
  - item_id: integer, yes
  - vendor_id: integer, yes
  - from_warehouse_id: integer, yes
  - to_warehouse_id: integer, yes
  - quantity: integer, yes
- FKs detalle
  - from_warehouse_id ? public.inventory_warehouse
  - item_id ? public.inventory_item
  - to_warehouse_id ? public.inventory_warehouse
  - reference_id ? public.purchase_order
  - vendor_id ? public.inventory_vendor

## public.inventory_unit — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - short_name: character varying, yes
  - long_name: character varying, yes
  - alt_name: character varying, yes
  - conv_factor1: character varying, yes
  - conv_factor2: character varying, yes
  - conv_factor3: character varying, yes

## public.inventory_vendor — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - visible: boolean, yes
  - address: character varying, no
  - city: character varying, no
  - state: character varying, no
  - zip: character varying, no
  - country: character varying, no
  - email: character varying, no
  - phone: character varying, no
  - fax: character varying, yes

## public.inventory_warehouse — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - visible: boolean, yes

## public.item_order_type — ~ 90 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - menu_item_id: integer, no
  - order_type_id: integer, no
- FKs detalle
  - menu_item_id ? public.menu_item
  - order_type_id ? public.order_type

## public.kds_ready_log — ~ 5 filas

- Flags: sin_timestamps

- PK: ticket_id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - ticket_id: integer, no
  - notified_at: timestamp without time zone, no

## public.kit_ticket_table_num — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - kit_ticket_id: integer, no
  - table_id: integer, yes
- FKs detalle
  - kit_ticket_id ? public.kitchen_ticket

## public.kitchen_ticket — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - ticket_id: integer, yes
  - create_date: timestamp without time zone, yes
  - close_date: timestamp without time zone, yes
  - voided: boolean, yes
  - sequence_number: integer, yes
  - status: character varying, yes
  - server_name: character varying, yes
  - ticket_type: character varying, yes
  - pg_id: integer, yes
- FKs detalle
  - pg_id ? public.printer_group

## public.kitchen_ticket_item — ~ 1691 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - cookable: boolean, yes
  - ticket_item_id: integer, no
  - ticket_item_modifier_id: integer, yes
  - menu_item_code: character varying, yes
  - menu_item_name: character varying, yes
  - menu_item_group_id: integer, yes
  - menu_item_group_name: character varying, yes
  - quantity: integer, yes
  - fractional_quantity: double precision, yes
  - fractional_unit: boolean, yes
  - unit_name: character varying, yes
  - sort_order: integer, yes
  - voided: boolean, yes
  - status: character varying, yes
  - kithen_ticket_id: integer, yes
  - item_order: integer, yes
- FKs detalle
  - kithen_ticket_id ? public.kitchen_ticket

## public.menu_category — ~ 7 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - translated_name: character varying, yes
  - visible: boolean, yes
  - beverage: boolean, yes
  - sort_order: integer, yes
  - btn_color: integer, yes
  - text_color: integer, yes

## public.menu_group — ~ 23 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - translated_name: character varying, yes
  - visible: boolean, yes
  - sort_order: integer, yes
  - btn_color: integer, yes
  - text_color: integer, yes
  - category_id: integer, yes
- FKs detalle
  - category_id ? public.menu_category

## public.menu_item — ~ 93 filas

- Flags: sin_timestamps

- PK: id
- FKs: 5
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - description: character varying, yes
  - unit_name: character varying, yes
  - translated_name: character varying, yes
  - barcode: character varying, yes
  - buy_price: double precision, no
  - stock_amount: double precision, yes
  - price: double precision, no
  - discount_rate: double precision, yes
  - visible: boolean, yes
  - disable_when_stock_amount_is_zero: boolean, yes
  - sort_order: integer, yes
  - btn_color: integer, yes
  - text_color: integer, yes
  - image: bytea, yes
  - show_image_only: boolean, yes
  - fractional_unit: boolean, yes
  - pizza_type: boolean, yes
  - default_sell_portion: integer, yes
  - group_id: integer, yes
  - tax_group_id: character varying, yes
  - recepie: integer, yes
  - pg_id: integer, yes
  - tax_id: integer, yes
- FKs detalle
  - pg_id ? public.printer_group
  - group_id ? public.menu_group
  - tax_group_id ? public.tax_group
  - recepie ? public.recepie
  - tax_id ? public.tax

## public.menu_item_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: menu_item_id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - menu_item_id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - menu_item_id ? public.menu_item

## public.menu_item_size — ~ 3 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - translated_name: character varying, yes
  - description: character varying, yes
  - sort_order: integer, yes
  - size_in_inch: double precision, yes
  - default_size: boolean, yes

## public.menu_item_terminal_ref — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - menu_item_id: integer, no
  - terminal_id: integer, no
- FKs detalle
  - terminal_id ? public.terminal
  - menu_item_id ? public.menu_item

## public.menu_modifier — ~ 165 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - translated_name: character varying, yes
  - price: double precision, yes
  - extra_price: double precision, yes
  - sort_order: integer, yes
  - btn_color: integer, yes
  - text_color: integer, yes
  - enable: boolean, yes
  - fixed_price: boolean, yes
  - print_to_kitchen: boolean, yes
  - section_wise_pricing: boolean, yes
  - pizza_modifier: boolean, yes
  - group_id: integer, yes
  - tax_id: integer, yes
- FKs detalle
  - group_id ? public.menu_modifier_group
  - tax_id ? public.tax
  - group_id ? public.menu_modifier_group

## public.menu_modifier_group — ~ 49 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - translated_name: character varying, yes
  - enabled: boolean, yes
  - exclusived: boolean, yes
  - required: boolean, yes

## public.menu_modifier_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: menu_modifier_id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - menu_modifier_id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - menu_modifier_id ? public.menu_modifier

## public.menucategory_discount — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - discount_id: integer, no
  - menucategory_id: integer, no
- FKs detalle
  - discount_id ? public.coupon_and_discount
  - menucategory_id ? public.menu_category

## public.menugroup_discount — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - discount_id: integer, no
  - menugroup_id: integer, no
- FKs detalle
  - menugroup_id ? public.menu_group
  - discount_id ? public.coupon_and_discount

## public.menuitem_discount — ~ 78 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - discount_id: integer, no
  - menuitem_id: integer, no
- FKs detalle
  - discount_id ? public.coupon_and_discount
  - menuitem_id ? public.menu_item

## public.menuitem_modifiergroup — ~ 62 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - min_quantity: integer, yes
  - max_quantity: integer, yes
  - sort_order: integer, yes
  - modifier_group: integer, yes
  - menuitem_modifiergroup_id: integer, yes
- FKs detalle
  - modifier_group ? public.menu_modifier_group
  - modifier_group ? public.menu_modifier_group
  - menuitem_modifiergroup_id ? public.menu_item

## public.menuitem_pizzapirce — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - menu_item_id: integer, no
  - pizza_price_id: integer, no
- FKs detalle
  - menu_item_id ? public.menu_item
  - pizza_price_id ? public.pizza_price

## public.menuitem_shift — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - shift_price: double precision, yes
  - shift_id: integer, yes
  - menuitem_id: integer, yes
- FKs detalle
  - menuitem_id ? public.menu_item
  - shift_id ? public.shift

## public.menumodifier_pizzamodifierprice — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - menumodifier_id: integer, no
  - pizzamodifierprice_id: integer, no
- FKs detalle
  - pizzamodifierprice_id ? public.pizza_modifier_price
  - menumodifier_id ? public.menu_modifier

## public.migrations — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - migration: character varying, no
  - batch: integer, no

## public.modifier_multiplier_price — ~ 63 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - price: double precision, yes
  - multiplier_id: character varying, yes
  - menumodifier_id: integer, yes
  - pizza_modifier_price_id: integer, yes
- FKs detalle
  - menumodifier_id ? public.menu_modifier
  - pizza_modifier_price_id ? public.pizza_modifier_price
  - multiplier_id ? public.multiplier

## public.multiplier — ~ 1 filas

- Flags: sin_timestamps

- PK: name
- FKs: N/A
- Columnas (nombre: tipo, null)
  - name: character varying, no
  - ticket_prefix: character varying, yes
  - rate: double precision, yes
  - sort_order: integer, yes
  - default_multiplier: boolean, yes
  - main: boolean, yes
  - btn_color: integer, yes
  - text_color: integer, yes

## public.order_type — ~ 4 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - enabled: boolean, yes
  - show_table_selection: boolean, yes
  - show_guest_selection: boolean, yes
  - should_print_to_kitchen: boolean, yes
  - prepaid: boolean, yes
  - close_on_paid: boolean, yes
  - required_customer_data: boolean, yes
  - delivery: boolean, yes
  - show_item_barcode: boolean, yes
  - show_in_login_screen: boolean, yes
  - consolidate_tiems_in_receipt: boolean, yes
  - allow_seat_based_order: boolean, yes
  - hide_item_with_empty_inventory: boolean, yes
  - has_forhere_and_togo: boolean, yes
  - pre_auth_credit_card: boolean, yes
  - bar_tab: boolean, yes
  - retail_order: boolean, yes
  - show_price_on_button: boolean, yes
  - show_stock_count_on_button: boolean, yes
  - show_unit_price_in_ticket_grid: boolean, yes
  - properties: text, yes

## public.packaging_unit — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - short_name: character varying, yes
  - factor: double precision, yes
  - baseunit: boolean, yes
  - dimension: character varying, yes

## public.payout_reasons — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - reason: character varying, yes

## public.payout_recepients — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes

## public.pizza_crust — ~ 2 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - translated_name: character varying, yes
  - description: character varying, yes
  - sort_order: integer, yes
  - default_crust: boolean, yes

## public.pizza_modifier_price — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - item_size: integer, yes
- FKs detalle
  - item_size ? public.menu_item_size

## public.pizza_price — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - price: double precision, yes
  - menu_item_size: integer, yes
  - crust: integer, yes
  - order_type: integer, yes
- FKs detalle
  - menu_item_size ? public.menu_item_size
  - crust ? public.pizza_crust
  - order_type ? public.order_type

## public.printer_configuration — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - receipt_printer: character varying, yes
  - kitchen_printer: character varying, yes
  - prwts: boolean, yes
  - prwtp: boolean, yes
  - pkwts: boolean, yes
  - pkwtp: boolean, yes
  - unpft: boolean, yes
  - unpfk: boolean, yes

## public.printer_group — ~ 2 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - is_default: boolean, yes

## public.printer_group_printers — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - printer_id: integer, no
  - printer_name: character varying, yes
- FKs detalle
  - printer_id ? public.printer_group

## public.purchase_order — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - order_id: character varying, yes
  - name: character varying, yes

## public.recepie — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - menu_item: integer, yes
- FKs detalle
  - menu_item ? public.menu_item

## public.recepie_item — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - percentage: double precision, yes
  - inventory_deductable: boolean, yes
  - inventory_item: integer, yes
  - recepie_id: integer, yes
- FKs detalle
  - inventory_item ? public.inventory_item
  - recepie_id ? public.recepie

## public.restaurant — ~ 1 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - unique_id: integer, yes
  - name: character varying, yes
  - address_line1: character varying, yes
  - address_line2: character varying, yes
  - address_line3: character varying, yes
  - zip_code: character varying, yes
  - telephone: character varying, yes
  - capacity: integer, yes
  - tables: integer, yes
  - cname: character varying, yes
  - csymbol: character varying, yes
  - sc_percentage: double precision, yes
  - gratuity_percentage: double precision, yes
  - ticket_footer: character varying, yes
  - price_includes_tax: boolean, yes
  - allow_modifier_max_exceed: boolean, yes

## public.restaurant_properties — ~ 3 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.restaurant

## public.shift — ~ 1 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - start_time: timestamp without time zone, yes
  - end_time: timestamp without time zone, yes
  - shift_len: bigint, yes

## public.shop_floor — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - occupied: boolean, yes
  - image: oid, yes

## public.shop_floor_template — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - default_floor: boolean, yes
  - main: boolean, yes
  - floor_id: integer, yes
- FKs detalle
  - floor_id ? public.shop_floor

## public.shop_floor_template_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.shop_floor_template

## public.shop_table — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - description: character varying, yes
  - capacity: integer, yes
  - x: integer, yes
  - y: integer, yes
  - floor_id: integer, yes
  - free: boolean, yes
  - serving: boolean, yes
  - booked: boolean, yes
  - dirty: boolean, yes
  - disable: boolean, yes
- FKs detalle
  - floor_id ? public.shop_floor

## public.shop_table_status — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - table_status: integer, yes

## public.shop_table_type — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - description: character varying, yes
  - name: character varying, yes

## public.table_booking_info — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - from_date: timestamp without time zone, yes
  - to_date: timestamp without time zone, yes
  - guest_count: integer, yes
  - status: character varying, yes
  - payment_status: character varying, yes
  - booking_confirm: character varying, yes
  - booking_charge: double precision, yes
  - remaining_balance: double precision, yes
  - paid_amount: double precision, yes
  - booking_id: character varying, yes
  - booking_type: character varying, yes
  - user_id: integer, yes
  - customer_id: integer, yes
- FKs detalle
  - customer_id ? public.customer
  - user_id ? public.users

## public.table_booking_mapping — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - booking_id: integer, no
  - table_id: integer, no
- FKs detalle
  - booking_id ? public.table_booking_info
  - table_id ? public.shop_table

## public.table_ticket_num — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - shop_table_status_id: integer, no
  - ticket_id: integer, yes
  - user_id: integer, yes
  - user_name: character varying, yes
- FKs detalle
  - shop_table_status_id ? public.shop_table_status

## public.table_type_relation — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 2
- Columnas (nombre: tipo, null)
  - table_id: integer, no
  - type_id: integer, no
- FKs detalle
  - type_id ? public.shop_table_type
  - table_id ? public.shop_table

## public.tax — ~ 2 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - rate: double precision, yes

## public.tax_group — ~ 0 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: character varying, no
  - name: character varying, no

## public.terminal — ~ 8 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, yes
  - terminal_key: character varying, yes
  - opening_balance: double precision, yes
  - current_balance: double precision, yes
  - has_cash_drawer: boolean, yes
  - in_use: boolean, yes
  - active: boolean, yes
  - location: character varying, yes
  - floor_id: integer, yes
  - assigned_user: integer, yes
- FKs detalle
  - assigned_user ? public.users

## public.terminal_printers — ~ 9 filas

- Flags: sin_timestamps

- PK: id
- FKs: 2
- Columnas (nombre: tipo, null)
  - id: integer, no
  - terminal_id: integer, yes
  - printer_name: character varying, yes
  - virtual_printer_id: integer, yes
- FKs detalle
  - virtual_printer_id ? public.virtual_printer
  - terminal_id ? public.terminal

## public.terminal_properties — ~ 4 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.terminal

## public.ticket — ~ 11633 filas

- Flags: sin_timestamps

- PK: id
- FKs: 6
- Columnas (nombre: tipo, null)
  - id: integer, no
  - global_id: character varying, yes
  - create_date: timestamp without time zone, yes
  - closing_date: timestamp without time zone, yes
  - active_date: timestamp without time zone, yes
  - deliveery_date: timestamp without time zone, yes
  - creation_hour: integer, yes
  - paid: boolean, yes
  - voided: boolean, yes
  - void_reason: character varying, yes
  - wasted: boolean, yes
  - refunded: boolean, yes
  - settled: boolean, yes
  - drawer_resetted: boolean, yes
  - sub_total: double precision, yes
  - total_discount: double precision, yes
  - total_tax: double precision, yes
  - total_price: double precision, yes
  - paid_amount: double precision, yes
  - due_amount: double precision, yes
  - advance_amount: double precision, yes
  - adjustment_amount: double precision, yes
  - number_of_guests: integer, yes
  - status: character varying, yes
  - bar_tab: boolean, yes
  - is_tax_exempt: boolean, yes
  - is_re_opened: boolean, yes
  - service_charge: double precision, yes
  - delivery_charge: double precision, yes
  - customer_id: integer, yes
  - delivery_address: character varying, yes
  - customer_pickeup: boolean, yes
  - delivery_extra_info: character varying, yes
  - ticket_type: character varying, yes
  - shift_id: integer, yes
  - owner_id: integer, yes
  - driver_id: integer, yes
  - gratuity_id: integer, yes
  - void_by_user: integer, yes
  - terminal_id: integer, yes
  - folio_date: date, yes
  - branch_key: text, yes
  - daily_folio: integer, yes
- FKs detalle
  - driver_id ? public.users
  - terminal_id ? public.terminal
  - owner_id ? public.users
  - void_by_user ? public.users
  - gratuity_id ? public.gratuity
  - shift_id ? public.shift

## public.ticket_discount — ~ 54 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - discount_id: integer, yes
  - name: character varying, yes
  - type: integer, yes
  - auto_apply: boolean, yes
  - minimum_amount: integer, yes
  - value: double precision, yes
  - ticket_id: integer, yes
- FKs detalle
  - ticket_id ? public.ticket

## public.ticket_item — ~ 20406 filas

- Flags: sin_timestamps

- PK: id
- FKs: 3
- Columnas (nombre: tipo, null)
  - id: integer, no
  - item_id: integer, yes
  - item_count: integer, yes
  - item_quantity: double precision, yes
  - item_name: character varying, yes
  - item_unit_name: character varying, yes
  - group_name: character varying, yes
  - category_name: character varying, yes
  - item_price: double precision, yes
  - item_tax_rate: double precision, yes
  - sub_total: double precision, yes
  - sub_total_without_modifiers: double precision, yes
  - discount: double precision, yes
  - tax_amount: double precision, yes
  - tax_amount_without_modifiers: double precision, yes
  - total_price: double precision, yes
  - total_price_without_modifiers: double precision, yes
  - beverage: boolean, yes
  - inventory_handled: boolean, yes
  - print_to_kitchen: boolean, yes
  - treat_as_seat: boolean, yes
  - seat_number: integer, yes
  - fractional_unit: boolean, yes
  - has_modiiers: boolean, yes
  - printed_to_kitchen: boolean, yes
  - status: character varying, yes
  - stock_amount_adjusted: boolean, yes
  - pizza_type: boolean, yes
  - size_modifier_id: integer, yes
  - ticket_id: integer, yes
  - pg_id: integer, yes
  - pizza_section_mode: integer, yes
- FKs detalle
  - size_modifier_id ? public.ticket_item_modifier
  - ticket_id ? public.ticket
  - pg_id ? public.printer_group

## public.ticket_item_addon_relation — ~ 0 filas

- Flags: sin_timestamps

- PK: ticket_item_id, list_order
- FKs: 2
- Columnas (nombre: tipo, null)
  - ticket_item_id: integer, no
  - modifier_id: integer, no
  - list_order: integer, no
- FKs detalle
  - modifier_id ? public.ticket_item_modifier
  - ticket_item_id ? public.ticket_item

## public.ticket_item_cooking_instruction — ~ 10989 filas

- Flags: sin_timestamps

- PK: ticket_item_id, item_order
- FKs: 1
- Columnas (nombre: tipo, null)
  - ticket_item_id: integer, no
  - description: character varying, yes
  - printedtokitchen: boolean, yes
  - item_order: integer, no
- FKs detalle
  - ticket_item_id ? public.ticket_item

## public.ticket_item_discount — ~ 146 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - discount_id: integer, yes
  - name: character varying, yes
  - type: integer, yes
  - auto_apply: boolean, yes
  - minimum_quantity: integer, yes
  - value: double precision, yes
  - amount: double precision, yes
  - ticket_itemid: integer, yes
- FKs detalle
  - ticket_itemid ? public.ticket_item

## public.ticket_item_modifier — ~ 11816 filas

- Flags: sin_timestamps

- PK: id
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - item_id: integer, yes
  - group_id: integer, yes
  - item_count: integer, yes
  - modifier_name: character varying, yes
  - modifier_price: double precision, yes
  - modifier_tax_rate: double precision, yes
  - modifier_type: integer, yes
  - subtotal_price: double precision, yes
  - total_price: double precision, yes
  - tax_amount: double precision, yes
  - info_only: boolean, yes
  - section_name: character varying, yes
  - multiplier_name: character varying, yes
  - print_to_kitchen: boolean, yes
  - section_wise_pricing: boolean, yes
  - status: character varying, yes
  - printed_to_kitchen: boolean, yes
  - ticket_item_id: integer, yes
- FKs detalle
  - ticket_item_id ? public.ticket_item

## public.ticket_item_modifier_relation — ~ 11816 filas

- Flags: sin_timestamps

- PK: ticket_item_id, list_order
- FKs: 2
- Columnas (nombre: tipo, null)
  - ticket_item_id: integer, no
  - modifier_id: integer, no
  - list_order: integer, no
- FKs detalle
  - ticket_item_id ? public.ticket_item
  - modifier_id ? public.ticket_item_modifier

## public.ticket_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.ticket

## public.ticket_table_num — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - ticket_id: integer, no
  - table_id: integer, yes
- FKs detalle
  - ticket_id ? public.ticket

## public.transaction_properties — ~ 0 filas

- Flags: sin_timestamps

- PK: id, property_name
- FKs: 1
- Columnas (nombre: tipo, null)
  - id: integer, no
  - property_value: character varying, yes
  - property_name: character varying, no
- FKs detalle
  - id ? public.transactions

## public.transactions — ~ 11632 filas

- Flags: sin_timestamps

- PK: id
- FKs: 5
- Columnas (nombre: tipo, null)
  - id: integer, no
  - payment_type: character varying, no
  - global_id: character varying, yes
  - transaction_time: timestamp without time zone, yes
  - amount: double precision, yes
  - tips_amount: double precision, yes
  - tips_exceed_amount: double precision, yes
  - tender_amount: double precision, yes
  - transaction_type: character varying, no
  - custom_payment_name: character varying, yes
  - custom_payment_ref: character varying, yes
  - custom_payment_field_name: character varying, yes
  - payment_sub_type: character varying, no
  - captured: boolean, yes
  - voided: boolean, yes
  - authorizable: boolean, yes
  - card_holder_name: character varying, yes
  - card_number: character varying, yes
  - card_auth_code: character varying, yes
  - card_type: character varying, yes
  - card_transaction_id: character varying, yes
  - card_merchant_gateway: character varying, yes
  - card_reader: character varying, yes
  - card_aid: character varying, yes
  - card_arqc: character varying, yes
  - card_ext_data: character varying, yes
  - gift_cert_number: character varying, yes
  - gift_cert_face_value: double precision, yes
  - gift_cert_paid_amount: double precision, yes
  - gift_cert_cash_back_amount: double precision, yes
  - drawer_resetted: boolean, yes
  - note: character varying, yes
  - terminal_id: integer, yes
  - ticket_id: integer, yes
  - user_id: integer, yes
  - payout_reason_id: integer, yes
  - payout_recepient_id: integer, yes
- FKs detalle
  - user_id ? public.users
  - payout_recepient_id ? public.payout_recepients
  - terminal_id ? public.terminal
  - ticket_id ? public.ticket
  - payout_reason_id ? public.payout_reasons

## public.user_permission — ~ 27 filas

- Flags: sin_timestamps

- PK: name
- FKs: N/A
- Columnas (nombre: tipo, null)
  - name: character varying, no

## public.user_type — ~ 4 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - p_name: character varying, yes

## public.user_user_permission — ~ 69 filas

- Flags: sin_timestamps

- PK: permissionid, elt
- FKs: 2
- Columnas (nombre: tipo, null)
  - permissionid: integer, no
  - elt: character varying, no
- FKs detalle
  - permissionid ? public.user_type
  - elt ? public.user_permission

## public.users — ~ 9 filas

- Flags: sin_timestamps

- PK: auto_id
- FKs: 3
- Columnas (nombre: tipo, null)
  - auto_id: integer, no
  - user_id: integer, yes
  - user_pass: character varying, no
  - first_name: character varying, yes
  - last_name: character varying, yes
  - ssn: character varying, yes
  - cost_per_hour: double precision, yes
  - clocked_in: boolean, yes
  - last_clock_in_time: timestamp without time zone, yes
  - last_clock_out_time: timestamp without time zone, yes
  - phone_no: character varying, yes
  - is_driver: boolean, yes
  - available_for_delivery: boolean, yes
  - active: boolean, yes
  - shift_id: integer, yes
  - currentterminal: integer, yes
  - n_user_type: integer, yes
- FKs detalle
  - shift_id ? public.shift
  - currentterminal ? public.terminal
  - n_user_type ? public.user_type

## public.virtual_printer — ~ 4 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - name: character varying, no
  - type: integer, yes
  - priority: integer, yes
  - enabled: boolean, yes

## public.virtualprinter_order_type — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: 1
- Columnas (nombre: tipo, null)
  - printer_id: integer, no
  - order_type: character varying, yes
- FKs detalle
  - printer_id ? public.virtual_printer

## public.void_reasons — ~ 10 filas

- Flags: sin_timestamps

- PK: id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, no
  - reason_text: character varying, yes

## public.zip_code_vs_delivery_charge — ~ 0 filas

- Flags: sin_timestamps

- PK: auto_id
- FKs: N/A
- Columnas (nombre: tipo, null)
  - auto_id: integer, no
  - zip_code: character varying, no
  - delivery_charge: double precision, no

## public.kds_orders_enhanced — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - kitchen_ticket_id: integer, yes
  - ticket_id: integer, yes
  - kds_created_at: timestamp without time zone, yes
  - sequence_number: integer, yes
  - daily_folio: integer, yes
  - folio_date: date, yes
  - branch_key: text, yes
  - folio_display: text, yes
  - number_of_guests: integer, yes
  - ticket_type: character varying, yes
  - terminal_name: character varying, yes
  - prioridad_voceo: text, yes

## public.ticket_folio_complete — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - id: integer, yes
  - daily_folio: integer, yes
  - folio_date: date, yes
  - branch_key: text, yes
  - total_price: double precision, yes
  - paid_amount: double precision, yes
  - create_date: timestamp without time zone, yes
  - folio_date_txt: text, yes
  - folio_display: text, yes
  - sucursal_completa: character varying, yes
  - terminal_name: character varying, yes
  - periodo_mes: text, yes
  - hora_venta: double precision, yes
  - dia_semana: double precision, yes
  - status_simple: text, yes

## public.vw_reconciliation_status — ~ 0 filas

- Flags: sin_timestamps

- PK: N/A
- FKs: N/A
- Columnas (nombre: tipo, null)
  - report_date: date, yes
  - terminal_id: integer, yes
  - tickets_count: bigint, yes
  - transactions_count: bigint, yes
  - correct_total: numeric, yes
  - current_system_total: numeric, yes
  - discrepancy: numeric, yes
  - discrepancy_percent: numeric, yes

