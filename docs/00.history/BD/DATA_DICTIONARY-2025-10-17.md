# Diccionario de Datos

- Fecha de generación: 2025-10-17
- Esquemas analizados: selemti, public
- Search path: selemti, public

## Diagrama ER - esquema public
```mermaid
erDiagram
    PUBLIC_ACTION_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) action_time
        character varying(255) action_name
        character varying(255) description
        integer(32,0) user_id
    }
    PUBLIC_ATTENDENCE_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) clock_in_time
        timestamp without time zone(6) clock_out_time
        smallint(16,0) clock_in_hour
        smallint(16,0) clock_out_hour
        boolean clocked_out
        integer(32,0) user_id
        integer(32,0) shift_id
        integer(32,0) terminal_id
    }
    PUBLIC_CASH_DRAWER {
        integer(32,0) id PK
        integer(32,0) terminal_id
    }
    PUBLIC_CASH_DRAWER_RESET_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) reset_time
        integer(32,0) user_id
    }
    PUBLIC_COOKING_INSTRUCTION {
        integer(32,0) id PK
        character varying(60) description
    }
    PUBLIC_COUPON_AND_DISCOUNT {
        integer(32,0) id PK
        character varying(120) name
        integer(32,0) type
        character varying(120) barcode
        integer(32,0) qualification_type
        boolean apply_to_all
        integer(32,0) minimum_buy
        integer(32,0) maximum_off
        double precision(53) value
        timestamp without time zone(6) expiry_date
        boolean enabled
        boolean auto_apply
        boolean modifiable
        boolean never_expire
        character varying(36) uuid
    }
    PUBLIC_CURRENCY {
        integer(32,0) id PK
        character varying(20) code
        character varying(30) name
        character varying(10) symbol
        double precision(53) exchange_rate
        integer(32,0) decimal_places
        double precision(53) tolerance
        double precision(53) buy_price
        double precision(53) sales_price
        boolean main
    }
    PUBLIC_CURRENCY_BALANCE {
        integer(32,0) id PK
        double precision(53) balance
        integer(32,0) currency_id
        integer(32,0) cash_drawer_id
        integer(32,0) dpr_id
    }
    PUBLIC_CUSTOM_PAYMENT {
        integer(32,0) id PK
        character varying(60) name
        boolean required_ref_number
        character varying(60) ref_number_field_name
    }
    PUBLIC_CUSTOMER {
        integer(32,0) auto_id PK
        character varying(30) loyalty_no
        integer(32,0) loyalty_point
        character varying(60) social_security_number
        bytea picture
        character varying(30) homephone_no
        character varying(30) mobile_no
        character varying(30) workphone_no
        character varying(40) email
        character varying(60) salutation
        character varying(60) first_name
        character varying(60) last_name
        character varying(120) name
        character varying(16) dob
        character varying(30) ssn
        character varying(220) address
        character varying(30) city
        character varying(30) state
        character varying(10) zip_code
        character varying(30) country
        boolean vip
        double precision(53) credit_limit
        double precision(53) credit_spent
        character varying(30) credit_card_no
        character varying(255) note
    }
    PUBLIC_CUSTOMER_PROPERTIES {
        integer(32,0) id PK
        character varying(255) property_value
        character varying(255) property_name PK
    }
    PUBLIC_DAILY_FOLIO_COUNTER {
        date folio_date PK
        text branch_key PK
        integer(32,0) last_value
    }
    PUBLIC_DATA_UPDATE_INFO {
        integer(32,0) id PK
        timestamp without time zone(6) last_update_time
    }
    PUBLIC_DELIVERY_ADDRESS {
        integer(32,0) id PK
        character varying(320) address
        character varying(10) phone_extension
        character varying(30) room_no
        double precision(53) distance
        integer(32,0) customer_id
    }
    PUBLIC_DELIVERY_CHARGE {
        integer(32,0) id PK
        character varying(220) name
        character varying(20) zip_code
        double precision(53) start_range
        double precision(53) end_range
        double precision(53) charge_amount
    }
    PUBLIC_DELIVERY_CONFIGURATION {
        integer(32,0) id PK
        character varying(20) unit_name
        character varying(8) unit_symbol
        boolean charge_by_zip_code
    }
    PUBLIC_DELIVERY_INSTRUCTION {
        integer(32,0) id PK
        character varying(220) notes
        integer(32,0) customer_no
    }
    PUBLIC_DRAWER_ASSIGNED_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) time
        character varying(60) operation
        integer(32,0) a_user
    }
    PUBLIC_DRAWER_PULL_REPORT {
        integer(32,0) id PK
        timestamp without time zone(6) report_time
        character varying(15) reg
        integer(32,0) ticket_count
        double precision(53) begin_cash
        double precision(53) net_sales
        double precision(53) sales_tax
        double precision(53) cash_tax
        double precision(53) total_revenue
        double precision(53) gross_receipts
        integer(32,0) giftcertreturncount
        double precision(53) giftcertreturnamount
        double precision(53) giftcertchangeamount
        integer(32,0) cash_receipt_no
        double precision(53) cash_receipt_amount
        integer(32,0) credit_card_receipt_no
        double precision(53) credit_card_receipt_amount
        integer(32,0) debit_card_receipt_no
        double precision(53) debit_card_receipt_amount
        integer(32,0) refund_receipt_count
        double precision(53) refund_amount
        double precision(53) receipt_differential
        double precision(53) cash_back
        double precision(53) cash_tips
        double precision(53) charged_tips
        double precision(53) tips_paid
        double precision(53) tips_differential
        integer(32,0) pay_out_no
        double precision(53) pay_out_amount
        integer(32,0) drawer_bleed_no
        double precision(53) drawer_bleed_amount
        double precision(53) drawer_accountable
        double precision(53) cash_to_deposit
        double precision(53) variance
        double precision(53) delivery_charge
        double precision(53) totalvoidwst
        double precision(53) totalvoid
        integer(32,0) totaldiscountcount
        double precision(53) totaldiscountamount
        double precision(53) totaldiscountsales
        integer(32,0) totaldiscountguest
        integer(32,0) totaldiscountpartysize
        integer(32,0) totaldiscountchecksize
        double precision(53) totaldiscountpercentage
        double precision(53) totaldiscountratio
        integer(32,0) user_id
        integer(32,0) terminal_id
    }
    PUBLIC_DRAWER_PULL_REPORT_VOIDTICKETS {
        integer(32,0) dpreport_id
        integer(32,0) code
        character varying(255) reason
        character varying(255) hast
        integer(32,0) quantity
        double precision(53) amount
    }
    PUBLIC_EMPLOYEE_IN_OUT_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) out_time
        timestamp without time zone(6) in_time
        smallint(16,0) out_hour
        smallint(16,0) in_hour
        boolean clock_out
        integer(32,0) user_id
        integer(32,0) shift_id
        integer(32,0) terminal_id
    }
    PUBLIC_GLOBAL_CONFIG {
        integer(32,0) id PK
        character varying(60) pos_key
        character varying(220) pos_value
    }
    PUBLIC_GRATUITY {
        integer(32,0) id PK
        double precision(53) amount
        boolean paid
        boolean refunded
        integer(32,0) ticket_id
        integer(32,0) owner_id
        integer(32,0) terminal_id
    }
    PUBLIC_GROUP_TAXES {
        character varying(128) group_id
        integer(32,0) elt
    }
    PUBLIC_GUEST_CHECK_PRINT {
        integer(32,0) id PK
        integer(32,0) ticket_id
        character varying(255) table_no
        double precision(53) ticket_total
        timestamp without time zone(6) print_time
        integer(32,0) user_id
    }
    PUBLIC_INVENTORY_GROUP {
        integer(32,0) id PK
        character varying(60) name
        boolean visible
    }
    PUBLIC_INVENTORY_ITEM {
        integer(32,0) id PK
        timestamp without time zone(6) create_time
        timestamp without time zone(6) last_update_date
        character varying(60) name
        character varying(30) package_barcode
        character varying(30) unit_barcode
        double precision(53) unit_per_package
        integer(32,0) sort_order
        integer(32,0) package_reorder_level
        integer(32,0) package_replenish_level
        character varying(255) description
        double precision(53) average_package_price
        double precision(53) total_unit_packages
        double precision(53) total_recepie_units
        double precision(53) unit_purchase_price
        double precision(53) unit_selling_price
        boolean visible
        integer(32,0) punit_id
        integer(32,0) recipe_unit_id
        integer(32,0) item_group_id
        integer(32,0) item_location_id
        integer(32,0) item_vendor_id
        integer(32,0) total_packages
    }
    PUBLIC_INVENTORY_LOCATION {
        integer(32,0) id PK
        character varying(60) name
        integer(32,0) sort_order
        boolean visible
        integer(32,0) warehouse_id
    }
    PUBLIC_INVENTORY_META_CODE {
        integer(32,0) id PK
        character varying(255) type
        character varying(255) code_text
        integer(32,0) code_no
        character varying(255) description
    }
    PUBLIC_INVENTORY_TRANSACTION {
        integer(32,0) id PK
        timestamp without time zone(6) transaction_date
        double precision(53) unit_quantity
        double precision(53) unit_price
        character varying(255) remark
        integer(32,0) tran_type
        integer(32,0) reference_id
        integer(32,0) item_id
        integer(32,0) vendor_id
        integer(32,0) from_warehouse_id
        integer(32,0) to_warehouse_id
        integer(32,0) quantity
    }
    PUBLIC_INVENTORY_UNIT {
        integer(32,0) id PK
        character varying(255) short_name
        character varying(255) long_name
        character varying(255) alt_name
        character varying(255) conv_factor1
        character varying(255) conv_factor2
        character varying(255) conv_factor3
    }
    PUBLIC_INVENTORY_VENDOR {
        integer(32,0) id PK
        character varying(60) name
        boolean visible
        character varying(120) address
        character varying(60) city
        character varying(60) state
        character varying(60) zip
        character varying(60) country
        character varying(60) email
        character varying(60) phone
        character varying(60) fax
    }
    PUBLIC_INVENTORY_WAREHOUSE {
        integer(32,0) id PK
        character varying(60) name
        boolean visible
    }
    PUBLIC_ITEM_ORDER_TYPE {
        integer(32,0) menu_item_id
        integer(32,0) order_type_id
    }
    PUBLIC_KDS_READY_LOG {
        integer(32,0) ticket_id PK
        timestamp without time zone(6) notified_at
    }
    PUBLIC_KIT_TICKET_TABLE_NUM {
        integer(32,0) kit_ticket_id
        integer(32,0) table_id
    }
    PUBLIC_KITCHEN_TICKET {
        integer(32,0) id PK
        integer(32,0) ticket_id
        timestamp without time zone(6) create_date
        timestamp without time zone(6) close_date
        boolean voided
        integer(32,0) sequence_number
        character varying(30) status
        character varying(30) server_name
        character varying(20) ticket_type
        integer(32,0) pg_id
    }
    PUBLIC_KITCHEN_TICKET_ITEM {
        integer(32,0) id PK
        boolean cookable
        integer(32,0) ticket_item_id
        integer(32,0) ticket_item_modifier_id
        character varying(255) menu_item_code
        character varying(120) menu_item_name
        integer(32,0) menu_item_group_id
        character varying(120) menu_item_group_name
        integer(32,0) quantity
        double precision(53) fractional_quantity
        boolean fractional_unit
        character varying(20) unit_name
        integer(32,0) sort_order
        boolean voided
        character varying(30) status
        integer(32,0) kithen_ticket_id
        integer(32,0) item_order
    }
    PUBLIC_MENU_CATEGORY {
        integer(32,0) id PK
        character varying(120) name
        character varying(120) translated_name
        boolean visible
        boolean beverage
        integer(32,0) sort_order
        integer(32,0) btn_color
        integer(32,0) text_color
    }
    PUBLIC_MENU_GROUP {
        integer(32,0) id PK
        character varying(120) name
        character varying(120) translated_name
        boolean visible
        integer(32,0) sort_order
        integer(32,0) btn_color
        integer(32,0) text_color
        integer(32,0) category_id
    }
    PUBLIC_MENU_ITEM {
        integer(32,0) id PK
        character varying(120) name
        character varying(255) description
        character varying(20) unit_name
        character varying(120) translated_name
        character varying(120) barcode
        double precision(53) buy_price
        double precision(53) stock_amount
        double precision(53) price
        double precision(53) discount_rate
        boolean visible
        boolean disable_when_stock_amount_is_zero
        integer(32,0) sort_order
        integer(32,0) btn_color
        integer(32,0) text_color
        bytea image
        boolean show_image_only
        boolean fractional_unit
        boolean pizza_type
        integer(32,0) default_sell_portion
        integer(32,0) group_id
        character varying(128) tax_group_id
        integer(32,0) recepie
        integer(32,0) pg_id
        integer(32,0) tax_id
    }
    PUBLIC_MENU_ITEM_PROPERTIES {
        integer(32,0) menu_item_id PK
        character varying(100) property_value
        character varying(255) property_name PK
    }
    PUBLIC_MENU_ITEM_SIZE {
        integer(32,0) id PK
        character varying(60) name
        character varying(60) translated_name
        character varying(120) description
        integer(32,0) sort_order
        double precision(53) size_in_inch
        boolean default_size
    }
    PUBLIC_MENU_ITEM_TERMINAL_REF {
        integer(32,0) menu_item_id
        integer(32,0) terminal_id
    }
    PUBLIC_MENU_MODIFIER {
        integer(32,0) id PK
        character varying(120) name
        character varying(120) translated_name
        double precision(53) price
        double precision(53) extra_price
        integer(32,0) sort_order
        integer(32,0) btn_color
        integer(32,0) text_color
        boolean enable
        boolean fixed_price
        boolean print_to_kitchen
        boolean section_wise_pricing
        boolean pizza_modifier
        integer(32,0) group_id
        integer(32,0) tax_id
    }
    PUBLIC_MENU_MODIFIER_GROUP {
        integer(32,0) id PK
        character varying(60) name
        character varying(60) translated_name
        boolean enabled
        boolean exclusived
        boolean required
    }
    PUBLIC_MENU_MODIFIER_PROPERTIES {
        integer(32,0) menu_modifier_id PK
        character varying(100) property_value
        character varying(255) property_name PK
    }
    PUBLIC_MENUCATEGORY_DISCOUNT {
        integer(32,0) discount_id
        integer(32,0) menucategory_id
    }
    PUBLIC_MENUGROUP_DISCOUNT {
        integer(32,0) discount_id
        integer(32,0) menugroup_id
    }
    PUBLIC_MENUITEM_DISCOUNT {
        integer(32,0) discount_id
        integer(32,0) menuitem_id
    }
    PUBLIC_MENUITEM_MODIFIERGROUP {
        integer(32,0) id PK
        integer(32,0) min_quantity
        integer(32,0) max_quantity
        integer(32,0) sort_order
        integer(32,0) modifier_group
        integer(32,0) menuitem_modifiergroup_id
    }
    PUBLIC_MENUITEM_PIZZAPIRCE {
        integer(32,0) menu_item_id
        integer(32,0) pizza_price_id
    }
    PUBLIC_MENUITEM_SHIFT {
        integer(32,0) id PK
        double precision(53) shift_price
        integer(32,0) shift_id
        integer(32,0) menuitem_id
    }
    PUBLIC_MENUMODIFIER_PIZZAMODIFIERPRICE {
        integer(32,0) menumodifier_id
        integer(32,0) pizzamodifierprice_id
    }
    PUBLIC_MIGRATIONS {
        integer(32,0) id PK
        character varying(255) migration
        integer(32,0) batch
    }
    PUBLIC_MODIFIER_MULTIPLIER_PRICE {
        integer(32,0) id PK
        double precision(53) price
        character varying(20) multiplier_id
        integer(32,0) menumodifier_id
        integer(32,0) pizza_modifier_price_id
    }
    PUBLIC_MULTIPLIER {
        character varying(20) name PK
        character varying(20) ticket_prefix
        double precision(53) rate
        integer(32,0) sort_order
        boolean default_multiplier
        boolean main
        integer(32,0) btn_color
        integer(32,0) text_color
    }
    PUBLIC_ORDER_TYPE {
        integer(32,0) id PK
        character varying(120) name
        boolean enabled
        boolean show_table_selection
        boolean show_guest_selection
        boolean should_print_to_kitchen
        boolean prepaid
        boolean close_on_paid
        boolean required_customer_data
        boolean delivery
        boolean show_item_barcode
        boolean show_in_login_screen
        boolean consolidate_tiems_in_receipt
        boolean allow_seat_based_order
        boolean hide_item_with_empty_inventory
        boolean has_forhere_and_togo
        boolean pre_auth_credit_card
        boolean bar_tab
        boolean retail_order
        boolean show_price_on_button
        boolean show_stock_count_on_button
        boolean show_unit_price_in_ticket_grid
        text properties
    }
    PUBLIC_PACKAGING_UNIT {
        integer(32,0) id PK
        character varying(30) name
        character varying(10) short_name
        double precision(53) factor
        boolean baseunit
        character varying(30) dimension
    }
    PUBLIC_PAYOUT_REASONS {
        integer(32,0) id PK
        character varying(255) reason
    }
    PUBLIC_PAYOUT_RECEPIENTS {
        integer(32,0) id PK
        character varying(255) name
    }
    PUBLIC_PIZZA_CRUST {
        integer(32,0) id PK
        character varying(60) name
        character varying(60) translated_name
        character varying(120) description
        integer(32,0) sort_order
        boolean default_crust
    }
    PUBLIC_PIZZA_MODIFIER_PRICE {
        integer(32,0) id PK
        integer(32,0) item_size
    }
    PUBLIC_PIZZA_PRICE {
        integer(32,0) id PK
        double precision(53) price
        integer(32,0) menu_item_size
        integer(32,0) crust
        integer(32,0) order_type
    }
    PUBLIC_PRINTER_CONFIGURATION {
        integer(32,0) id PK
        character varying(255) receipt_printer
        character varying(255) kitchen_printer
        boolean prwts
        boolean prwtp
        boolean pkwts
        boolean pkwtp
        boolean unpft
        boolean unpfk
    }
    PUBLIC_PRINTER_GROUP {
        integer(32,0) id PK
        character varying(60) name
        boolean is_default
    }
    PUBLIC_PRINTER_GROUP_PRINTERS {
        integer(32,0) printer_id
        character varying(255) printer_name
    }
    PUBLIC_PURCHASE_ORDER {
        integer(32,0) id PK
        character varying(30) order_id
        character varying(30) name
    }
    PUBLIC_RECEPIE {
        integer(32,0) id PK
        integer(32,0) menu_item
    }
    PUBLIC_RECEPIE_ITEM {
        integer(32,0) id PK
        double precision(53) percentage
        boolean inventory_deductable
        integer(32,0) inventory_item
        integer(32,0) recepie_id
    }
    PUBLIC_RESTAURANT {
        integer(32,0) id PK
        integer(32,0) unique_id
        character varying(120) name
        character varying(60) address_line1
        character varying(60) address_line2
        character varying(60) address_line3
        character varying(10) zip_code
        character varying(16) telephone
        integer(32,0) capacity
        integer(32,0) tables
        character varying(20) cname
        character varying(10) csymbol
        double precision(53) sc_percentage
        double precision(53) gratuity_percentage
        character varying(60) ticket_footer
        boolean price_includes_tax
        boolean allow_modifier_max_exceed
    }
    PUBLIC_RESTAURANT_PROPERTIES {
        integer(32,0) id PK
        character varying(1000) property_value
        character varying(255) property_name PK
    }
    PUBLIC_SHIFT {
        integer(32,0) id PK
        character varying(60) name
        timestamp without time zone(6) start_time
        timestamp without time zone(6) end_time
        bigint(64,0) shift_len
    }
    PUBLIC_SHOP_FLOOR {
        integer(32,0) id PK
        character varying(60) name
        boolean occupied
        oid image
    }
    PUBLIC_SHOP_FLOOR_TEMPLATE {
        integer(32,0) id PK
        character varying(60) name
        boolean default_floor
        boolean main
        integer(32,0) floor_id
    }
    PUBLIC_SHOP_FLOOR_TEMPLATE_PROPERTIES {
        integer(32,0) id PK
        character varying(60) property_value
        character varying(255) property_name PK
    }
    PUBLIC_SHOP_TABLE {
        integer(32,0) id PK
        character varying(20) name
        character varying(60) description
        integer(32,0) capacity
        integer(32,0) x
        integer(32,0) y
        integer(32,0) floor_id
        boolean free
        boolean serving
        boolean booked
        boolean dirty
        boolean disable
    }
    PUBLIC_SHOP_TABLE_STATUS {
        integer(32,0) id PK
        integer(32,0) table_status
    }
    PUBLIC_SHOP_TABLE_TYPE {
        integer(32,0) id PK
        character varying(120) description
        character varying(40) name
    }
    PUBLIC_TABLE_BOOKING_INFO {
        integer(32,0) id PK
        timestamp without time zone(6) from_date
        timestamp without time zone(6) to_date
        integer(32,0) guest_count
        character varying(30) status
        character varying(30) payment_status
        character varying(30) booking_confirm
        double precision(53) booking_charge
        double precision(53) remaining_balance
        double precision(53) paid_amount
        character varying(30) booking_id
        character varying(30) booking_type
        integer(32,0) user_id
        integer(32,0) customer_id
    }
    PUBLIC_TABLE_BOOKING_MAPPING {
        integer(32,0) booking_id
        integer(32,0) table_id
    }
    PUBLIC_TABLE_TICKET_NUM {
        integer(32,0) shop_table_status_id
        integer(32,0) ticket_id
        integer(32,0) user_id
        character varying(30) user_name
    }
    PUBLIC_TABLE_TYPE_RELATION {
        integer(32,0) table_id
        integer(32,0) type_id
    }
    PUBLIC_TAX {
        integer(32,0) id PK
        character varying(20) name
        double precision(53) rate
    }
    PUBLIC_TAX_GROUP {
        character varying(128) id PK
        character varying(20) name
    }
    PUBLIC_TERMINAL {
        integer(32,0) id PK
        character varying(60) name
        character varying(120) terminal_key
        double precision(53) opening_balance
        double precision(53) current_balance
        boolean has_cash_drawer
        boolean in_use
        boolean active
        character varying(320) location
        integer(32,0) floor_id
        integer(32,0) assigned_user
    }
    PUBLIC_TERMINAL_PRINTERS {
        integer(32,0) id PK
        integer(32,0) terminal_id
        character varying(60) printer_name
        integer(32,0) virtual_printer_id
    }
    PUBLIC_TERMINAL_PROPERTIES {
        integer(32,0) id PK
        character varying(255) property_value
        character varying(255) property_name PK
    }
    PUBLIC_TICKET {
        integer(32,0) id PK
        character varying(16) global_id
        timestamp without time zone(6) create_date
        timestamp without time zone(6) closing_date
        timestamp without time zone(6) active_date
        timestamp without time zone(6) deliveery_date
        integer(32,0) creation_hour
        boolean paid
        boolean voided
        character varying(255) void_reason
        boolean wasted
        boolean refunded
        boolean settled
        boolean drawer_resetted
        double precision(53) sub_total
        double precision(53) total_discount
        double precision(53) total_tax
        double precision(53) total_price
        double precision(53) paid_amount
        double precision(53) due_amount
        double precision(53) advance_amount
        double precision(53) adjustment_amount
        integer(32,0) number_of_guests
        character varying(30) status
        boolean bar_tab
        boolean is_tax_exempt
        boolean is_re_opened
        double precision(53) service_charge
        double precision(53) delivery_charge
        integer(32,0) customer_id
        character varying(120) delivery_address
        boolean customer_pickeup
        character varying(255) delivery_extra_info
        character varying(20) ticket_type
        integer(32,0) shift_id
        integer(32,0) owner_id
        integer(32,0) driver_id
        integer(32,0) gratuity_id
        integer(32,0) void_by_user
        integer(32,0) terminal_id
        date folio_date
        text branch_key
        integer(32,0) daily_folio
    }
    PUBLIC_TICKET_DISCOUNT {
        integer(32,0) id PK
        integer(32,0) discount_id
        character varying(30) name
        integer(32,0) type
        boolean auto_apply
        integer(32,0) minimum_amount
        double precision(53) value
        integer(32,0) ticket_id
    }
    PUBLIC_TICKET_ITEM {
        integer(32,0) id PK
        integer(32,0) item_id
        integer(32,0) item_count
        double precision(53) item_quantity
        character varying(120) item_name
        character varying(20) item_unit_name
        character varying(120) group_name
        character varying(120) category_name
        double precision(53) item_price
        double precision(53) item_tax_rate
        double precision(53) sub_total
        double precision(53) sub_total_without_modifiers
        double precision(53) discount
        double precision(53) tax_amount
        double precision(53) tax_amount_without_modifiers
        double precision(53) total_price
        double precision(53) total_price_without_modifiers
        boolean beverage
        boolean inventory_handled
        boolean print_to_kitchen
        boolean treat_as_seat
        integer(32,0) seat_number
        boolean fractional_unit
        boolean has_modiiers
        boolean printed_to_kitchen
        character varying(255) status
        boolean stock_amount_adjusted
        boolean pizza_type
        integer(32,0) size_modifier_id
        integer(32,0) ticket_id
        integer(32,0) pg_id
        integer(32,0) pizza_section_mode
    }
    PUBLIC_TICKET_ITEM_ADDON_RELATION {
        integer(32,0) ticket_item_id PK
        integer(32,0) modifier_id
        integer(32,0) list_order PK
    }
    PUBLIC_TICKET_ITEM_COOKING_INSTRUCTION {
        integer(32,0) ticket_item_id PK
        character varying(60) description
        boolean printedtokitchen
        integer(32,0) item_order PK
    }
    PUBLIC_TICKET_ITEM_DISCOUNT {
        integer(32,0) id PK
        integer(32,0) discount_id
        character varying(30) name
        integer(32,0) type
        boolean auto_apply
        integer(32,0) minimum_quantity
        double precision(53) value
        double precision(53) amount
        integer(32,0) ticket_itemid
    }
    PUBLIC_TICKET_ITEM_MODIFIER {
        integer(32,0) id PK
        integer(32,0) item_id
        integer(32,0) group_id
        integer(32,0) item_count
        character varying(120) modifier_name
        double precision(53) modifier_price
        double precision(53) modifier_tax_rate
        integer(32,0) modifier_type
        double precision(53) subtotal_price
        double precision(53) total_price
        double precision(53) tax_amount
        boolean info_only
        character varying(20) section_name
        character varying(20) multiplier_name
        boolean print_to_kitchen
        boolean section_wise_pricing
        character varying(10) status
        boolean printed_to_kitchen
        integer(32,0) ticket_item_id
    }
    PUBLIC_TICKET_ITEM_MODIFIER_RELATION {
        integer(32,0) ticket_item_id PK
        integer(32,0) modifier_id
        integer(32,0) list_order PK
    }
    PUBLIC_TICKET_PROPERTIES {
        integer(32,0) id PK
        character varying(1000) property_value
        character varying(255) property_name PK
    }
    PUBLIC_TICKET_TABLE_NUM {
        integer(32,0) ticket_id
        integer(32,0) table_id
    }
    PUBLIC_TRANSACTION_PROPERTIES {
        integer(32,0) id PK
        character varying(255) property_value
        character varying(255) property_name PK
    }
    PUBLIC_TRANSACTIONS {
        integer(32,0) id PK
        character varying(30) payment_type
        character varying(16) global_id
        timestamp without time zone(6) transaction_time
        double precision(53) amount
        double precision(53) tips_amount
        double precision(53) tips_exceed_amount
        double precision(53) tender_amount
        character varying(30) transaction_type
        character varying(60) custom_payment_name
        character varying(120) custom_payment_ref
        character varying(60) custom_payment_field_name
        character varying(40) payment_sub_type
        boolean captured
        boolean voided
        boolean authorizable
        character varying(60) card_holder_name
        character varying(40) card_number
        character varying(30) card_auth_code
        character varying(20) card_type
        character varying(255) card_transaction_id
        character varying(60) card_merchant_gateway
        character varying(30) card_reader
        character varying(120) card_aid
        character varying(120) card_arqc
        character varying(255) card_ext_data
        character varying(64) gift_cert_number
        double precision(53) gift_cert_face_value
        double precision(53) gift_cert_paid_amount
        double precision(53) gift_cert_cash_back_amount
        boolean drawer_resetted
        character varying(255) note
        integer(32,0) terminal_id
        integer(32,0) ticket_id
        integer(32,0) user_id
        integer(32,0) payout_reason_id
        integer(32,0) payout_recepient_id
    }
    PUBLIC_USER_PERMISSION {
        character varying(40) name PK
    }
    PUBLIC_USER_TYPE {
        integer(32,0) id PK
        character varying(60) p_name
    }
    PUBLIC_USER_USER_PERMISSION {
        integer(32,0) permissionid PK
        character varying(40) elt PK
    }
    PUBLIC_USERS {
        integer(32,0) auto_id PK
        integer(32,0) user_id
        character varying(16) user_pass
        character varying(30) first_name
        character varying(30) last_name
        character varying(30) ssn
        double precision(53) cost_per_hour
        boolean clocked_in
        timestamp without time zone(6) last_clock_in_time
        timestamp without time zone(6) last_clock_out_time
        character varying(20) phone_no
        boolean is_driver
        boolean available_for_delivery
        boolean active
        integer(32,0) shift_id
        integer(32,0) currentterminal
        integer(32,0) n_user_type
    }
    PUBLIC_VIRTUAL_PRINTER {
        integer(32,0) id PK
        character varying(60) name
        integer(32,0) type
        integer(32,0) priority
        boolean enabled
    }
    PUBLIC_VIRTUALPRINTER_ORDER_TYPE {
        integer(32,0) printer_id
        character varying(255) order_type
    }
    PUBLIC_VOID_REASONS {
        integer(32,0) id PK
        character varying(255) reason_text
    }
    PUBLIC_ZIP_CODE_VS_DELIVERY_CHARGE {
        integer(32,0) auto_id PK
        character varying(10) zip_code
        double precision(53) delivery_charge
    }
    PUBLIC_USERS ||--o{ PUBLIC_ACTION_HISTORY : "fk3f3af36b3e20ad51"
    PUBLIC_TERMINAL ||--o{ PUBLIC_ATTENDENCE_HISTORY : "fkdfe829a2ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_ATTENDENCE_HISTORY : "fkdfe829a3e20ad51"
    PUBLIC_SHIFT ||--o{ PUBLIC_ATTENDENCE_HISTORY : "fkdfe829a7660a5e3"
    PUBLIC_TERMINAL ||--o{ PUBLIC_CASH_DRAWER : "fk6221077d2ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_CASH_DRAWER_RESET_HISTORY : "fk719418223e20ad51"
    PUBLIC_CURRENCY ||--o{ PUBLIC_CURRENCY_BALANCE : "fk2cc0e08e28dd6c11"
    PUBLIC_CASH_DRAWER ||--o{ PUBLIC_CURRENCY_BALANCE : "fk2cc0e08e9006558"
    PUBLIC_DRAWER_PULL_REPORT ||--o{ PUBLIC_CURRENCY_BALANCE : "fk2cc0e08efb910735"
    PUBLIC_CUSTOMER ||--o{ PUBLIC_CUSTOMER_PROPERTIES : "fkd43068347bbccf0"
    PUBLIC_CUSTOMER ||--o{ PUBLIC_DELIVERY_ADDRESS : "fk29aca6899e1c3cf1"
    PUBLIC_CUSTOMER ||--o{ PUBLIC_DELIVERY_INSTRUCTION : "fk29d9ca39e1c3d97"
    PUBLIC_USERS ||--o{ PUBLIC_DRAWER_ASSIGNED_HISTORY : "fk5a823c91f1dd782b"
    PUBLIC_TERMINAL ||--o{ PUBLIC_DRAWER_PULL_REPORT : "fkaec362202ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_DRAWER_PULL_REPORT : "fkaec362203e20ad51"
    PUBLIC_DRAWER_PULL_REPORT ||--o{ PUBLIC_DRAWER_PULL_REPORT_VOIDTICKETS : "fk98cf9b143ef4cd9b"
    PUBLIC_TERMINAL ||--o{ PUBLIC_EMPLOYEE_IN_OUT_HISTORY : "fk6d5db9fa2ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_EMPLOYEE_IN_OUT_HISTORY : "fk6d5db9fa3e20ad51"
    PUBLIC_SHIFT ||--o{ PUBLIC_EMPLOYEE_IN_OUT_HISTORY : "fk6d5db9fa7660a5e3"
    PUBLIC_TICKET ||--o{ PUBLIC_GRATUITY : "fk34e4e3771df2d7f1"
    PUBLIC_TERMINAL ||--o{ PUBLIC_GRATUITY : "fk34e4e3772ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_GRATUITY : "fk34e4e377aa075d69"
    PUBLIC_TAX ||--o{ PUBLIC_GROUP_TAXES : "fkf8a37399d900aa01"
    PUBLIC_TAX_GROUP ||--o{ PUBLIC_GROUP_TAXES : "fkf8a37399eff11066"
    PUBLIC_USERS ||--o{ PUBLIC_GUEST_CHECK_PRINT : "fkce827c6f3e20ad51"
    PUBLIC_INVENTORY_GROUP ||--o{ PUBLIC_INVENTORY_ITEM : "fk7dc968362cd583c1"
    PUBLIC_PACKAGING_UNIT ||--o{ PUBLIC_INVENTORY_ITEM : "fk7dc968363525e956"
    PUBLIC_PACKAGING_UNIT ||--o{ PUBLIC_INVENTORY_ITEM : "fk7dc968366848d615"
    PUBLIC_INVENTORY_LOCATION ||--o{ PUBLIC_INVENTORY_ITEM : "fk7dc9683695e455d3"
    PUBLIC_INVENTORY_VENDOR ||--o{ PUBLIC_INVENTORY_ITEM : "fk7dc968369e60c333"
    PUBLIC_INVENTORY_WAREHOUSE ||--o{ PUBLIC_INVENTORY_LOCATION : "fk59073b58c46a9c15"
    PUBLIC_PURCHASE_ORDER ||--o{ PUBLIC_INVENTORY_TRANSACTION : "fkaf48f43b5b397c5"
    PUBLIC_INVENTORY_ITEM ||--o{ PUBLIC_INVENTORY_TRANSACTION : "fkaf48f43b96a3d6bf"
    PUBLIC_INVENTORY_VENDOR ||--o{ PUBLIC_INVENTORY_TRANSACTION : "fkaf48f43bd152c95f"
    PUBLIC_INVENTORY_WAREHOUSE ||--o{ PUBLIC_INVENTORY_TRANSACTION : "fkaf48f43beda09759"
    PUBLIC_INVENTORY_WAREHOUSE ||--o{ PUBLIC_INVENTORY_TRANSACTION : "fkaf48f43bff3f328a"
    PUBLIC_ORDER_TYPE ||--o{ PUBLIC_ITEM_ORDER_TYPE : "fke2b846573ac1d2e0"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_ITEM_ORDER_TYPE : "fke2b8465789fe23f0"
    PUBLIC_KITCHEN_TICKET ||--o{ PUBLIC_KIT_TICKET_TABLE_NUM : "fk5696584bb73e273e"
    PUBLIC_PRINTER_GROUP ||--o{ PUBLIC_KITCHEN_TICKET : "fk341cbc275cf1375f"
    PUBLIC_KITCHEN_TICKET ||--o{ PUBLIC_KITCHEN_TICKET_ITEM : "fk1462f02bcb07faa3"
    PUBLIC_MENU_CATEGORY ||--o{ PUBLIC_MENU_GROUP : "fk4dc1ab7f2e347ff0"
    PUBLIC_MENU_GROUP ||--o{ PUBLIC_MENU_ITEM : "fk4cd5a1f35188aa24"
    PUBLIC_PRINTER_GROUP ||--o{ PUBLIC_MENU_ITEM : "fk4cd5a1f35cf1375f"
    PUBLIC_TAX_GROUP ||--o{ PUBLIC_MENU_ITEM : "fk4cd5a1f35ee9f27a"
    PUBLIC_TAX ||--o{ PUBLIC_MENU_ITEM : "fk4cd5a1f3a4802f83"
    PUBLIC_RECEPIE ||--o{ PUBLIC_MENU_ITEM : "fk4cd5a1f3f3b77c57"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENU_ITEM_PROPERTIES : "fkf94186ff89fe23f0"
    PUBLIC_TERMINAL ||--o{ PUBLIC_MENU_ITEM_TERMINAL_REF : "fk9ea1afc2ad2d031"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENU_ITEM_TERMINAL_REF : "fk9ea1afc89fe23f0"
    PUBLIC_MENU_MODIFIER_GROUP ||--o{ PUBLIC_MENU_MODIFIER : "fk59b6b1b72501cb2c"
    PUBLIC_MENU_MODIFIER_GROUP ||--o{ PUBLIC_MENU_MODIFIER : "fk59b6b1b75e0c7b8d"
    PUBLIC_TAX ||--o{ PUBLIC_MENU_MODIFIER : "fk59b6b1b7a4802f83"
    PUBLIC_MENU_MODIFIER ||--o{ PUBLIC_MENU_MODIFIER_PROPERTIES : "fk1273b4bbb79c6270"
    PUBLIC_MENU_CATEGORY ||--o{ PUBLIC_MENUCATEGORY_DISCOUNT : "fk4f8523e38d9ea931"
    PUBLIC_COUPON_AND_DISCOUNT ||--o{ PUBLIC_MENUCATEGORY_DISCOUNT : "fk4f8523e3d3e91e11"
    PUBLIC_MENU_GROUP ||--o{ PUBLIC_MENUGROUP_DISCOUNT : "fke3790e40113bf083"
    PUBLIC_COUPON_AND_DISCOUNT ||--o{ PUBLIC_MENUGROUP_DISCOUNT : "fke3790e40d3e91e11"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENUITEM_DISCOUNT : "fkd89ccdee33662891"
    PUBLIC_COUPON_AND_DISCOUNT ||--o{ PUBLIC_MENUITEM_DISCOUNT : "fkd89ccdeed3e91e11"
    PUBLIC_MENU_MODIFIER_GROUP ||--o{ PUBLIC_MENUITEM_MODIFIERGROUP : "fk312b355b40fda3c9"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENUITEM_MODIFIERGROUP : "fk312b355b6e7b8b68"
    PUBLIC_MENU_MODIFIER_GROUP ||--o{ PUBLIC_MENUITEM_MODIFIERGROUP : "fk312b355b7f2f368"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENUITEM_PIZZAPIRCE : "fk17bd51a089fe23f0"
    PUBLIC_PIZZA_PRICE ||--o{ PUBLIC_MENUITEM_PIZZAPIRCE : "fk17bd51a0ae5d580"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_MENUITEM_SHIFT : "fke03c92d533662891"
    PUBLIC_SHIFT ||--o{ PUBLIC_MENUITEM_SHIFT : "fke03c92d57660a5e3"
    PUBLIC_PIZZA_MODIFIER_PRICE ||--o{ PUBLIC_MENUMODIFIER_PIZZAMODIFIERPRICE : "fk572726f374be2c71"
    PUBLIC_MENU_MODIFIER ||--o{ PUBLIC_MENUMODIFIER_PIZZAMODIFIERPRICE : "fk572726f3ae3f2e91"
    PUBLIC_MULTIPLIER ||--o{ PUBLIC_MODIFIER_MULTIPLIER_PRICE : "fk8a16099391d62c51"
    PUBLIC_PIZZA_MODIFIER_PRICE ||--o{ PUBLIC_MODIFIER_MULTIPLIER_PRICE : "fk8a1609939c9e4883"
    PUBLIC_MENU_MODIFIER ||--o{ PUBLIC_MODIFIER_MULTIPLIER_PRICE : "fk8a160993ae3f2e91"
    PUBLIC_MENU_ITEM_SIZE ||--o{ PUBLIC_PIZZA_MODIFIER_PRICE : "fkd3de7e7896183657"
    PUBLIC_PIZZA_CRUST ||--o{ PUBLIC_PIZZA_PRICE : "fkeac112927c59441d"
    PUBLIC_ORDER_TYPE ||--o{ PUBLIC_PIZZA_PRICE : "fkeac11292a56d141c"
    PUBLIC_MENU_ITEM_SIZE ||--o{ PUBLIC_PIZZA_PRICE : "fkeac11292dd545b77"
    PUBLIC_PRINTER_GROUP ||--o{ PUBLIC_PRINTER_GROUP_PRINTERS : "fkc05b805e5f31265c"
    PUBLIC_MENU_ITEM ||--o{ PUBLIC_RECEPIE : "fk6b4e177764931efc"
    PUBLIC_INVENTORY_ITEM ||--o{ PUBLIC_RECEPIE_ITEM : "fk855626db1682b10e"
    PUBLIC_RECEPIE ||--o{ PUBLIC_RECEPIE_ITEM : "fk855626dbcae89b83"
    PUBLIC_RESTAURANT ||--o{ PUBLIC_RESTAURANT_PROPERTIES : "fk80ad9f75fc64768f"
    PUBLIC_SHOP_FLOOR ||--o{ PUBLIC_SHOP_FLOOR_TEMPLATE : "fkba6efbd68979c3cd"
    PUBLIC_SHOP_FLOOR_TEMPLATE ||--o{ PUBLIC_SHOP_FLOOR_TEMPLATE_PROPERTIES : "fkd70c313ca36ab054"
    PUBLIC_SHOP_FLOOR ||--o{ PUBLIC_SHOP_TABLE : "fk2458e9258979c3cd"
    PUBLIC_USERS ||--o{ PUBLIC_TABLE_BOOKING_INFO : "fk301c4de53e20ad51"
    PUBLIC_CUSTOMER ||--o{ PUBLIC_TABLE_BOOKING_INFO : "fk301c4de59e1c3cf1"
    PUBLIC_TABLE_BOOKING_INFO ||--o{ PUBLIC_TABLE_BOOKING_MAPPING : "fk6bc51417160de3b1"
    PUBLIC_SHOP_TABLE ||--o{ PUBLIC_TABLE_BOOKING_MAPPING : "fk6bc51417dc46948d"
    PUBLIC_SHOP_TABLE_STATUS ||--o{ PUBLIC_TABLE_TICKET_NUM : "fkcbeff0e454031ec1"
    PUBLIC_SHOP_TABLE ||--o{ PUBLIC_TABLE_TYPE_RELATION : "fk93802290dc46948d"
    PUBLIC_SHOP_TABLE_TYPE ||--o{ PUBLIC_TABLE_TYPE_RELATION : "fk93802290f5d6e47b"
    PUBLIC_USERS ||--o{ PUBLIC_TERMINAL : "fke83d827c969c6de"
    PUBLIC_TERMINAL ||--o{ PUBLIC_TERMINAL_PRINTERS : "fk99ede5fc2ad2d031"
    PUBLIC_VIRTUAL_PRINTER ||--o{ PUBLIC_TERMINAL_PRINTERS : "fk99ede5fcc433e65a"
    PUBLIC_TERMINAL ||--o{ PUBLIC_TERMINAL_PROPERTIES : "fk963f26d69d31df8e"
    PUBLIC_USERS ||--o{ PUBLIC_TICKET : "fk937b5f0c1f6a9a4a"
    PUBLIC_TERMINAL ||--o{ PUBLIC_TICKET : "fk937b5f0c2ad2d031"
    PUBLIC_SHIFT ||--o{ PUBLIC_TICKET : "fk937b5f0c7660a5e3"
    PUBLIC_USERS ||--o{ PUBLIC_TICKET : "fk937b5f0caa075d69"
    PUBLIC_GRATUITY ||--o{ PUBLIC_TICKET : "fk937b5f0cc188ea51"
    PUBLIC_USERS ||--o{ PUBLIC_TICKET : "fk937b5f0cf575c7d4"
    PUBLIC_TICKET ||--o{ PUBLIC_TICKET_DISCOUNT : "fk1fa465141df2d7f1"
    PUBLIC_TICKET ||--o{ PUBLIC_TICKET_ITEM : "fk979f54661df2d7f1"
    PUBLIC_TICKET_ITEM_MODIFIER ||--o{ PUBLIC_TICKET_ITEM : "fk979f546633e5d3b2"
    PUBLIC_PRINTER_GROUP ||--o{ PUBLIC_TICKET_ITEM : "fk979f54665cf1375f"
    PUBLIC_TICKET_ITEM_MODIFIER ||--o{ PUBLIC_TICKET_ITEM_ADDON_RELATION : "fk9f1996346c108ef0"
    PUBLIC_TICKET_ITEM ||--o{ PUBLIC_TICKET_ITEM_ADDON_RELATION : "fk9f199634dec6120a"
    PUBLIC_TICKET_ITEM ||--o{ PUBLIC_TICKET_ITEM_COOKING_INSTRUCTION : "fk3825f9d0dec6120a"
    PUBLIC_TICKET_ITEM ||--o{ PUBLIC_TICKET_ITEM_DISCOUNT : "fk3df5d4fab9276e77"
    PUBLIC_TICKET_ITEM ||--o{ PUBLIC_TICKET_ITEM_MODIFIER : "fk8fd6290dec6120a"
    PUBLIC_TICKET_ITEM_MODIFIER ||--o{ PUBLIC_TICKET_ITEM_MODIFIER_RELATION : "fk5d3f9acb6c108ef0"
    PUBLIC_TICKET_ITEM ||--o{ PUBLIC_TICKET_ITEM_MODIFIER_RELATION : "fk5d3f9acbdec6120a"
    PUBLIC_TICKET ||--o{ PUBLIC_TICKET_PROPERTIES : "fk70ecd046223049de"
    PUBLIC_TICKET ||--o{ PUBLIC_TICKET_TABLE_NUM : "fk65af15e21df2d7f1"
    PUBLIC_TRANSACTIONS ||--o{ PUBLIC_TRANSACTION_PROPERTIES : "fke3de65548e8203bc"
    PUBLIC_TICKET ||--o{ PUBLIC_TRANSACTIONS : "fkfe9871551df2d7f1"
    PUBLIC_TERMINAL ||--o{ PUBLIC_TRANSACTIONS : "fkfe9871552ad2d031"
    PUBLIC_USERS ||--o{ PUBLIC_TRANSACTIONS : "fkfe9871553e20ad51"
    PUBLIC_PAYOUT_RECEPIENTS ||--o{ PUBLIC_TRANSACTIONS : "fkfe987155ca43b6"
    PUBLIC_PAYOUT_REASONS ||--o{ PUBLIC_TRANSACTIONS : "fkfe987155fc697d9e"
    PUBLIC_USER_TYPE ||--o{ PUBLIC_USER_USER_PERMISSION : "fk2dbeaa4f283ecc6"
    PUBLIC_USER_PERMISSION ||--o{ PUBLIC_USER_USER_PERMISSION : "fk2dbeaa4f8f23f5e"
    PUBLIC_SHIFT ||--o{ PUBLIC_USERS : "fk4d495e87660a5e3"
    PUBLIC_USER_TYPE ||--o{ PUBLIC_USERS : "fk4d495e8897b1e39"
    PUBLIC_TERMINAL ||--o{ PUBLIC_USERS : "fk4d495e8d9409968"
    PUBLIC_VIRTUAL_PRINTER ||--o{ PUBLIC_VIRTUALPRINTER_ORDER_TYPE : "fk9af7853bcf15f4a6"
```

## Diagrama ER - esquema selemti
```mermaid
erDiagram
    SELEMTI_ALMACEN {
        text id PK
        text sucursal_id
        text nombre
        boolean activo
    }
    SELEMTI_AUDITORIA {
        bigint(64,0) id PK
        integer(32,0) quien
        text que
        jsonb payload
        timestamp with time zone(6) creado_en
    }
    SELEMTI_CACHE {
        character varying(255) key PK
        text value
        integer(32,0) expiration
    }
    SELEMTI_CACHE_LOCKS {
        character varying(255) key PK
        character varying(255) owner
        integer(32,0) expiration
    }
    SELEMTI_CAT_UNIDADES {
        bigint(64,0) id PK
        timestamp without time zone(0) created_at
        timestamp without time zone(0) updated_at
    }
    SELEMTI_CONVERSIONES_UNIDAD {
        integer(32,0) id PK
        integer(32,0) unidad_origen_id
        integer(32,0) unidad_destino_id
        numeric(12,6) factor_conversion
        text formula_directa
        numeric(5,4) precision_estimada
        boolean activo
        timestamp without time zone(6) created_at
    }
    SELEMTI_COST_LAYER {
        bigint(64,0) id PK
        character varying(20) item_id
        bigint(64,0) batch_id
        timestamp without time zone(6) ts_in
        numeric(14,6) qty_in
        numeric(14,6) qty_left
        numeric(14,6) unit_cost
        character varying(30) sucursal_id
        text source_ref
        bigint(64,0) source_id
    }
    SELEMTI_FAILED_JOBS {
        bigint(64,0) id PK
        character varying(255) uuid
        text connection
        text queue
        text payload
        text exception
        timestamp without time zone(0) failed_at
    }
    SELEMTI_FORMAS_PAGO {
        bigint(64,0) id PK
        text codigo
        text payment_type
        text transaction_type
        text payment_sub_type
        text custom_name
        text custom_ref
        boolean activo
        integer(32,0) prioridad
        timestamp with time zone(6) creado_en
    }
    SELEMTI_HISTORIAL_COSTOS_ITEM {
        integer(32,0) id PK
        character varying(20) item_id
        date fecha_efectiva
        timestamp without time zone(6) fecha_registro
        numeric(10,2) costo_anterior
        numeric(10,2) costo_nuevo
        character varying(20) tipo_cambio
        integer(32,0) referencia_id
        character varying(20) referencia_tipo
        integer(32,0) usuario_id
        date valid_from
        date valid_to
        timestamp without time zone(6) sys_from
        timestamp without time zone(6) sys_to
        numeric(12,4) costo_wac
        numeric(12,4) costo_peps
        numeric(12,4) costo_ueps
        numeric(12,4) costo_estandar
        character varying(10) algoritmo_principal
        integer(32,0) version_datos
        boolean recalculado
        character varying(20) fuente_datos
        json metadata_calculo
        timestamp without time zone(6) created_at
    }
    SELEMTI_HISTORIAL_COSTOS_RECETA {
        integer(32,0) id PK
        integer(32,0) receta_version_id
        date fecha_calculo
        numeric(10,2) costo_total
        numeric(10,2) costo_porcion
        character varying(20) algoritmo_utilizado
        integer(32,0) version_datos
        json metadata_calculo
        timestamp without time zone(6) created_at
        date valid_from
        date valid_to
        timestamp without time zone(6) sys_from
        timestamp without time zone(6) sys_to
    }
    SELEMTI_INVENTORY_BATCH {
        integer(32,0) id PK
        character varying(20) item_id
        character varying(50) lote_proveedor
        date fecha_recepcion
        date fecha_caducidad
        numeric(5,2) temperatura_recepcion
        character varying(255) documento_url
        numeric(10,3) cantidad_original
        numeric(10,3) cantidad_actual
        character varying(20) estado
        character varying(10) ubicacion_id
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_ITEM_VENDOR {
        text item_id PK
        text vendor_id PK
        text presentacion PK
        integer(32,0) unidad_presentacion_id
        numeric(14,6) factor_a_canonica
        numeric(14,6) costo_ultimo
        text moneda
        integer(32,0) lead_time_dias
        text codigo_proveedor
        boolean activo
        timestamp without time zone(6) created_at
    }
    SELEMTI_ITEMS {
        character varying(20) id PK
        character varying(100) nombre
        text descripcion
        character varying(10) categoria_id
        character varying(10) unidad_medida
        boolean perishable
        integer(32,0) temperatura_min
        integer(32,0) temperatura_max
        numeric(10,2) costo_promedio
        boolean activo
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
        integer(32,0) unidad_medida_id
        numeric(12,6) factor_conversion
        integer(32,0) unidad_compra_id
        numeric(12,6) factor_compra
        USER-DEFINED tipo
        integer(32,0) unidad_salida_id
    }
    SELEMTI_JOB_BATCHES {
        character varying(255) id PK
        character varying(255) name
        integer(32,0) total_jobs
        integer(32,0) pending_jobs
        integer(32,0) failed_jobs
        text failed_job_ids
        text options
        integer(32,0) cancelled_at
        integer(32,0) created_at
        integer(32,0) finished_at
    }
    SELEMTI_JOB_RECALC_QUEUE {
        bigint(64,0) id PK
        text scope_type
        date scope_from
        date scope_to
        character varying(20) item_id
        character varying(20) receta_id
        character varying(30) sucursal_id
        text reason
        timestamp without time zone(6) created_ts
        text status
        json result
    }
    SELEMTI_JOBS {
        bigint(64,0) id PK
        character varying(255) queue
        text payload
        smallint(16,0) attempts
        integer(32,0) reserved_at
        integer(32,0) available_at
        integer(32,0) created_at
    }
    SELEMTI_MIGRATIONS {
        integer(32,0) id PK
        character varying(255) migration
        integer(32,0) batch
    }
    SELEMTI_MODEL_HAS_PERMISSIONS {
        bigint(64,0) permission_id PK
        character varying(255) model_type PK
        bigint(64,0) model_id PK
    }
    SELEMTI_MODEL_HAS_ROLES {
        bigint(64,0) role_id PK
        character varying(255) model_type PK
        bigint(64,0) model_id PK
    }
    SELEMTI_MODIFICADORES_POS {
        integer(32,0) id PK
        character varying(20) codigo_pos
        character varying(100) nombre
        character varying(20) tipo
        numeric(10,2) precio_extra
        character varying(20) receta_modificador_id
        boolean activo
    }
    SELEMTI_MOV_INV {
        bigint(64,0) id PK
        timestamp without time zone(6) ts
        character varying(20) item_id
        integer(32,0) lote_id
        numeric(14,6) cantidad
        numeric(14,6) qty_original
        integer(32,0) uom_original_id
        numeric(14,6) costo_unit
        character varying(20) tipo
        character varying(50) ref_tipo
        bigint(64,0) ref_id
        character varying(30) sucursal_id
        integer(32,0) usuario_id
        timestamp without time zone(6) created_at
    }
    SELEMTI_OP_PRODUCCION_CAB {
        integer(32,0) id PK
        integer(32,0) receta_version_id
        numeric(10,3) cantidad_planeada
        numeric(10,3) cantidad_real
        date fecha_produccion
        character varying(20) estado
        character varying(50) lote_resultado
        integer(32,0) usuario_responsable
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_PARAM_SUCURSAL {
        integer(32,0) id PK
        text sucursal_id
        USER-DEFINED consumo
        numeric(8,4) tolerancia_precorte_pct
        numeric(12,4) tolerancia_corte_abs
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_PASSWORD_RESET_TOKENS {
        character varying(255) email PK
        character varying(255) token
        timestamp without time zone(0) created_at
    }
    SELEMTI_PERDIDA_LOG {
        bigint(64,0) id PK
        timestamp without time zone(6) ts
        text item_id
        bigint(64,0) lote_id
        text sucursal_id
        USER-DEFINED clase
        text motivo
        numeric(14,6) qty_canonica
        numeric(14,6) qty_original
        integer(32,0) uom_original_id
        text evidencia_url
        integer(32,0) usuario_id
        text ref_tipo
        bigint(64,0) ref_id
        timestamp without time zone(6) created_at
    }
    SELEMTI_PERMISSIONS {
        bigint(64,0) id PK
        character varying(255) name
        character varying(255) guard_name
        timestamp without time zone(0) created_at
        timestamp without time zone(0) updated_at
    }
    SELEMTI_POS_MAP {
        text pos_system PK
        text plu PK
        text tipo
        text receta_id
        integer(32,0) receta_version_id
        date valid_from PK
        date valid_to
        timestamp without time zone(6) sys_from PK
        timestamp without time zone(6) sys_to
        json meta
    }
    SELEMTI_POSTCORTE {
        bigint(64,0) id PK
        bigint(64,0) sesion_id
        numeric(12,2) sistema_efectivo_esperado
        numeric(12,2) declarado_efectivo
        numeric(12,2) diferencia_efectivo
        text veredicto_efectivo
        numeric(12,2) sistema_tarjetas
        numeric(12,2) declarado_tarjetas
        numeric(12,2) diferencia_tarjetas
        text veredicto_tarjetas
        timestamp with time zone(6) creado_en
        integer(32,0) creado_por
        text notas
        numeric(12,2) sistema_transferencias
        numeric(12,2) declarado_transferencias
        numeric(12,2) diferencia_transferencias
        text veredicto_transferencias
        boolean validado
        integer(32,0) validado_por
        timestamp with time zone(6) validado_en
    }
    SELEMTI_PRECORTE {
        bigint(64,0) id PK
        bigint(64,0) sesion_id
        numeric(12,2) declarado_efectivo
        numeric(12,2) declarado_otros
        text estatus
        timestamp with time zone(6) creado_en
        integer(32,0) creado_por
        inet ip_cliente
        text notas
    }
    SELEMTI_PRECORTE_EFECTIVO {
        bigint(64,0) id PK
        bigint(64,0) precorte_id
        numeric(12,2) denominacion
        integer(32,0) cantidad
        numeric(12,2) subtotal
    }
    SELEMTI_PRECORTE_OTROS {
        bigint(64,0) id PK
        bigint(64,0) precorte_id
        text tipo
        numeric(12,2) monto
        text referencia
        text evidencia_url
        text notas
        timestamp with time zone(6) creado_en
    }
    SELEMTI_PROVEEDOR {
        text id PK
        text nombre
        text rfc
        boolean activo
    }
    SELEMTI_RECALC_LOG {
        bigint(64,0) id PK
        bigint(64,0) job_id
        text step
        timestamp without time zone(6) started_ts
        timestamp without time zone(6) ended_ts
        boolean ok
        json details
    }
    SELEMTI_RECETA_CAB {
        character varying(20) id PK
        character varying(100) nombre_plato
        character varying(20) codigo_plato_pos
        character varying(50) categoria_plato
        integer(32,0) porciones_standard
        text instrucciones_preparacion
        integer(32,0) tiempo_preparacion_min
        numeric(10,2) costo_standard_porcion
        numeric(10,2) precio_venta_sugerido
        boolean activo
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_RECETA_DET {
        integer(32,0) id PK
        integer(32,0) receta_version_id
        character varying(20) item_id
        numeric(10,4) cantidad
        character varying(10) unidad_medida
        numeric(5,2) merma_porcentaje
        text instrucciones_especificas
        integer(32,0) orden
        timestamp without time zone(6) created_at
    }
    SELEMTI_RECETA_SHADOW {
        integer(32,0) id PK
        character varying(20) codigo_plato_pos
        character varying(100) nombre_plato
        character varying(15) estado
        numeric(5,4) confianza
        integer(32,0) total_ventas_analizadas
        date fecha_primer_venta
        date fecha_ultima_venta
        numeric(10,2) frecuencia_dias
        json ingredientes_inferidos
        integer(32,0) usuario_validador
        timestamp without time zone(6) fecha_validacion
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_RECETA_VERSION {
        integer(32,0) id PK
        character varying(20) receta_id
        integer(32,0) version
        text descripcion_cambios
        date fecha_efectiva
        boolean version_publicada
        integer(32,0) usuario_publicador
        timestamp without time zone(6) fecha_publicacion
        timestamp without time zone(6) created_at
    }
    SELEMTI_ROLE_HAS_PERMISSIONS {
        bigint(64,0) permission_id PK
        bigint(64,0) role_id PK
    }
    SELEMTI_ROLES {
        bigint(64,0) id PK
        character varying(255) name
        character varying(255) guard_name
        timestamp without time zone(0) created_at
        timestamp without time zone(0) updated_at
    }
    SELEMTI_SESION_CAJON {
        bigint(64,0) id PK
        text sucursal
        integer(32,0) terminal_id
        text terminal_nombre
        integer(32,0) cajero_usuario_id
        timestamp with time zone(6) apertura_ts
        timestamp with time zone(6) cierre_ts
        text estatus
        numeric(12,2) opening_float
        numeric(12,2) closing_float
        integer(32,0) dah_evento_id
        boolean skipped_precorte
    }
    SELEMTI_SESSIONS {
        character varying(255) id PK
        bigint(64,0) user_id
        character varying(45) ip_address
        text user_agent
        text payload
        integer(32,0) last_activity
    }
    SELEMTI_STOCK_POLICY {
        bigint(64,0) id PK
        text item_id
        text sucursal_id
        text almacen_id
        numeric(14,6) min_qty
        numeric(14,6) max_qty
        numeric(14,6) reorder_lote
        boolean activo
        timestamp without time zone(6) created_at
    }
    SELEMTI_SUCURSAL {
        text id PK
        text nombre
        boolean activo
    }
    SELEMTI_SUCURSAL_ALMACEN_TERMINAL {
        integer(32,0) id PK
        text sucursal_id
        text almacen_id
        integer(32,0) terminal_id
        text location
        text descripcion
        boolean activo
        timestamp without time zone(6) created_at
    }
    SELEMTI_TICKET_DET_CONSUMO {
        bigint(64,0) id PK
        bigint(64,0) ticket_id
        bigint(64,0) ticket_det_id
        text item_id
        bigint(64,0) lote_id
        numeric(14,6) qty_canonica
        numeric(14,6) qty_original
        integer(32,0) uom_original_id
        text sucursal_id
        text ref_tipo
        bigint(64,0) ref_id
        timestamp without time zone(6) created_at
    }
    SELEMTI_TICKET_VENTA_CAB {
        bigint(64,0) id PK
        character varying(50) numero_ticket
        timestamp without time zone(6) fecha_venta
        character varying(10) sucursal_id
        integer(32,0) terminal_id
        numeric(12,2) total_venta
        character varying(20) estado
        timestamp without time zone(6) created_at
    }
    SELEMTI_TICKET_VENTA_DET {
        bigint(64,0) id PK
        bigint(64,0) ticket_id
        character varying(20) item_id
        numeric(10,3) cantidad
        numeric(10,2) precio_unitario
        numeric(12,2) subtotal
        integer(32,0) receta_version_id
        timestamp without time zone(6) created_at
        integer(32,0) receta_shadow_id
        boolean reprocesado
        integer(32,0) version_reproceso
        json modificadores_aplicados
    }
    SELEMTI_UNIDADES_MEDIDA {
        integer(32,0) id PK
        character varying(10) codigo
        character varying(50) nombre
        character varying(10) tipo
        character varying(20) categoria
        boolean es_base
        numeric(12,6) factor_conversion_base
        integer(32,0) decimales
        timestamp without time zone(6) created_at
    }
    SELEMTI_USER_ROLES {
        integer(32,0) user_id PK
        character varying(20) role_id PK
        timestamp without time zone(6) assigned_at
        integer(32,0) assigned_by
    }
    SELEMTI_USERS {
        integer(32,0) id PK
        character varying(50) username
        character varying(255) password_hash
        character varying(255) email
        character varying(100) nombre_completo
        character varying(10) sucursal_id
        boolean activo
        timestamp without time zone(6) fecha_ultimo_login
        integer(32,0) intentos_login
        timestamp without time zone(6) bloqueado_hasta
        timestamp without time zone(6) created_at
        timestamp without time zone(6) updated_at
    }
    SELEMTI_SUCURSAL ||--o{ SELEMTI_ALMACEN : "almacen_sucursal_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_CONVERSIONES_UNIDAD : "conversiones_unidad_unidad_destino_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_CONVERSIONES_UNIDAD : "conversiones_unidad_unidad_origen_id_fkey"
    SELEMTI_INVENTORY_BATCH ||--o{ SELEMTI_COST_LAYER : "cost_layer_batch_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_COST_LAYER : "cost_layer_item_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_HISTORIAL_COSTOS_ITEM : "historial_costos_item_item_id_fkey"
    SELEMTI_RECETA_VERSION ||--o{ SELEMTI_HISTORIAL_COSTOS_RECETA : "historial_costos_receta_receta_version_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_INVENTORY_BATCH : "inventory_batch_item_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_ITEM_VENDOR : "item_vendor_item_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_ITEM_VENDOR : "item_vendor_unidad_presentacion_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_ITEMS : "items_unidad_compra_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_ITEMS : "items_unidad_medida_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_ITEMS : "items_unidad_salida_id_fkey"
    SELEMTI_PERMISSIONS ||--o{ SELEMTI_MODEL_HAS_PERMISSIONS : "model_has_permissions_permission_id_foreign"
    SELEMTI_ROLES ||--o{ SELEMTI_MODEL_HAS_ROLES : "model_has_roles_role_id_foreign"
    SELEMTI_RECETA_CAB ||--o{ SELEMTI_MODIFICADORES_POS : "modificadores_pos_receta_modificador_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_MOV_INV : "mov_inv_item_id_fkey"
    SELEMTI_INVENTORY_BATCH ||--o{ SELEMTI_MOV_INV : "mov_inv_lote_id_fkey"
    SELEMTI_RECETA_VERSION ||--o{ SELEMTI_OP_PRODUCCION_CAB : "op_produccion_cab_receta_version_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_PERDIDA_LOG : "perdida_log_item_id_fkey"
    SELEMTI_INVENTORY_BATCH ||--o{ SELEMTI_PERDIDA_LOG : "perdida_log_lote_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_PERDIDA_LOG : "perdida_log_uom_original_id_fkey"
    SELEMTI_SESION_CAJON ||--o{ SELEMTI_POSTCORTE : "postcorte_sesion_id_fkey"
    SELEMTI_SESION_CAJON ||--o{ SELEMTI_PRECORTE : "precorte_sesion_id_fkey"
    SELEMTI_PRECORTE ||--o{ SELEMTI_PRECORTE_EFECTIVO : "precorte_efectivo_precorte_id_fkey"
    SELEMTI_PRECORTE ||--o{ SELEMTI_PRECORTE_OTROS : "precorte_otros_precorte_id_fkey"
    SELEMTI_JOB_RECALC_QUEUE ||--o{ SELEMTI_RECALC_LOG : "recalc_log_job_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_RECETA_DET : "receta_det_item_id_fkey"
    SELEMTI_RECETA_VERSION ||--o{ SELEMTI_RECETA_DET : "receta_det_receta_version_id_fkey"
    SELEMTI_RECETA_CAB ||--o{ SELEMTI_RECETA_VERSION : "receta_version_receta_id_fkey"
    SELEMTI_PERMISSIONS ||--o{ SELEMTI_ROLE_HAS_PERMISSIONS : "role_has_permissions_permission_id_foreign"
    SELEMTI_ROLES ||--o{ SELEMTI_ROLE_HAS_PERMISSIONS : "role_has_permissions_role_id_foreign"
    SELEMTI_ITEMS ||--o{ SELEMTI_STOCK_POLICY : "stock_policy_item_id_fkey"
    SELEMTI_ITEMS ||--o{ SELEMTI_TICKET_DET_CONSUMO : "ticket_det_consumo_item_id_fkey"
    SELEMTI_INVENTORY_BATCH ||--o{ SELEMTI_TICKET_DET_CONSUMO : "ticket_det_consumo_lote_id_fkey"
    SELEMTI_UNIDADES_MEDIDA ||--o{ SELEMTI_TICKET_DET_CONSUMO : "ticket_det_consumo_uom_original_id_fkey"
    SELEMTI_TICKET_VENTA_CAB ||--o{ SELEMTI_TICKET_VENTA_DET : "fk_ticket_det_cab"
    SELEMTI_RECETA_SHADOW ||--o{ SELEMTI_TICKET_VENTA_DET : "ticket_venta_det_receta_shadow_id_fkey"
    SELEMTI_RECETA_VERSION ||--o{ SELEMTI_TICKET_VENTA_DET : "ticket_venta_det_receta_version_id_fkey"
```

## Diagrama Global - caja/ventas/pagos/movimientos
```mermaid
erDiagram
    PUBLIC_CASH_DRAWER {
        integer(32,0) id PK
        integer(32,0) terminal_id
    }
    PUBLIC_CASH_DRAWER_RESET_HISTORY {
        integer(32,0) id PK
        timestamp without time zone(6) reset_time
        integer(32,0) user_id
    }
    PUBLIC_CUSTOM_PAYMENT {
        integer(32,0) id PK
        character varying(60) name
        boolean required_ref_number
        character varying(60) ref_number_field_name
    }
    SELEMTI_FORMAS_PAGO {
        bigint(64,0) id PK
        text codigo
        text payment_type
        text transaction_type
        text payment_sub_type
        text custom_name
        text custom_ref
        boolean activo
        integer(32,0) prioridad
        timestamp with time zone(6) creado_en
    }
    SELEMTI_TICKET_VENTA_CAB {
        bigint(64,0) id PK
        character varying(50) numero_ticket
        timestamp without time zone(6) fecha_venta
        character varying(10) sucursal_id
        integer(32,0) terminal_id
        numeric(12,2) total_venta
        character varying(20) estado
        timestamp without time zone(6) created_at
    }
    SELEMTI_TICKET_VENTA_DET {
        bigint(64,0) id PK
        bigint(64,0) ticket_id
        character varying(20) item_id
        numeric(10,3) cantidad
        numeric(10,2) precio_unitario
        numeric(12,2) subtotal
        integer(32,0) receta_version_id
        timestamp without time zone(6) created_at
        integer(32,0) receta_shadow_id
        boolean reprocesado
        integer(32,0) version_reproceso
        json modificadores_aplicados
    }
    SELEMTI_TICKET_VENTA_CAB ||--o{ SELEMTI_TICKET_VENTA_DET : "fk_ticket_det_cab"
```

## Detalle de tablas

### public.action_history
- Descripción: sin comentario
- Filas estimadas: ~36,562
- Flags: faltan índices para FKs (fk3f3af36b3e20ad51) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('action_history_id_seq'::regclass) | action_history_id_seq |  |
| action_time | timestamp without time zone(6) | Sí |  |  |  |
| action_name | character varying(255) | Sí |  |  |  |
| description | character varying(255) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- action_history_pkey: id

#### Llaves foráneas
- fk3f3af36b3e20ad51: (user_id) ➜ public.users (auto_id)

#### Índices
- action_history_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.attendence_history
- Descripción: sin comentario
- Filas estimadas: ~8
- Flags: faltan índices para FKs (fkdfe829a2ad2d031, fkdfe829a3e20ad51, fkdfe829a7660a5e3) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('attendence_history_id_seq'::regclass) | attendence_history_id_seq |  |
| clock_in_time | timestamp without time zone(6) | Sí |  |  |  |
| clock_out_time | timestamp without time zone(6) | Sí |  |  |  |
| clock_in_hour | smallint(16,0) | Sí |  |  |  |
| clock_out_hour | smallint(16,0) | Sí |  |  |  |
| clocked_out | boolean | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| shift_id | integer(32,0) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- attendence_history_pkey: id

#### Llaves foráneas
- fkdfe829a2ad2d031: (terminal_id) ➜ public.terminal (id)
- fkdfe829a3e20ad51: (user_id) ➜ public.users (auto_id)
- fkdfe829a7660a5e3: (shift_id) ➜ public.shift (id)

#### Índices
- attendence_history_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.cash_drawer
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk6221077d2ad2d031) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('cash_drawer_id_seq'::regclass) | cash_drawer_id_seq |  |
| terminal_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- cash_drawer_pkey: id

#### Llaves foráneas
- fk6221077d2ad2d031: (terminal_id) ➜ public.terminal (id)

#### Índices
- cash_drawer_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.cash_drawer_reset_history
- Descripción: sin comentario
- Filas estimadas: ~70
- Flags: faltan índices para FKs (fk719418223e20ad51) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('cash_drawer_reset_history_id_seq'::regclass) | cash_drawer_reset_history_id_seq |  |
| reset_time | timestamp without time zone(6) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- cash_drawer_reset_history_pkey: id

#### Llaves foráneas
- fk719418223e20ad51: (user_id) ➜ public.users (auto_id)

#### Índices
- cash_drawer_reset_history_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.cooking_instruction
- Descripción: sin comentario
- Filas estimadas: ~17
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('cooking_instruction_id_seq'::regclass) | cooking_instruction_id_seq |  |
| description | character varying(60) | Sí |  |  |  |

#### Llave primaria
- cooking_instruction_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- cooking_instruction_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.coupon_and_discount
- Descripción: sin comentario
- Filas estimadas: ~6
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('coupon_and_discount_id_seq'::regclass) | coupon_and_discount_id_seq |  |
| name | character varying(120) | Sí |  |  |  |
| type | integer(32,0) | Sí |  |  |  |
| barcode | character varying(120) | Sí |  |  |  |
| qualification_type | integer(32,0) | Sí |  |  |  |
| apply_to_all | boolean | Sí |  |  |  |
| minimum_buy | integer(32,0) | Sí |  |  |  |
| maximum_off | integer(32,0) | Sí |  |  |  |
| value | double precision(53) | Sí |  |  |  |
| expiry_date | timestamp without time zone(6) | Sí |  |  |  |
| enabled | boolean | Sí |  |  |  |
| auto_apply | boolean | Sí |  |  |  |
| modifiable | boolean | Sí |  |  |  |
| never_expire | boolean | Sí |  |  |  |
| uuid | character varying(36) | Sí |  |  |  |

#### Llave primaria
- coupon_and_discount_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- coupon_and_discount_pkey [PK, UNIQUE] (id) USING BTREE
- coupon_and_discount_uuid_key [UNIQUE] (uuid) USING BTREE

#### Restricciones UNIQUE
- coupon_and_discount_uuid_key: uuid

#### Restricciones CHECK
- Sin restricciones CHECK

### public.currency
- Descripción: sin comentario
- Filas estimadas: ~5
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('currency_id_seq'::regclass) | currency_id_seq |  |
| code | character varying(20) | Sí |  |  |  |
| name | character varying(30) | Sí |  |  |  |
| symbol | character varying(10) | Sí |  |  |  |
| exchange_rate | double precision(53) | Sí |  |  |  |
| decimal_places | integer(32,0) | Sí |  |  |  |
| tolerance | double precision(53) | Sí |  |  |  |
| buy_price | double precision(53) | Sí |  |  |  |
| sales_price | double precision(53) | Sí |  |  |  |
| main | boolean | Sí |  |  |  |

#### Llave primaria
- currency_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- currency_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.currency_balance
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk2cc0e08e28dd6c11, fk2cc0e08e9006558, fk2cc0e08efb910735) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('currency_balance_id_seq'::regclass) | currency_balance_id_seq |  |
| balance | double precision(53) | Sí |  |  |  |
| currency_id | integer(32,0) | Sí |  |  |  |
| cash_drawer_id | integer(32,0) | Sí |  |  |  |
| dpr_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- currency_balance_pkey: id

#### Llaves foráneas
- fk2cc0e08e28dd6c11: (currency_id) ➜ public.currency (id)
- fk2cc0e08e9006558: (cash_drawer_id) ➜ public.cash_drawer (id)
- fk2cc0e08efb910735: (dpr_id) ➜ public.drawer_pull_report (id)

#### Índices
- currency_balance_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.custom_payment
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('custom_payment_id_seq'::regclass) | custom_payment_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| required_ref_number | boolean | Sí |  |  |  |
| ref_number_field_name | character varying(60) | Sí |  |  |  |

#### Llave primaria
- custom_payment_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- custom_payment_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.customer
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| auto_id | integer(32,0) | No | nextval('customer_auto_id_seq'::regclass) | customer_auto_id_seq |  |
| loyalty_no | character varying(30) | Sí |  |  |  |
| loyalty_point | integer(32,0) | Sí |  |  |  |
| social_security_number | character varying(60) | Sí |  |  |  |
| picture | bytea | Sí |  |  |  |
| homephone_no | character varying(30) | Sí |  |  |  |
| mobile_no | character varying(30) | Sí |  |  |  |
| workphone_no | character varying(30) | Sí |  |  |  |
| email | character varying(40) | Sí |  |  |  |
| salutation | character varying(60) | Sí |  |  |  |
| first_name | character varying(60) | Sí |  |  |  |
| last_name | character varying(60) | Sí |  |  |  |
| name | character varying(120) | Sí |  |  |  |
| dob | character varying(16) | Sí |  |  |  |
| ssn | character varying(30) | Sí |  |  |  |
| address | character varying(220) | Sí |  |  |  |
| city | character varying(30) | Sí |  |  |  |
| state | character varying(30) | Sí |  |  |  |
| zip_code | character varying(10) | Sí |  |  |  |
| country | character varying(30) | Sí |  |  |  |
| vip | boolean | Sí |  |  |  |
| credit_limit | double precision(53) | Sí |  |  |  |
| credit_spent | double precision(53) | Sí |  |  |  |
| credit_card_no | character varying(30) | Sí |  |  |  |
| note | character varying(255) | Sí |  |  |  |

#### Llave primaria
- customer_pkey: auto_id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- customer_pkey [PK, UNIQUE] (auto_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.customer_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(255) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- customer_properties_pkey: id, property_name

#### Llaves foráneas
- fkd43068347bbccf0: (id) ➜ public.customer (auto_id)

#### Índices
- customer_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.daily_folio_counter
- Descripción: sin comentario
- Filas estimadas: ~21
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| folio_date | date | No |  |  |  |
| branch_key | text | No |  |  |  |
| last_value | integer(32,0) | No | 0 |  |  |

#### Llave primaria
- daily_folio_counter_pkey: folio_date, branch_key

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- daily_folio_counter_pkey [PK, UNIQUE] (folio_date, branch_key) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.data_update_info
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('data_update_info_id_seq'::regclass) | data_update_info_id_seq |  |
| last_update_time | timestamp without time zone(6) | Sí |  |  |  |

#### Llave primaria
- data_update_info_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- data_update_info_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.delivery_address
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk29aca6899e1c3cf1) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('delivery_address_id_seq'::regclass) | delivery_address_id_seq |  |
| address | character varying(320) | Sí |  |  |  |
| phone_extension | character varying(10) | Sí |  |  |  |
| room_no | character varying(30) | Sí |  |  |  |
| distance | double precision(53) | Sí |  |  |  |
| customer_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- delivery_address_pkey: id

#### Llaves foráneas
- fk29aca6899e1c3cf1: (customer_id) ➜ public.customer (auto_id)

#### Índices
- delivery_address_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.delivery_charge
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('delivery_charge_id_seq'::regclass) | delivery_charge_id_seq |  |
| name | character varying(220) | Sí |  |  |  |
| zip_code | character varying(20) | Sí |  |  |  |
| start_range | double precision(53) | Sí |  |  |  |
| end_range | double precision(53) | Sí |  |  |  |
| charge_amount | double precision(53) | Sí |  |  |  |

#### Llave primaria
- delivery_charge_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- delivery_charge_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.delivery_configuration
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('delivery_configuration_id_seq'::regclass) | delivery_configuration_id_seq |  |
| unit_name | character varying(20) | Sí |  |  |  |
| unit_symbol | character varying(8) | Sí |  |  |  |
| charge_by_zip_code | boolean | Sí |  |  |  |

#### Llave primaria
- delivery_configuration_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- delivery_configuration_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.delivery_instruction
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk29d9ca39e1c3d97) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('delivery_instruction_id_seq'::regclass) | delivery_instruction_id_seq |  |
| notes | character varying(220) | Sí |  |  |  |
| customer_no | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- delivery_instruction_pkey: id

#### Llaves foráneas
- fk29d9ca39e1c3d97: (customer_no) ➜ public.customer (auto_id)

#### Índices
- delivery_instruction_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.drawer_assigned_history
- Descripción: sin comentario
- Filas estimadas: ~141
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('drawer_assigned_history_id_seq'::regclass) | drawer_assigned_history_id_seq |  |
| time | timestamp without time zone(6) | Sí |  |  |  |
| operation | character varying(60) | Sí |  |  |  |
| a_user | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- drawer_assigned_history_pkey: id

#### Llaves foráneas
- fk5a823c91f1dd782b: (a_user) ➜ public.users (auto_id)

#### Índices
- drawer_assigned_history_pkey [PK, UNIQUE] (id) USING BTREE
- idx_dah_user_op_time (a_user, operation, time) USING BTREE
- idx_drawer_assigned_history_user_time (a_user, time) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.drawer_pull_report
- Descripción: sin comentario
- Filas estimadas: ~70
- Flags: faltan índices para FKs (fkaec362202ad2d031, fkaec362203e20ad51) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('drawer_pull_report_id_seq'::regclass) | drawer_pull_report_id_seq |  |
| report_time | timestamp without time zone(6) | Sí |  |  |  |
| reg | character varying(15) | Sí |  |  |  |
| ticket_count | integer(32,0) | Sí |  |  |  |
| begin_cash | double precision(53) | Sí |  |  |  |
| net_sales | double precision(53) | Sí |  |  |  |
| sales_tax | double precision(53) | Sí |  |  |  |
| cash_tax | double precision(53) | Sí |  |  |  |
| total_revenue | double precision(53) | Sí |  |  |  |
| gross_receipts | double precision(53) | Sí |  |  |  |
| giftcertreturncount | integer(32,0) | Sí |  |  |  |
| giftcertreturnamount | double precision(53) | Sí |  |  |  |
| giftcertchangeamount | double precision(53) | Sí |  |  |  |
| cash_receipt_no | integer(32,0) | Sí |  |  |  |
| cash_receipt_amount | double precision(53) | Sí |  |  |  |
| credit_card_receipt_no | integer(32,0) | Sí |  |  |  |
| credit_card_receipt_amount | double precision(53) | Sí |  |  |  |
| debit_card_receipt_no | integer(32,0) | Sí |  |  |  |
| debit_card_receipt_amount | double precision(53) | Sí |  |  |  |
| refund_receipt_count | integer(32,0) | Sí |  |  |  |
| refund_amount | double precision(53) | Sí |  |  |  |
| receipt_differential | double precision(53) | Sí |  |  |  |
| cash_back | double precision(53) | Sí |  |  |  |
| cash_tips | double precision(53) | Sí |  |  |  |
| charged_tips | double precision(53) | Sí |  |  |  |
| tips_paid | double precision(53) | Sí |  |  |  |
| tips_differential | double precision(53) | Sí |  |  |  |
| pay_out_no | integer(32,0) | Sí |  |  |  |
| pay_out_amount | double precision(53) | Sí |  |  |  |
| drawer_bleed_no | integer(32,0) | Sí |  |  |  |
| drawer_bleed_amount | double precision(53) | Sí |  |  |  |
| drawer_accountable | double precision(53) | Sí |  |  |  |
| cash_to_deposit | double precision(53) | Sí |  |  |  |
| variance | double precision(53) | Sí |  |  |  |
| delivery_charge | double precision(53) | Sí |  |  |  |
| totalvoidwst | double precision(53) | Sí |  |  |  |
| totalvoid | double precision(53) | Sí |  |  |  |
| totaldiscountcount | integer(32,0) | Sí |  |  |  |
| totaldiscountamount | double precision(53) | Sí |  |  |  |
| totaldiscountsales | double precision(53) | Sí |  |  |  |
| totaldiscountguest | integer(32,0) | Sí |  |  |  |
| totaldiscountpartysize | integer(32,0) | Sí |  |  |  |
| totaldiscountchecksize | integer(32,0) | Sí |  |  |  |
| totaldiscountpercentage | double precision(53) | Sí |  |  |  |
| totaldiscountratio | double precision(53) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- drawer_pull_report_pkey: id

#### Llaves foráneas
- fkaec362202ad2d031: (terminal_id) ➜ public.terminal (id)
- fkaec362203e20ad51: (user_id) ➜ public.users (auto_id)

#### Índices
- drawer_pull_report_pkey [PK, UNIQUE] (id) USING BTREE
- drawer_report_time (report_time) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.drawer_pull_report_voidtickets
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk98cf9b143ef4cd9b) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| dpreport_id | integer(32,0) | No |  |  |  |
| code | integer(32,0) | Sí |  |  |  |
| reason | character varying(255) | Sí |  |  |  |
| hast | character varying(255) | Sí |  |  |  |
| quantity | integer(32,0) | Sí |  |  |  |
| amount | double precision(53) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk98cf9b143ef4cd9b: (dpreport_id) ➜ public.drawer_pull_report (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.employee_in_out_history
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk6d5db9fa2ad2d031, fk6d5db9fa3e20ad51, fk6d5db9fa7660a5e3) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('employee_in_out_history_id_seq'::regclass) | employee_in_out_history_id_seq |  |
| out_time | timestamp without time zone(6) | Sí |  |  |  |
| in_time | timestamp without time zone(6) | Sí |  |  |  |
| out_hour | smallint(16,0) | Sí |  |  |  |
| in_hour | smallint(16,0) | Sí |  |  |  |
| clock_out | boolean | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| shift_id | integer(32,0) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- employee_in_out_history_pkey: id

#### Llaves foráneas
- fk6d5db9fa2ad2d031: (terminal_id) ➜ public.terminal (id)
- fk6d5db9fa3e20ad51: (user_id) ➜ public.users (auto_id)
- fk6d5db9fa7660a5e3: (shift_id) ➜ public.shift (id)

#### Índices
- employee_in_out_history_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.global_config
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('global_config_id_seq'::regclass) | global_config_id_seq |  |
| pos_key | character varying(60) | Sí |  |  |  |
| pos_value | character varying(220) | Sí |  |  |  |

#### Llave primaria
- global_config_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- global_config_pkey [PK, UNIQUE] (id) USING BTREE
- global_config_pos_key_key [UNIQUE] (pos_key) USING BTREE

#### Restricciones UNIQUE
- global_config_pos_key_key: pos_key

#### Restricciones CHECK
- Sin restricciones CHECK

### public.gratuity
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk34e4e3771df2d7f1, fk34e4e3772ad2d031, fk34e4e377aa075d69) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('gratuity_id_seq'::regclass) | gratuity_id_seq |  |
| amount | double precision(53) | Sí |  |  |  |
| paid | boolean | Sí |  |  |  |
| refunded | boolean | Sí |  |  |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| owner_id | integer(32,0) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- gratuity_pkey: id

#### Llaves foráneas
- fk34e4e3771df2d7f1: (ticket_id) ➜ public.ticket (id)
- fk34e4e3772ad2d031: (terminal_id) ➜ public.terminal (id)
- fk34e4e377aa075d69: (owner_id) ➜ public.users (auto_id)

#### Índices
- gratuity_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.group_taxes
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkf8a37399d900aa01, fkf8a37399eff11066) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| group_id | character varying(128) | No |  |  |  |
| elt | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fkf8a37399d900aa01: (elt) ➜ public.tax (id)
- fkf8a37399eff11066: (group_id) ➜ public.tax_group (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.guest_check_print
- Descripción: sin comentario
- Filas estimadas: ~95
- Flags: faltan índices para FKs (fkce827c6f3e20ad51) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('guest_check_print_id_seq'::regclass) | guest_check_print_id_seq |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| table_no | character varying(255) | Sí |  |  |  |
| ticket_total | double precision(53) | Sí |  |  |  |
| print_time | timestamp without time zone(6) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- guest_check_print_pkey: id

#### Llaves foráneas
- fkce827c6f3e20ad51: (user_id) ➜ public.users (auto_id)

#### Índices
- guest_check_print_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_group
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_group_id_seq'::regclass) | inventory_group_id_seq |  |
| name | character varying(60) | No |  |  |  |
| visible | boolean | Sí |  |  |  |

#### Llave primaria
- inventory_group_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- inventory_group_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_item
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk7dc968362cd583c1, fk7dc968363525e956, fk7dc968366848d615, fk7dc9683695e455d3, fk7dc968369e60c333) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_item_id_seq'::regclass) | inventory_item_id_seq |  |
| create_time | timestamp without time zone(6) | Sí |  |  |  |
| last_update_date | timestamp without time zone(6) | Sí |  |  |  |
| name | character varying(60) | Sí |  |  |  |
| package_barcode | character varying(30) | Sí |  |  |  |
| unit_barcode | character varying(30) | Sí |  |  |  |
| unit_per_package | double precision(53) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| package_reorder_level | integer(32,0) | Sí |  |  |  |
| package_replenish_level | integer(32,0) | Sí |  |  |  |
| description | character varying(255) | Sí |  |  |  |
| average_package_price | double precision(53) | Sí |  |  |  |
| total_unit_packages | double precision(53) | Sí |  |  |  |
| total_recepie_units | double precision(53) | Sí |  |  |  |
| unit_purchase_price | double precision(53) | Sí |  |  |  |
| unit_selling_price | double precision(53) | Sí |  |  |  |
| visible | boolean | Sí |  |  |  |
| punit_id | integer(32,0) | Sí |  |  |  |
| recipe_unit_id | integer(32,0) | Sí |  |  |  |
| item_group_id | integer(32,0) | Sí |  |  |  |
| item_location_id | integer(32,0) | Sí |  |  |  |
| item_vendor_id | integer(32,0) | Sí |  |  |  |
| total_packages | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- inventory_item_pkey: id

#### Llaves foráneas
- fk7dc968362cd583c1: (item_group_id) ➜ public.inventory_group (id)
- fk7dc968363525e956: (punit_id) ➜ public.packaging_unit (id)
- fk7dc968366848d615: (recipe_unit_id) ➜ public.packaging_unit (id)
- fk7dc9683695e455d3: (item_location_id) ➜ public.inventory_location (id)
- fk7dc968369e60c333: (item_vendor_id) ➜ public.inventory_vendor (id)

#### Índices
- inventory_item_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_location
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk59073b58c46a9c15) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_location_id_seq'::regclass) | inventory_location_id_seq |  |
| name | character varying(60) | No |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| visible | boolean | Sí |  |  |  |
| warehouse_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- inventory_location_pkey: id

#### Llaves foráneas
- fk59073b58c46a9c15: (warehouse_id) ➜ public.inventory_warehouse (id)

#### Índices
- inventory_location_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_meta_code
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_meta_code_id_seq'::regclass) | inventory_meta_code_id_seq |  |
| type | character varying(255) | Sí |  |  |  |
| code_text | character varying(255) | Sí |  |  |  |
| code_no | integer(32,0) | Sí |  |  |  |
| description | character varying(255) | Sí |  |  |  |

#### Llave primaria
- inventory_meta_code_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- inventory_meta_code_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_transaction
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkaf48f43b5b397c5, fkaf48f43b96a3d6bf, fkaf48f43bd152c95f, fkaf48f43beda09759, fkaf48f43bff3f328a) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_transaction_id_seq'::regclass) | inventory_transaction_id_seq |  |
| transaction_date | timestamp without time zone(6) | Sí |  |  |  |
| unit_quantity | double precision(53) | Sí |  |  |  |
| unit_price | double precision(53) | Sí |  |  |  |
| remark | character varying(255) | Sí |  |  |  |
| tran_type | integer(32,0) | Sí |  |  |  |
| reference_id | integer(32,0) | Sí |  |  |  |
| item_id | integer(32,0) | Sí |  |  |  |
| vendor_id | integer(32,0) | Sí |  |  |  |
| from_warehouse_id | integer(32,0) | Sí |  |  |  |
| to_warehouse_id | integer(32,0) | Sí |  |  |  |
| quantity | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- inventory_transaction_pkey: id

#### Llaves foráneas
- fkaf48f43b5b397c5: (reference_id) ➜ public.purchase_order (id)
- fkaf48f43b96a3d6bf: (item_id) ➜ public.inventory_item (id)
- fkaf48f43bd152c95f: (vendor_id) ➜ public.inventory_vendor (id)
- fkaf48f43beda09759: (to_warehouse_id) ➜ public.inventory_warehouse (id)
- fkaf48f43bff3f328a: (from_warehouse_id) ➜ public.inventory_warehouse (id)

#### Índices
- inventory_transaction_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_unit
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_unit_id_seq'::regclass) | inventory_unit_id_seq |  |
| short_name | character varying(255) | Sí |  |  |  |
| long_name | character varying(255) | Sí |  |  |  |
| alt_name | character varying(255) | Sí |  |  |  |
| conv_factor1 | character varying(255) | Sí |  |  |  |
| conv_factor2 | character varying(255) | Sí |  |  |  |
| conv_factor3 | character varying(255) | Sí |  |  |  |

#### Llave primaria
- inventory_unit_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- inventory_unit_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_vendor
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_vendor_id_seq'::regclass) | inventory_vendor_id_seq |  |
| name | character varying(60) | No |  |  |  |
| visible | boolean | Sí |  |  |  |
| address | character varying(120) | No |  |  |  |
| city | character varying(60) | No |  |  |  |
| state | character varying(60) | No |  |  |  |
| zip | character varying(60) | No |  |  |  |
| country | character varying(60) | No |  |  |  |
| email | character varying(60) | No |  |  |  |
| phone | character varying(60) | No |  |  |  |
| fax | character varying(60) | Sí |  |  |  |

#### Llave primaria
- inventory_vendor_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- inventory_vendor_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.inventory_warehouse
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_warehouse_id_seq'::regclass) | inventory_warehouse_id_seq |  |
| name | character varying(60) | No |  |  |  |
| visible | boolean | Sí |  |  |  |

#### Llave primaria
- inventory_warehouse_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- inventory_warehouse_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.item_order_type
- Descripción: sin comentario
- Filas estimadas: ~90
- Flags: faltan índices para FKs (fke2b846573ac1d2e0, fke2b8465789fe23f0) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menu_item_id | integer(32,0) | No |  |  |  |
| order_type_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fke2b846573ac1d2e0: (order_type_id) ➜ public.order_type (id)
- fke2b8465789fe23f0: (menu_item_id) ➜ public.menu_item (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.kds_ready_log
- Descripción: sin comentario
- Filas estimadas: ~5
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| ticket_id | integer(32,0) | No |  |  |  |
| notified_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- kds_ready_log_pkey: ticket_id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- kds_ready_log_pkey [PK, UNIQUE] (ticket_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.kit_ticket_table_num
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk5696584bb73e273e) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| kit_ticket_id | integer(32,0) | No |  |  |  |
| table_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk5696584bb73e273e: (kit_ticket_id) ➜ public.kitchen_ticket (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.kitchen_ticket
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk341cbc275cf1375f) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('kitchen_ticket_id_seq'::regclass) | kitchen_ticket_id_seq |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| create_date | timestamp without time zone(6) | Sí |  |  |  |
| close_date | timestamp without time zone(6) | Sí |  |  |  |
| voided | boolean | Sí |  |  |  |
| sequence_number | integer(32,0) | Sí |  |  |  |
| status | character varying(30) | Sí |  |  |  |
| server_name | character varying(30) | Sí |  |  |  |
| ticket_type | character varying(20) | Sí |  |  |  |
| pg_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- kitchen_ticket_pkey: id

#### Llaves foráneas
- fk341cbc275cf1375f: (pg_id) ➜ public.printer_group (id)

#### Índices
- ix_kitchen_ticket_ticket_id (ticket_id) USING BTREE
- kitchen_ticket_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.kitchen_ticket_item
- Descripción: sin comentario
- Filas estimadas: ~1,691
- Flags: faltan índices para FKs (fk1462f02bcb07faa3) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('kitchen_ticket_item_id_seq'::regclass) | kitchen_ticket_item_id_seq |  |
| cookable | boolean | Sí |  |  |  |
| ticket_item_id | integer(32,0) | No |  |  |  |
| ticket_item_modifier_id | integer(32,0) | Sí |  |  |  |
| menu_item_code | character varying(255) | Sí |  |  |  |
| menu_item_name | character varying(120) | Sí |  |  |  |
| menu_item_group_id | integer(32,0) | Sí |  |  |  |
| menu_item_group_name | character varying(120) | Sí |  |  |  |
| quantity | integer(32,0) | Sí |  |  |  |
| fractional_quantity | double precision(53) | Sí |  |  |  |
| fractional_unit | boolean | Sí |  |  |  |
| unit_name | character varying(20) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| voided | boolean | Sí |  |  |  |
| status | character varying(30) | Sí |  |  |  |
| kithen_ticket_id | integer(32,0) | Sí |  |  |  |
| item_order | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- kitchen_ticket_item_pkey: id

#### Llaves foráneas
- fk1462f02bcb07faa3: (kithen_ticket_id) ➜ public.kitchen_ticket (id)

#### Índices
- ix_kitchen_ticket_item_item_id (ticket_item_id) USING BTREE
- kitchen_ticket_item_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_category
- Descripción: sin comentario
- Filas estimadas: ~7
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_category_id_seq'::regclass) | menu_category_id_seq |  |
| name | character varying(120) | No |  |  |  |
| translated_name | character varying(120) | Sí |  |  |  |
| visible | boolean | Sí |  |  |  |
| beverage | boolean | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| btn_color | integer(32,0) | Sí |  |  |  |
| text_color | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menu_category_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- food_category_visible (visible) USING BTREE
- menu_category_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_group
- Descripción: sin comentario
- Filas estimadas: ~23
- Flags: faltan índices para FKs (fk4dc1ab7f2e347ff0) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_group_id_seq'::regclass) | menu_group_id_seq |  |
| name | character varying(120) | No |  |  |  |
| translated_name | character varying(120) | Sí |  |  |  |
| visible | boolean | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| btn_color | integer(32,0) | Sí |  |  |  |
| text_color | integer(32,0) | Sí |  |  |  |
| category_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menu_group_pkey: id

#### Llaves foráneas
- fk4dc1ab7f2e347ff0: (category_id) ➜ public.menu_category (id)

#### Índices
- menu_group_pkey [PK, UNIQUE] (id) USING BTREE
- menugroupvisible (visible) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_item
- Descripción: sin comentario
- Filas estimadas: ~93
- Flags: faltan índices para FKs (fk4cd5a1f35188aa24, fk4cd5a1f35cf1375f, fk4cd5a1f35ee9f27a, fk4cd5a1f3a4802f83, fk4cd5a1f3f3b77c57) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_item_id_seq'::regclass) | menu_item_id_seq |  |
| name | character varying(120) | No |  |  |  |
| description | character varying(255) | Sí |  |  |  |
| unit_name | character varying(20) | Sí |  |  |  |
| translated_name | character varying(120) | Sí |  |  |  |
| barcode | character varying(120) | Sí |  |  |  |
| buy_price | double precision(53) | No |  |  |  |
| stock_amount | double precision(53) | Sí |  |  |  |
| price | double precision(53) | No |  |  |  |
| discount_rate | double precision(53) | Sí |  |  |  |
| visible | boolean | Sí |  |  |  |
| disable_when_stock_amount_is_zero | boolean | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| btn_color | integer(32,0) | Sí |  |  |  |
| text_color | integer(32,0) | Sí |  |  |  |
| image | bytea | Sí |  |  |  |
| show_image_only | boolean | Sí |  |  |  |
| fractional_unit | boolean | Sí |  |  |  |
| pizza_type | boolean | Sí |  |  |  |
| default_sell_portion | integer(32,0) | Sí |  |  |  |
| group_id | integer(32,0) | Sí |  |  |  |
| tax_group_id | character varying(128) | Sí |  |  |  |
| recepie | integer(32,0) | Sí |  |  |  |
| pg_id | integer(32,0) | Sí |  |  |  |
| tax_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menu_item_pkey: id

#### Llaves foráneas
- fk4cd5a1f35188aa24: (group_id) ➜ public.menu_group (id)
- fk4cd5a1f35cf1375f: (pg_id) ➜ public.printer_group (id)
- fk4cd5a1f35ee9f27a: (tax_group_id) ➜ public.tax_group (id)
- fk4cd5a1f3a4802f83: (tax_id) ➜ public.tax (id)
- fk4cd5a1f3f3b77c57: (recepie) ➜ public.recepie (id)

#### Índices
- menu_item_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_item_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menu_item_id | integer(32,0) | No |  |  |  |
| property_value | character varying(100) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- menu_item_properties_pkey: menu_item_id, property_name

#### Llaves foráneas
- fkf94186ff89fe23f0: (menu_item_id) ➜ public.menu_item (id)

#### Índices
- menu_item_properties_pkey [PK, UNIQUE] (menu_item_id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_item_size
- Descripción: sin comentario
- Filas estimadas: ~3
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_item_size_id_seq'::regclass) | menu_item_size_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| translated_name | character varying(60) | Sí |  |  |  |
| description | character varying(120) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| size_in_inch | double precision(53) | Sí |  |  |  |
| default_size | boolean | Sí |  |  |  |

#### Llave primaria
- menu_item_size_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- menu_item_size_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_item_terminal_ref
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk9ea1afc2ad2d031, fk9ea1afc89fe23f0) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menu_item_id | integer(32,0) | No |  |  |  |
| terminal_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk9ea1afc2ad2d031: (terminal_id) ➜ public.terminal (id)
- fk9ea1afc89fe23f0: (menu_item_id) ➜ public.menu_item (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_modifier
- Descripción: sin comentario
- Filas estimadas: ~165
- Flags: faltan índices para FKs (fk59b6b1b72501cb2c, fk59b6b1b75e0c7b8d, fk59b6b1b7a4802f83) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_modifier_id_seq'::regclass) | menu_modifier_id_seq |  |
| name | character varying(120) | Sí |  |  |  |
| translated_name | character varying(120) | Sí |  |  |  |
| price | double precision(53) | Sí |  |  |  |
| extra_price | double precision(53) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| btn_color | integer(32,0) | Sí |  |  |  |
| text_color | integer(32,0) | Sí |  |  |  |
| enable | boolean | Sí |  |  |  |
| fixed_price | boolean | Sí |  |  |  |
| print_to_kitchen | boolean | Sí |  |  |  |
| section_wise_pricing | boolean | Sí |  |  |  |
| pizza_modifier | boolean | Sí |  |  |  |
| group_id | integer(32,0) | Sí |  |  |  |
| tax_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menu_modifier_pkey: id

#### Llaves foráneas
- fk59b6b1b72501cb2c: (group_id) ➜ public.menu_modifier_group (id)
- fk59b6b1b75e0c7b8d: (group_id) ➜ public.menu_modifier_group (id)
- fk59b6b1b7a4802f83: (tax_id) ➜ public.tax (id)

#### Índices
- menu_modifier_pkey [PK, UNIQUE] (id) USING BTREE
- modifierenabled (enable) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_modifier_group
- Descripción: sin comentario
- Filas estimadas: ~49
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menu_modifier_group_id_seq'::regclass) | menu_modifier_group_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| translated_name | character varying(60) | Sí |  |  |  |
| enabled | boolean | Sí |  |  |  |
| exclusived | boolean | Sí |  |  |  |
| required | boolean | Sí |  |  |  |

#### Llave primaria
- menu_modifier_group_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- menu_modifier_group_pkey [PK, UNIQUE] (id) USING BTREE
- mg_enable (enabled) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menu_modifier_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menu_modifier_id | integer(32,0) | No |  |  |  |
| property_value | character varying(100) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- menu_modifier_properties_pkey: menu_modifier_id, property_name

#### Llaves foráneas
- fk1273b4bbb79c6270: (menu_modifier_id) ➜ public.menu_modifier (id)

#### Índices
- menu_modifier_properties_pkey [PK, UNIQUE] (menu_modifier_id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menucategory_discount
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk4f8523e38d9ea931, fk4f8523e3d3e91e11) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| discount_id | integer(32,0) | No |  |  |  |
| menucategory_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk4f8523e38d9ea931: (menucategory_id) ➜ public.menu_category (id)
- fk4f8523e3d3e91e11: (discount_id) ➜ public.coupon_and_discount (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menugroup_discount
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fke3790e40113bf083, fke3790e40d3e91e11) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| discount_id | integer(32,0) | No |  |  |  |
| menugroup_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fke3790e40113bf083: (menugroup_id) ➜ public.menu_group (id)
- fke3790e40d3e91e11: (discount_id) ➜ public.coupon_and_discount (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menuitem_discount
- Descripción: sin comentario
- Filas estimadas: ~78
- Flags: faltan índices para FKs (fkd89ccdee33662891, fkd89ccdeed3e91e11) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| discount_id | integer(32,0) | No |  |  |  |
| menuitem_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fkd89ccdee33662891: (menuitem_id) ➜ public.menu_item (id)
- fkd89ccdeed3e91e11: (discount_id) ➜ public.coupon_and_discount (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menuitem_modifiergroup
- Descripción: sin comentario
- Filas estimadas: ~62
- Flags: faltan índices para FKs (fk312b355b40fda3c9, fk312b355b6e7b8b68, fk312b355b7f2f368) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menuitem_modifiergroup_id_seq'::regclass) | menuitem_modifiergroup_id_seq |  |
| min_quantity | integer(32,0) | Sí |  |  |  |
| max_quantity | integer(32,0) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| modifier_group | integer(32,0) | Sí |  |  |  |
| menuitem_modifiergroup_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menuitem_modifiergroup_pkey: id

#### Llaves foráneas
- fk312b355b40fda3c9: (modifier_group) ➜ public.menu_modifier_group (id)
- fk312b355b6e7b8b68: (menuitem_modifiergroup_id) ➜ public.menu_item (id)
- fk312b355b7f2f368: (modifier_group) ➜ public.menu_modifier_group (id)

#### Índices
- menuitem_modifiergroup_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menuitem_pizzapirce
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk17bd51a089fe23f0, fk17bd51a0ae5d580) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menu_item_id | integer(32,0) | No |  |  |  |
| pizza_price_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk17bd51a089fe23f0: (menu_item_id) ➜ public.menu_item (id)
- fk17bd51a0ae5d580: (pizza_price_id) ➜ public.pizza_price (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menuitem_shift
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fke03c92d533662891, fke03c92d57660a5e3) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('menuitem_shift_id_seq'::regclass) | menuitem_shift_id_seq |  |
| shift_price | double precision(53) | Sí |  |  |  |
| shift_id | integer(32,0) | Sí |  |  |  |
| menuitem_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- menuitem_shift_pkey: id

#### Llaves foráneas
- fke03c92d533662891: (menuitem_id) ➜ public.menu_item (id)
- fke03c92d57660a5e3: (shift_id) ➜ public.shift (id)

#### Índices
- menuitem_shift_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.menumodifier_pizzamodifierprice
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk572726f374be2c71, fk572726f3ae3f2e91) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| menumodifier_id | integer(32,0) | No |  |  |  |
| pizzamodifierprice_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk572726f374be2c71: (pizzamodifierprice_id) ➜ public.pizza_modifier_price (id)
- fk572726f3ae3f2e91: (menumodifier_id) ➜ public.menu_modifier (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.migrations
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('public.migrations_id_seq'::regclass) | public.migrations_id_seq |  |
| migration | character varying(255) | No |  |  |  |
| batch | integer(32,0) | No |  |  |  |

#### Llave primaria
- migrations_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- migrations_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.modifier_multiplier_price
- Descripción: sin comentario
- Filas estimadas: ~63
- Flags: faltan índices para FKs (fk8a16099391d62c51, fk8a1609939c9e4883, fk8a160993ae3f2e91) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('modifier_multiplier_price_id_seq'::regclass) | modifier_multiplier_price_id_seq |  |
| price | double precision(53) | Sí |  |  |  |
| multiplier_id | character varying(20) | Sí |  |  |  |
| menumodifier_id | integer(32,0) | Sí |  |  |  |
| pizza_modifier_price_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- modifier_multiplier_price_pkey: id

#### Llaves foráneas
- fk8a16099391d62c51: (multiplier_id) ➜ public.multiplier (name)
- fk8a1609939c9e4883: (pizza_modifier_price_id) ➜ public.pizza_modifier_price (id)
- fk8a160993ae3f2e91: (menumodifier_id) ➜ public.menu_modifier (id)

#### Índices
- modifier_multiplier_price_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.multiplier
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| name | character varying(20) | No |  |  |  |
| ticket_prefix | character varying(20) | Sí |  |  |  |
| rate | double precision(53) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| default_multiplier | boolean | Sí |  |  |  |
| main | boolean | Sí |  |  |  |
| btn_color | integer(32,0) | Sí |  |  |  |
| text_color | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- multiplier_pkey: name

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- multiplier_pkey [PK, UNIQUE] (name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.order_type
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('order_type_id_seq'::regclass) | order_type_id_seq |  |
| name | character varying(120) | No |  |  |  |
| enabled | boolean | Sí |  |  |  |
| show_table_selection | boolean | Sí |  |  |  |
| show_guest_selection | boolean | Sí |  |  |  |
| should_print_to_kitchen | boolean | Sí |  |  |  |
| prepaid | boolean | Sí |  |  |  |
| close_on_paid | boolean | Sí |  |  |  |
| required_customer_data | boolean | Sí |  |  |  |
| delivery | boolean | Sí |  |  |  |
| show_item_barcode | boolean | Sí |  |  |  |
| show_in_login_screen | boolean | Sí |  |  |  |
| consolidate_tiems_in_receipt | boolean | Sí |  |  |  |
| allow_seat_based_order | boolean | Sí |  |  |  |
| hide_item_with_empty_inventory | boolean | Sí |  |  |  |
| has_forhere_and_togo | boolean | Sí |  |  |  |
| pre_auth_credit_card | boolean | Sí |  |  |  |
| bar_tab | boolean | Sí |  |  |  |
| retail_order | boolean | Sí |  |  |  |
| show_price_on_button | boolean | Sí |  |  |  |
| show_stock_count_on_button | boolean | Sí |  |  |  |
| show_unit_price_in_ticket_grid | boolean | Sí |  |  |  |
| properties | text | Sí |  |  |  |

#### Llave primaria
- order_type_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- order_type_name_key [UNIQUE] (name) USING BTREE
- order_type_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- order_type_name_key: name

#### Restricciones CHECK
- Sin restricciones CHECK

### public.packaging_unit
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('packaging_unit_id_seq'::regclass) | packaging_unit_id_seq |  |
| name | character varying(30) | Sí |  |  |  |
| short_name | character varying(10) | Sí |  |  |  |
| factor | double precision(53) | Sí |  |  |  |
| baseunit | boolean | Sí |  |  |  |
| dimension | character varying(30) | Sí |  |  |  |

#### Llave primaria
- packaging_unit_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- packaging_unit_name_key [UNIQUE] (name) USING BTREE
- packaging_unit_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- packaging_unit_name_key: name

#### Restricciones CHECK
- Sin restricciones CHECK

### public.payout_reasons
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('payout_reasons_id_seq'::regclass) | payout_reasons_id_seq |  |
| reason | character varying(255) | Sí |  |  |  |

#### Llave primaria
- payout_reasons_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- payout_reasons_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.payout_recepients
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('payout_recepients_id_seq'::regclass) | payout_recepients_id_seq |  |
| name | character varying(255) | Sí |  |  |  |

#### Llave primaria
- payout_recepients_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- payout_recepients_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.pizza_crust
- Descripción: sin comentario
- Filas estimadas: ~2
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('pizza_crust_id_seq'::regclass) | pizza_crust_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| translated_name | character varying(60) | Sí |  |  |  |
| description | character varying(120) | Sí |  |  |  |
| sort_order | integer(32,0) | Sí |  |  |  |
| default_crust | boolean | Sí |  |  |  |

#### Llave primaria
- pizza_crust_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- pizza_crust_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.pizza_modifier_price
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkd3de7e7896183657) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('pizza_modifier_price_id_seq'::regclass) | pizza_modifier_price_id_seq |  |
| item_size | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- pizza_modifier_price_pkey: id

#### Llaves foráneas
- fkd3de7e7896183657: (item_size) ➜ public.menu_item_size (id)

#### Índices
- pizza_modifier_price_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.pizza_price
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkeac112927c59441d, fkeac11292a56d141c, fkeac11292dd545b77) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('pizza_price_id_seq'::regclass) | pizza_price_id_seq |  |
| price | double precision(53) | Sí |  |  |  |
| menu_item_size | integer(32,0) | Sí |  |  |  |
| crust | integer(32,0) | Sí |  |  |  |
| order_type | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- pizza_price_pkey: id

#### Llaves foráneas
- fkeac112927c59441d: (crust) ➜ public.pizza_crust (id)
- fkeac11292a56d141c: (order_type) ➜ public.order_type (id)
- fkeac11292dd545b77: (menu_item_size) ➜ public.menu_item_size (id)

#### Índices
- pizza_price_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.printer_configuration
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| receipt_printer | character varying(255) | Sí |  |  |  |
| kitchen_printer | character varying(255) | Sí |  |  |  |
| prwts | boolean | Sí |  |  |  |
| prwtp | boolean | Sí |  |  |  |
| pkwts | boolean | Sí |  |  |  |
| pkwtp | boolean | Sí |  |  |  |
| unpft | boolean | Sí |  |  |  |
| unpfk | boolean | Sí |  |  |  |

#### Llave primaria
- printer_configuration_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- printer_configuration_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.printer_group
- Descripción: sin comentario
- Filas estimadas: ~2
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('printer_group_id_seq'::regclass) | printer_group_id_seq |  |
| name | character varying(60) | No |  |  |  |
| is_default | boolean | Sí |  |  |  |

#### Llave primaria
- printer_group_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- printer_group_name_key [UNIQUE] (name) USING BTREE
- printer_group_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- printer_group_name_key: name

#### Restricciones CHECK
- Sin restricciones CHECK

### public.printer_group_printers
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkc05b805e5f31265c) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| printer_id | integer(32,0) | No |  |  |  |
| printer_name | character varying(255) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fkc05b805e5f31265c: (printer_id) ➜ public.printer_group (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.purchase_order
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('purchase_order_id_seq'::regclass) | purchase_order_id_seq |  |
| order_id | character varying(30) | Sí |  |  |  |
| name | character varying(30) | Sí |  |  |  |

#### Llave primaria
- purchase_order_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- purchase_order_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.recepie
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk6b4e177764931efc) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('recepie_id_seq'::regclass) | recepie_id_seq |  |
| menu_item | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- recepie_pkey: id

#### Llaves foráneas
- fk6b4e177764931efc: (menu_item) ➜ public.menu_item (id)

#### Índices
- recepie_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.recepie_item
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk855626db1682b10e, fk855626dbcae89b83) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('recepie_item_id_seq'::regclass) | recepie_item_id_seq |  |
| percentage | double precision(53) | Sí |  |  |  |
| inventory_deductable | boolean | Sí |  |  |  |
| inventory_item | integer(32,0) | Sí |  |  |  |
| recepie_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- recepie_item_pkey: id

#### Llaves foráneas
- fk855626db1682b10e: (inventory_item) ➜ public.inventory_item (id)
- fk855626dbcae89b83: (recepie_id) ➜ public.recepie (id)

#### Índices
- recepie_item_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.restaurant
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| unique_id | integer(32,0) | Sí |  |  |  |
| name | character varying(120) | Sí |  |  |  |
| address_line1 | character varying(60) | Sí |  |  |  |
| address_line2 | character varying(60) | Sí |  |  |  |
| address_line3 | character varying(60) | Sí |  |  |  |
| zip_code | character varying(10) | Sí |  |  |  |
| telephone | character varying(16) | Sí |  |  |  |
| capacity | integer(32,0) | Sí |  |  |  |
| tables | integer(32,0) | Sí |  |  |  |
| cname | character varying(20) | Sí |  |  |  |
| csymbol | character varying(10) | Sí |  |  |  |
| sc_percentage | double precision(53) | Sí |  |  |  |
| gratuity_percentage | double precision(53) | Sí |  |  |  |
| ticket_footer | character varying(60) | Sí |  |  |  |
| price_includes_tax | boolean | Sí |  |  |  |
| allow_modifier_max_exceed | boolean | Sí |  |  |  |

#### Llave primaria
- restaurant_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- restaurant_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.restaurant_properties
- Descripción: sin comentario
- Filas estimadas: ~3
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(1000) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- restaurant_properties_pkey: id, property_name

#### Llaves foráneas
- fk80ad9f75fc64768f: (id) ➜ public.restaurant (id)

#### Índices
- restaurant_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shift
- Descripción: sin comentario
- Filas estimadas: ~1
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('shift_id_seq'::regclass) | shift_id_seq |  |
| name | character varying(60) | No |  |  |  |
| start_time | timestamp without time zone(6) | Sí |  |  |  |
| end_time | timestamp without time zone(6) | Sí |  |  |  |
| shift_len | bigint(64,0) | Sí |  |  |  |

#### Llave primaria
- shift_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- shift_name_key [UNIQUE] (name) USING BTREE
- shift_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- shift_name_key: name

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_floor
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('shop_floor_id_seq'::regclass) | shop_floor_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| occupied | boolean | Sí |  |  |  |
| image | oid | Sí |  |  |  |

#### Llave primaria
- shop_floor_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- shop_floor_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_floor_template
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkba6efbd68979c3cd) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('shop_floor_template_id_seq'::regclass) | shop_floor_template_id_seq |  |
| name | character varying(60) | Sí |  |  |  |
| default_floor | boolean | Sí |  |  |  |
| main | boolean | Sí |  |  |  |
| floor_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- shop_floor_template_pkey: id

#### Llaves foráneas
- fkba6efbd68979c3cd: (floor_id) ➜ public.shop_floor (id)

#### Índices
- shop_floor_template_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_floor_template_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(60) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- shop_floor_template_properties_pkey: id, property_name

#### Llaves foráneas
- fkd70c313ca36ab054: (id) ➜ public.shop_floor_template (id)

#### Índices
- shop_floor_template_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_table
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk2458e9258979c3cd) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| name | character varying(20) | Sí |  |  |  |
| description | character varying(60) | Sí |  |  |  |
| capacity | integer(32,0) | Sí |  |  |  |
| x | integer(32,0) | Sí |  |  |  |
| y | integer(32,0) | Sí |  |  |  |
| floor_id | integer(32,0) | Sí |  |  |  |
| free | boolean | Sí |  |  |  |
| serving | boolean | Sí |  |  |  |
| booked | boolean | Sí |  |  |  |
| dirty | boolean | Sí |  |  |  |
| disable | boolean | Sí |  |  |  |

#### Llave primaria
- shop_table_pkey: id

#### Llaves foráneas
- fk2458e9258979c3cd: (floor_id) ➜ public.shop_floor (id)

#### Índices
- shop_table_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_table_status
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| table_status | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- shop_table_status_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- shop_table_status_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.shop_table_type
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('shop_table_type_id_seq'::regclass) | shop_table_type_id_seq |  |
| description | character varying(120) | Sí |  |  |  |
| name | character varying(40) | Sí |  |  |  |

#### Llave primaria
- shop_table_type_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- shop_table_type_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.table_booking_info
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk301c4de53e20ad51, fk301c4de59e1c3cf1) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('table_booking_info_id_seq'::regclass) | table_booking_info_id_seq |  |
| from_date | timestamp without time zone(6) | Sí |  |  |  |
| to_date | timestamp without time zone(6) | Sí |  |  |  |
| guest_count | integer(32,0) | Sí |  |  |  |
| status | character varying(30) | Sí |  |  |  |
| payment_status | character varying(30) | Sí |  |  |  |
| booking_confirm | character varying(30) | Sí |  |  |  |
| booking_charge | double precision(53) | Sí |  |  |  |
| remaining_balance | double precision(53) | Sí |  |  |  |
| paid_amount | double precision(53) | Sí |  |  |  |
| booking_id | character varying(30) | Sí |  |  |  |
| booking_type | character varying(30) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| customer_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- table_booking_info_pkey: id

#### Llaves foráneas
- fk301c4de53e20ad51: (user_id) ➜ public.users (auto_id)
- fk301c4de59e1c3cf1: (customer_id) ➜ public.customer (auto_id)

#### Índices
- fromdate (from_date) USING BTREE
- table_booking_info_pkey [PK, UNIQUE] (id) USING BTREE
- todate (to_date) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.table_booking_mapping
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk6bc51417160de3b1, fk6bc51417dc46948d) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| booking_id | integer(32,0) | No |  |  |  |
| table_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk6bc51417160de3b1: (booking_id) ➜ public.table_booking_info (id)
- fk6bc51417dc46948d: (table_id) ➜ public.shop_table (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.table_ticket_num
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fkcbeff0e454031ec1) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| shop_table_status_id | integer(32,0) | No |  |  |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| user_name | character varying(30) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fkcbeff0e454031ec1: (shop_table_status_id) ➜ public.shop_table_status (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.table_type_relation
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk93802290dc46948d, fk93802290f5d6e47b) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| table_id | integer(32,0) | No |  |  |  |
| type_id | integer(32,0) | No |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk93802290dc46948d: (table_id) ➜ public.shop_table (id)
- fk93802290f5d6e47b: (type_id) ➜ public.shop_table_type (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.tax
- Descripción: sin comentario
- Filas estimadas: ~2
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('tax_id_seq'::regclass) | tax_id_seq |  |
| name | character varying(20) | No |  |  |  |
| rate | double precision(53) | Sí |  |  |  |

#### Llave primaria
- tax_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- tax_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.tax_group
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | character varying(128) | No |  |  |  |
| name | character varying(20) | No |  |  |  |

#### Llave primaria
- tax_group_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- tax_group_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.terminal
- Descripción: sin comentario
- Filas estimadas: ~8
- Flags: faltan índices para FKs (fke83d827c969c6de) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| name | character varying(60) | Sí |  |  |  |
| terminal_key | character varying(120) | Sí |  |  |  |
| opening_balance | double precision(53) | Sí |  |  |  |
| current_balance | double precision(53) | Sí |  |  |  |
| has_cash_drawer | boolean | Sí |  |  |  |
| in_use | boolean | Sí |  |  |  |
| active | boolean | Sí |  |  |  |
| location | character varying(320) | Sí |  |  |  |
| floor_id | integer(32,0) | Sí |  |  |  |
| assigned_user | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- terminal_pkey: id

#### Llaves foráneas
- fke83d827c969c6de: (assigned_user) ➜ public.users (auto_id)

#### Índices
- terminal_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.terminal_printers
- Descripción: sin comentario
- Filas estimadas: ~9
- Flags: faltan índices para FKs (fk99ede5fc2ad2d031, fk99ede5fcc433e65a) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('terminal_printers_id_seq'::regclass) | terminal_printers_id_seq |  |
| terminal_id | integer(32,0) | Sí |  |  |  |
| printer_name | character varying(60) | Sí |  |  |  |
| virtual_printer_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- terminal_printers_pkey: id

#### Llaves foráneas
- fk99ede5fc2ad2d031: (terminal_id) ➜ public.terminal (id)
- fk99ede5fcc433e65a: (virtual_printer_id) ➜ public.virtual_printer (id)

#### Índices
- terminal_printers_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.terminal_properties
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(255) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- terminal_properties_pkey: id, property_name

#### Llaves foráneas
- fk963f26d69d31df8e: (id) ➜ public.terminal (id)

#### Índices
- terminal_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket
- Descripción: sin comentario
- Filas estimadas: ~11,633
- Flags: faltan índices para FKs (fk937b5f0c1f6a9a4a, fk937b5f0c2ad2d031, fk937b5f0c7660a5e3, fk937b5f0caa075d69, fk937b5f0cc188ea51, fk937b5f0cf575c7d4) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('ticket_id_seq'::regclass) | ticket_id_seq |  |
| global_id | character varying(16) | Sí |  |  |  |
| create_date | timestamp without time zone(6) | Sí |  |  |  |
| closing_date | timestamp without time zone(6) | Sí |  |  |  |
| active_date | timestamp without time zone(6) | Sí |  |  |  |
| deliveery_date | timestamp without time zone(6) | Sí |  |  |  |
| creation_hour | integer(32,0) | Sí |  |  |  |
| paid | boolean | Sí |  |  |  |
| voided | boolean | Sí |  |  |  |
| void_reason | character varying(255) | Sí |  |  |  |
| wasted | boolean | Sí |  |  |  |
| refunded | boolean | Sí |  |  |  |
| settled | boolean | Sí |  |  |  |
| drawer_resetted | boolean | Sí |  |  |  |
| sub_total | double precision(53) | Sí |  |  |  |
| total_discount | double precision(53) | Sí |  |  |  |
| total_tax | double precision(53) | Sí |  |  |  |
| total_price | double precision(53) | Sí |  |  |  |
| paid_amount | double precision(53) | Sí |  |  |  |
| due_amount | double precision(53) | Sí |  |  |  |
| advance_amount | double precision(53) | Sí |  |  |  |
| adjustment_amount | double precision(53) | Sí |  |  |  |
| number_of_guests | integer(32,0) | Sí |  |  |  |
| status | character varying(30) | Sí |  |  |  |
| bar_tab | boolean | Sí |  |  |  |
| is_tax_exempt | boolean | Sí |  |  |  |
| is_re_opened | boolean | Sí |  |  |  |
| service_charge | double precision(53) | Sí |  |  |  |
| delivery_charge | double precision(53) | Sí |  |  |  |
| customer_id | integer(32,0) | Sí |  |  |  |
| delivery_address | character varying(120) | Sí |  |  |  |
| customer_pickeup | boolean | Sí |  |  |  |
| delivery_extra_info | character varying(255) | Sí |  |  |  |
| ticket_type | character varying(20) | Sí |  |  |  |
| shift_id | integer(32,0) | Sí |  |  |  |
| owner_id | integer(32,0) | Sí |  |  |  |
| driver_id | integer(32,0) | Sí |  |  |  |
| gratuity_id | integer(32,0) | Sí |  |  |  |
| void_by_user | integer(32,0) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |
| folio_date | date | Sí |  |  |  |
| branch_key | text | Sí |  |  |  |
| daily_folio | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- ticket_pkey: id

#### Llaves foráneas
- fk937b5f0c1f6a9a4a: (void_by_user) ➜ public.users (auto_id)
- fk937b5f0c2ad2d031: (terminal_id) ➜ public.terminal (id)
- fk937b5f0c7660a5e3: (shift_id) ➜ public.shift (id)
- fk937b5f0caa075d69: (owner_id) ➜ public.users (auto_id)
- fk937b5f0cc188ea51: (gratuity_id) ➜ public.gratuity (id)
- fk937b5f0cf575c7d4: (driver_id) ➜ public.users (auto_id)

#### Índices
- creationhour (creation_hour) USING BTREE
- deliverydate (deliveery_date) USING BTREE
- drawerresetted (drawer_resetted) USING BTREE
- idx_ticket_close_term_owner (closing_date, terminal_id, owner_id) USING BTREE
- ix_ticket_branch_key (branch_key) USING BTREE
- ix_ticket_folio_date (folio_date) USING BTREE
- ticket_global_id_key [UNIQUE] (global_id) USING BTREE
- ticket_pkey [PK, UNIQUE] (id) USING BTREE
- ticketactivedate (active_date) USING BTREE
- ticketclosingdate (closing_date) USING BTREE
- ticketcreatedate (create_date) USING BTREE
- ticketpaid (paid) USING BTREE
- ticketsettled (settled) USING BTREE
- ticketvoided (voided) USING BTREE
- ux_ticket_dailyfolio [UNIQUE, PARCIAL] (folio_date, branch_key, daily_folio) USING BTREE WHERE (daily_folio IS NOT NULL)

#### Restricciones UNIQUE
- ticket_global_id_key: global_id

#### Restricciones CHECK
- ck_ticket_daily_folio_positive: CHECK (daily_folio IS NULL OR daily_folio > 0)

### public.ticket_discount
- Descripción: sin comentario
- Filas estimadas: ~54
- Flags: faltan índices para FKs (fk1fa465141df2d7f1) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('ticket_discount_id_seq'::regclass) | ticket_discount_id_seq |  |
| discount_id | integer(32,0) | Sí |  |  |  |
| name | character varying(30) | Sí |  |  |  |
| type | integer(32,0) | Sí |  |  |  |
| auto_apply | boolean | Sí |  |  |  |
| minimum_amount | integer(32,0) | Sí |  |  |  |
| value | double precision(53) | Sí |  |  |  |
| ticket_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- ticket_discount_pkey: id

#### Llaves foráneas
- fk1fa465141df2d7f1: (ticket_id) ➜ public.ticket (id)

#### Índices
- ticket_discount_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item
- Descripción: sin comentario
- Filas estimadas: ~20,406
- Flags: faltan índices para FKs (fk979f546633e5d3b2, fk979f54665cf1375f) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('ticket_item_id_seq'::regclass) | ticket_item_id_seq |  |
| item_id | integer(32,0) | Sí |  |  |  |
| item_count | integer(32,0) | Sí |  |  |  |
| item_quantity | double precision(53) | Sí |  |  |  |
| item_name | character varying(120) | Sí |  |  |  |
| item_unit_name | character varying(20) | Sí |  |  |  |
| group_name | character varying(120) | Sí |  |  |  |
| category_name | character varying(120) | Sí |  |  |  |
| item_price | double precision(53) | Sí |  |  |  |
| item_tax_rate | double precision(53) | Sí |  |  |  |
| sub_total | double precision(53) | Sí |  |  |  |
| sub_total_without_modifiers | double precision(53) | Sí |  |  |  |
| discount | double precision(53) | Sí |  |  |  |
| tax_amount | double precision(53) | Sí |  |  |  |
| tax_amount_without_modifiers | double precision(53) | Sí |  |  |  |
| total_price | double precision(53) | Sí |  |  |  |
| total_price_without_modifiers | double precision(53) | Sí |  |  |  |
| beverage | boolean | Sí |  |  |  |
| inventory_handled | boolean | Sí |  |  |  |
| print_to_kitchen | boolean | Sí |  |  |  |
| treat_as_seat | boolean | Sí |  |  |  |
| seat_number | integer(32,0) | Sí |  |  |  |
| fractional_unit | boolean | Sí |  |  |  |
| has_modiiers | boolean | Sí |  |  |  |
| printed_to_kitchen | boolean | Sí |  |  |  |
| status | character varying(255) | Sí |  |  |  |
| stock_amount_adjusted | boolean | Sí |  |  |  |
| pizza_type | boolean | Sí |  |  |  |
| size_modifier_id | integer(32,0) | Sí |  |  |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| pg_id | integer(32,0) | Sí |  |  |  |
| pizza_section_mode | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- ticket_item_pkey: id

#### Llaves foráneas
- fk979f54661df2d7f1: (ticket_id) ➜ public.ticket (id)
- fk979f546633e5d3b2: (size_modifier_id) ➜ public.ticket_item_modifier (id)
- fk979f54665cf1375f: (pg_id) ➜ public.printer_group (id)

#### Índices
- ix_ticket_item_ticket_pg (ticket_id, pg_id) USING BTREE
- ticket_item_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item_addon_relation
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk9f1996346c108ef0) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| ticket_item_id | integer(32,0) | No |  |  |  |
| modifier_id | integer(32,0) | No |  |  |  |
| list_order | integer(32,0) | No |  |  |  |

#### Llave primaria
- ticket_item_addon_relation_pkey: ticket_item_id, list_order

#### Llaves foráneas
- fk9f1996346c108ef0: (modifier_id) ➜ public.ticket_item_modifier (id)
- fk9f199634dec6120a: (ticket_item_id) ➜ public.ticket_item (id)

#### Índices
- ticket_item_addon_relation_pkey [PK, UNIQUE] (ticket_item_id, list_order) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item_cooking_instruction
- Descripción: sin comentario
- Filas estimadas: ~10,989
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| ticket_item_id | integer(32,0) | No |  |  |  |
| description | character varying(60) | Sí |  |  |  |
| printedtokitchen | boolean | Sí |  |  |  |
| item_order | integer(32,0) | No |  |  |  |

#### Llave primaria
- ticket_item_cooking_instruction_pkey: ticket_item_id, item_order

#### Llaves foráneas
- fk3825f9d0dec6120a: (ticket_item_id) ➜ public.ticket_item (id)

#### Índices
- ticket_item_cooking_instruction_pkey [PK, UNIQUE] (ticket_item_id, item_order) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item_discount
- Descripción: sin comentario
- Filas estimadas: ~146
- Flags: faltan índices para FKs (fk3df5d4fab9276e77) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('ticket_item_discount_id_seq'::regclass) | ticket_item_discount_id_seq |  |
| discount_id | integer(32,0) | Sí |  |  |  |
| name | character varying(30) | Sí |  |  |  |
| type | integer(32,0) | Sí |  |  |  |
| auto_apply | boolean | Sí |  |  |  |
| minimum_quantity | integer(32,0) | Sí |  |  |  |
| value | double precision(53) | Sí |  |  |  |
| amount | double precision(53) | Sí |  |  |  |
| ticket_itemid | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- ticket_item_discount_pkey: id

#### Llaves foráneas
- fk3df5d4fab9276e77: (ticket_itemid) ➜ public.ticket_item (id)

#### Índices
- ticket_item_discount_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item_modifier
- Descripción: sin comentario
- Filas estimadas: ~11,816
- Flags: faltan índices para FKs (fk8fd6290dec6120a) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('ticket_item_modifier_id_seq'::regclass) | ticket_item_modifier_id_seq |  |
| item_id | integer(32,0) | Sí |  |  |  |
| group_id | integer(32,0) | Sí |  |  |  |
| item_count | integer(32,0) | Sí |  |  |  |
| modifier_name | character varying(120) | Sí |  |  |  |
| modifier_price | double precision(53) | Sí |  |  |  |
| modifier_tax_rate | double precision(53) | Sí |  |  |  |
| modifier_type | integer(32,0) | Sí |  |  |  |
| subtotal_price | double precision(53) | Sí |  |  |  |
| total_price | double precision(53) | Sí |  |  |  |
| tax_amount | double precision(53) | Sí |  |  |  |
| info_only | boolean | Sí |  |  |  |
| section_name | character varying(20) | Sí |  |  |  |
| multiplier_name | character varying(20) | Sí |  |  |  |
| print_to_kitchen | boolean | Sí |  |  |  |
| section_wise_pricing | boolean | Sí |  |  |  |
| status | character varying(10) | Sí |  |  |  |
| printed_to_kitchen | boolean | Sí |  |  |  |
| ticket_item_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- ticket_item_modifier_pkey: id

#### Llaves foráneas
- fk8fd6290dec6120a: (ticket_item_id) ➜ public.ticket_item (id)

#### Índices
- ticket_item_modifier_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_item_modifier_relation
- Descripción: sin comentario
- Filas estimadas: ~11,816
- Flags: faltan índices para FKs (fk5d3f9acb6c108ef0) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| ticket_item_id | integer(32,0) | No |  |  |  |
| modifier_id | integer(32,0) | No |  |  |  |
| list_order | integer(32,0) | No |  |  |  |

#### Llave primaria
- ticket_item_modifier_relation_pkey: ticket_item_id, list_order

#### Llaves foráneas
- fk5d3f9acb6c108ef0: (modifier_id) ➜ public.ticket_item_modifier (id)
- fk5d3f9acbdec6120a: (ticket_item_id) ➜ public.ticket_item (id)

#### Índices
- ticket_item_modifier_relation_pkey [PK, UNIQUE] (ticket_item_id, list_order) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(1000) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- ticket_properties_pkey: id, property_name

#### Llaves foráneas
- fk70ecd046223049de: (id) ➜ public.ticket (id)

#### Índices
- ticket_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.ticket_table_num
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk65af15e21df2d7f1) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| ticket_id | integer(32,0) | No |  |  |  |
| table_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk65af15e21df2d7f1: (ticket_id) ➜ public.ticket (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.transaction_properties
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No |  |  |  |
| property_value | character varying(255) | Sí |  |  |  |
| property_name | character varying(255) | No |  |  |  |

#### Llave primaria
- transaction_properties_pkey: id, property_name

#### Llaves foráneas
- fke3de65548e8203bc: (id) ➜ public.transactions (id)

#### Índices
- transaction_properties_pkey [PK, UNIQUE] (id, property_name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.transactions
- Descripción: sin comentario
- Filas estimadas: ~11,632
- Flags: faltan índices para FKs (fkfe9871551df2d7f1, fkfe9871553e20ad51, fkfe987155ca43b6, fkfe987155fc697d9e) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('transactions_id_seq'::regclass) | transactions_id_seq |  |
| payment_type | character varying(30) | No |  |  |  |
| global_id | character varying(16) | Sí |  |  |  |
| transaction_time | timestamp without time zone(6) | Sí |  |  |  |
| amount | double precision(53) | Sí |  |  |  |
| tips_amount | double precision(53) | Sí |  |  |  |
| tips_exceed_amount | double precision(53) | Sí |  |  |  |
| tender_amount | double precision(53) | Sí |  |  |  |
| transaction_type | character varying(30) | No |  |  |  |
| custom_payment_name | character varying(60) | Sí |  |  |  |
| custom_payment_ref | character varying(120) | Sí |  |  |  |
| custom_payment_field_name | character varying(60) | Sí |  |  |  |
| payment_sub_type | character varying(40) | No |  |  |  |
| captured | boolean | Sí |  |  |  |
| voided | boolean | Sí |  |  |  |
| authorizable | boolean | Sí |  |  |  |
| card_holder_name | character varying(60) | Sí |  |  |  |
| card_number | character varying(40) | Sí |  |  |  |
| card_auth_code | character varying(30) | Sí |  |  |  |
| card_type | character varying(20) | Sí |  |  |  |
| card_transaction_id | character varying(255) | Sí |  |  |  |
| card_merchant_gateway | character varying(60) | Sí |  |  |  |
| card_reader | character varying(30) | Sí |  |  |  |
| card_aid | character varying(120) | Sí |  |  |  |
| card_arqc | character varying(120) | Sí |  |  |  |
| card_ext_data | character varying(255) | Sí |  |  |  |
| gift_cert_number | character varying(64) | Sí |  |  |  |
| gift_cert_face_value | double precision(53) | Sí |  |  |  |
| gift_cert_paid_amount | double precision(53) | Sí |  |  |  |
| gift_cert_cash_back_amount | double precision(53) | Sí |  |  |  |
| drawer_resetted | boolean | Sí |  |  |  |
| note | character varying(255) | Sí |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |
| ticket_id | integer(32,0) | Sí |  |  |  |
| user_id | integer(32,0) | Sí |  |  |  |
| payout_reason_id | integer(32,0) | Sí |  |  |  |
| payout_recepient_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- transactions_pkey: id

#### Llaves foráneas
- fkfe9871551df2d7f1: (ticket_id) ➜ public.ticket (id)
- fkfe9871552ad2d031: (terminal_id) ➜ public.terminal (id)
- fkfe9871553e20ad51: (user_id) ➜ public.users (auto_id)
- fkfe987155ca43b6: (payout_recepient_id) ➜ public.payout_recepients (id)
- fkfe987155fc697d9e: (payout_reason_id) ➜ public.payout_reasons (id)

#### Índices
- idx_tx_term_user_time (terminal_id, user_id, transaction_time) USING BTREE
- tran_drawer_resetted (drawer_resetted) USING BTREE
- transactions_global_id_key [UNIQUE] (global_id) USING BTREE
- transactions_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- transactions_global_id_key: global_id

#### Restricciones CHECK
- Sin restricciones CHECK

### public.user_permission
- Descripción: sin comentario
- Filas estimadas: ~27
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| name | character varying(40) | No |  |  |  |

#### Llave primaria
- user_permission_pkey: name

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- user_permission_pkey [PK, UNIQUE] (name) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.user_type
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('user_type_id_seq'::regclass) | user_type_id_seq |  |
| p_name | character varying(60) | Sí |  |  |  |

#### Llave primaria
- user_type_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- user_type_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.user_user_permission
- Descripción: sin comentario
- Filas estimadas: ~69
- Flags: faltan índices para FKs (fk2dbeaa4f8f23f5e) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| permissionid | integer(32,0) | No |  |  |  |
| elt | character varying(40) | No |  |  |  |

#### Llave primaria
- user_user_permission_pkey: permissionid, elt

#### Llaves foráneas
- fk2dbeaa4f283ecc6: (permissionid) ➜ public.user_type (id)
- fk2dbeaa4f8f23f5e: (elt) ➜ public.user_permission (name)

#### Índices
- user_user_permission_pkey [PK, UNIQUE] (permissionid, elt) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.users
- Descripción: sin comentario
- Filas estimadas: ~9
- Flags: faltan índices para FKs (fk4d495e87660a5e3, fk4d495e8897b1e39, fk4d495e8d9409968) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| auto_id | integer(32,0) | No | nextval('users_auto_id_seq'::regclass) | users_auto_id_seq |  |
| user_id | integer(32,0) | Sí |  |  |  |
| user_pass | character varying(16) | No |  |  |  |
| first_name | character varying(30) | Sí |  |  |  |
| last_name | character varying(30) | Sí |  |  |  |
| ssn | character varying(30) | Sí |  |  |  |
| cost_per_hour | double precision(53) | Sí |  |  |  |
| clocked_in | boolean | Sí |  |  |  |
| last_clock_in_time | timestamp without time zone(6) | Sí |  |  |  |
| last_clock_out_time | timestamp without time zone(6) | Sí |  |  |  |
| phone_no | character varying(20) | Sí |  |  |  |
| is_driver | boolean | Sí |  |  |  |
| available_for_delivery | boolean | Sí |  |  |  |
| active | boolean | Sí |  |  |  |
| shift_id | integer(32,0) | Sí |  |  |  |
| currentterminal | integer(32,0) | Sí |  |  |  |
| n_user_type | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- users_pkey: auto_id

#### Llaves foráneas
- fk4d495e87660a5e3: (shift_id) ➜ public.shift (id)
- fk4d495e8897b1e39: (n_user_type) ➜ public.user_type (id)
- fk4d495e8d9409968: (currentterminal) ➜ public.terminal (id)

#### Índices
- users_pkey [PK, UNIQUE] (auto_id) USING BTREE
- users_user_id_key [UNIQUE] (user_id) USING BTREE
- users_user_pass_key [UNIQUE] (user_pass) USING BTREE

#### Restricciones UNIQUE
- users_user_id_key: user_id
- users_user_pass_key: user_pass

#### Restricciones CHECK
- Sin restricciones CHECK

### public.virtual_printer
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('virtual_printer_id_seq'::regclass) | virtual_printer_id_seq |  |
| name | character varying(60) | No |  |  |  |
| type | integer(32,0) | Sí |  |  |  |
| priority | integer(32,0) | Sí |  |  |  |
| enabled | boolean | Sí |  |  |  |

#### Llave primaria
- virtual_printer_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- virtual_printer_name_key [UNIQUE] (name) USING BTREE
- virtual_printer_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- virtual_printer_name_key: name

#### Restricciones CHECK
- Sin restricciones CHECK

### public.virtualprinter_order_type
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk9af7853bcf15f4a6) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| printer_id | integer(32,0) | No |  |  |  |
| order_type | character varying(255) | Sí |  |  |  |

#### Llave primaria
- No definida

#### Llaves foráneas
- fk9af7853bcf15f4a6: (printer_id) ➜ public.virtual_printer (id)

#### Índices
- Sin índices

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.void_reasons
- Descripción: sin comentario
- Filas estimadas: ~10
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('void_reasons_id_seq'::regclass) | void_reasons_id_seq |  |
| reason_text | character varying(255) | Sí |  |  |  |

#### Llave primaria
- void_reasons_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- void_reasons_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### public.zip_code_vs_delivery_charge
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| auto_id | integer(32,0) | No | nextval('zip_code_vs_delivery_charge_auto_id_seq'::regclass) | zip_code_vs_delivery_charge_auto_id_seq |  |
| zip_code | character varying(10) | No |  |  |  |
| delivery_charge | double precision(53) | No |  |  |  |

#### Llave primaria
- zip_code_vs_delivery_charge_pkey: auto_id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- zip_code_vs_delivery_charge_pkey [PK, UNIQUE] (auto_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.almacen
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (almacen_sucursal_id_fkey) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | text | No |  |  |  |
| sucursal_id | text | No |  |  |  |
| nombre | text | No |  |  |  |
| activo | boolean | No | true |  |  |

#### Llave primaria
- almacen_pkey: id

#### Llaves foráneas
- almacen_sucursal_id_fkey: (sucursal_id) ➜ selemti.sucursal (id)

#### Índices
- almacen_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.auditoria
- Descripción: sin comentario
- Filas estimadas: ~8
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('auditoria_id_seq'::regclass) | auditoria_id_seq |  |
| quien | integer(32,0) | Sí |  |  |  |
| que | text | No |  |  |  |
| payload | jsonb | Sí |  |  |  |
| creado_en | timestamp with time zone(6) | No | now() |  |  |

#### Llave primaria
- auditoria_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- auditoria_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.cache
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| key | character varying(255) | No |  |  |  |
| value | text | No |  |  |  |
| expiration | integer(32,0) | No |  |  |  |

#### Llave primaria
- cache_pkey: key

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- cache_pkey [PK, UNIQUE] (key) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.cache_locks
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| key | character varying(255) | No |  |  |  |
| owner | character varying(255) | No |  |  |  |
| expiration | integer(32,0) | No |  |  |  |

#### Llave primaria
- cache_locks_pkey: key

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- cache_locks_pkey [PK, UNIQUE] (key) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.cat_unidades
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: ninguno

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('cat_unidades_id_seq'::regclass) | cat_unidades_id_seq |  |
| created_at | timestamp without time zone(0) | Sí |  |  |  |
| updated_at | timestamp without time zone(0) | Sí |  |  |  |

#### Llave primaria
- cat_unidades_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- cat_unidades_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.conversiones_unidad
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (conversiones_unidad_unidad_destino_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('conversiones_unidad_id_seq'::regclass) | conversiones_unidad_id_seq |  |
| unidad_origen_id | integer(32,0) | No |  |  |  |
| unidad_destino_id | integer(32,0) | No |  |  |  |
| factor_conversion | numeric(12,6) | No |  |  |  |
| formula_directa | text | Sí |  |  |  |
| precision_estimada | numeric(5,4) | Sí | 1.0 |  |  |
| activo | boolean | Sí | true |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- conversiones_unidad_pkey: id

#### Llaves foráneas
- conversiones_unidad_unidad_destino_id_fkey: (unidad_destino_id) ➜ selemti.unidades_medida (id)
- conversiones_unidad_unidad_origen_id_fkey: (unidad_origen_id) ➜ selemti.unidades_medida (id)

#### Índices
- conversiones_unidad_pkey [PK, UNIQUE] (id) USING BTREE
- conversiones_unidad_unidad_origen_id_unidad_destino_id_key [UNIQUE] (unidad_origen_id, unidad_destino_id) USING BTREE

#### Restricciones UNIQUE
- conversiones_unidad_unidad_origen_id_unidad_destino_id_key: unidad_origen_id, unidad_destino_id

#### Restricciones CHECK
- conversiones_unidad_check: CHECK (unidad_origen_id <> unidad_destino_id)
- conversiones_unidad_factor_conversion_check: CHECK (factor_conversion > 0::numeric)

### selemti.cost_layer
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (cost_layer_batch_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('cost_layer_id_seq'::regclass) | cost_layer_id_seq |  |
| item_id | character varying(20) | No |  |  |  |
| batch_id | bigint(64,0) | Sí |  |  |  |
| ts_in | timestamp without time zone(6) | No |  |  |  |
| qty_in | numeric(14,6) | No |  |  |  |
| qty_left | numeric(14,6) | No |  |  |  |
| unit_cost | numeric(14,6) | No |  |  |  |
| sucursal_id | character varying(30) | Sí |  |  |  |
| source_ref | text | Sí |  |  |  |
| source_id | bigint(64,0) | Sí |  |  |  |

#### Llave primaria
- cost_layer_pkey: id

#### Llaves foráneas
- cost_layer_batch_id_fkey: (batch_id) ➜ selemti.inventory_batch (id)
- cost_layer_item_id_fkey: (item_id) ➜ selemti.items (id)

#### Índices
- cost_layer_pkey [PK, UNIQUE] (id) USING BTREE
- ix_layer_item_suc (item_id, sucursal_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.failed_jobs
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('failed_jobs_id_seq'::regclass) | failed_jobs_id_seq |  |
| uuid | character varying(255) | No |  |  |  |
| connection | text | No |  |  |  |
| queue | text | No |  |  |  |
| payload | text | No |  |  |  |
| exception | text | No |  |  |  |
| failed_at | timestamp without time zone(0) | No | now() |  |  |

#### Llave primaria
- failed_jobs_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- failed_jobs_pkey [PK, UNIQUE] (id) USING BTREE
- failed_jobs_uuid_unique [UNIQUE] (uuid) USING BTREE

#### Restricciones UNIQUE
- failed_jobs_uuid_unique: uuid

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.formas_pago
- Descripción: sin comentario
- Filas estimadas: ~13
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('formas_pago_id_seq'::regclass) | formas_pago_id_seq |  |
| codigo | text | No |  |  |  |
| payment_type | text | Sí |  |  |  |
| transaction_type | text | Sí |  |  |  |
| payment_sub_type | text | Sí |  |  |  |
| custom_name | text | Sí |  |  |  |
| custom_ref | text | Sí |  |  |  |
| activo | boolean | No | true |  |  |
| prioridad | integer(32,0) | No | 100 |  |  |
| creado_en | timestamp with time zone(6) | No | now() |  |  |

#### Llave primaria
- formas_pago_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- formas_pago_pkey [PK, UNIQUE] (id) USING BTREE
- uq_fp_huella_expr [UNIQUE] (payment_type, (COALESCE(transaction_type, ''::text)), (COALESCE(payment_sub_type, ''::text)), (COALESCE(custom_name, ''::text)), (COALESCE(custom_ref, ''::text))) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.historial_costos_item
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('historial_costos_item_id_seq'::regclass) | historial_costos_item_id_seq |  |
| item_id | character varying(20) | No |  |  |  |
| fecha_efectiva | date | No |  |  |  |
| fecha_registro | timestamp without time zone(6) | Sí | now() |  |  |
| costo_anterior | numeric(10,2) | Sí |  |  |  |
| costo_nuevo | numeric(10,2) | Sí |  |  |  |
| tipo_cambio | character varying(20) | Sí |  |  |  |
| referencia_id | integer(32,0) | Sí |  |  |  |
| referencia_tipo | character varying(20) | Sí |  |  |  |
| usuario_id | integer(32,0) | Sí |  |  |  |
| valid_from | date | No |  |  |  |
| valid_to | date | Sí |  |  |  |
| sys_from | timestamp without time zone(6) | No | now() |  |  |
| sys_to | timestamp without time zone(6) | Sí |  |  |  |
| costo_wac | numeric(12,4) | Sí |  |  |  |
| costo_peps | numeric(12,4) | Sí |  |  |  |
| costo_ueps | numeric(12,4) | Sí |  |  |  |
| costo_estandar | numeric(12,4) | Sí |  |  |  |
| algoritmo_principal | character varying(10) | Sí | 'WAC'::character varying |  |  |
| version_datos | integer(32,0) | Sí | 1 |  |  |
| recalculado | boolean | Sí | false |  |  |
| fuente_datos | character varying(20) | Sí |  |  |  |
| metadata_calculo | json | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- historial_costos_item_pkey: id

#### Llaves foráneas
- historial_costos_item_item_id_fkey: (item_id) ➜ selemti.items (id)

#### Índices
- historial_costos_item_item_id_fecha_efectiva_version_datos_key [UNIQUE] (item_id, fecha_efectiva, version_datos) USING BTREE
- historial_costos_item_pkey [PK, UNIQUE] (id) USING BTREE
- idx_historial_costos_item_fecha (item_id, fecha_efectiva) USING BTREE

#### Restricciones UNIQUE
- historial_costos_item_item_id_fecha_efectiva_version_datos_key: item_id, fecha_efectiva, version_datos

#### Restricciones CHECK
- historial_costos_item_algoritmo_principal_check: CHECK (algoritmo_principal::text = ANY (ARRAY['WAC'::character varying, 'PEPS'::character varying, 'UEPS'::character varying, 'ESTANDAR'::character varying]::text[]))
- historial_costos_item_fuente_datos_check: CHECK (fuente_datos::text = ANY (ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying, 'IMPORTACION'::character varying]::text[]))
- historial_costos_item_tipo_cambio_check: CHECK (tipo_cambio::text = ANY (ARRAY['COMPRA'::character varying, 'AJUSTE'::character varying, 'REPROCESO'::character varying]::text[]))

### selemti.historial_costos_receta
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (historial_costos_receta_receta_version_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('historial_costos_receta_id_seq'::regclass) | historial_costos_receta_id_seq |  |
| receta_version_id | integer(32,0) | No |  |  |  |
| fecha_calculo | date | No |  |  |  |
| costo_total | numeric(10,2) | Sí |  |  |  |
| costo_porcion | numeric(10,2) | Sí |  |  |  |
| algoritmo_utilizado | character varying(20) | Sí |  |  |  |
| version_datos | integer(32,0) | Sí | 1 |  |  |
| metadata_calculo | json | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| valid_from | date | No |  |  |  |
| valid_to | date | Sí |  |  |  |
| sys_from | timestamp without time zone(6) | No | now() |  |  |
| sys_to | timestamp without time zone(6) | Sí |  |  |  |

#### Llave primaria
- historial_costos_receta_pkey: id

#### Llaves foráneas
- historial_costos_receta_receta_version_id_fkey: (receta_version_id) ➜ selemti.receta_version (id)

#### Índices
- historial_costos_receta_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.inventory_batch
- Descripción: Lotes de inventario con trazabilidad completa
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('inventory_batch_id_seq'::regclass) | inventory_batch_id_seq |  |
| item_id | character varying(20) | No |  |  |  |
| lote_proveedor | character varying(50) | No |  |  |  |
| fecha_recepcion | date | No |  |  |  |
| fecha_caducidad | date | No |  |  |  |
| temperatura_recepcion | numeric(5,2) | Sí |  |  |  |
| documento_url | character varying(255) | Sí |  |  |  |
| cantidad_original | numeric(10,3) | No |  |  |  |
| cantidad_actual | numeric(10,3) | No |  |  |  |
| estado | character varying(20) | Sí | 'ACTIVO'::character varying |  |  |
| ubicacion_id | character varying(10) | No |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- inventory_batch_pkey: id

#### Llaves foráneas
- inventory_batch_item_id_fkey: (item_id) ➜ selemti.items (id)

#### Índices
- idx_inventory_batch_caducidad (fecha_caducidad) USING BTREE
- idx_inventory_batch_item (item_id) USING BTREE
- inventory_batch_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- inventory_batch_cantidad_actual_check: CHECK (cantidad_actual >= 0::numeric)
- inventory_batch_cantidad_original_check: CHECK (cantidad_original > 0::numeric)
- inventory_batch_check: CHECK (cantidad_actual <= cantidad_original)
- inventory_batch_estado_check: CHECK (estado::text = ANY (ARRAY['ACTIVO'::character varying, 'BLOQUEADO'::character varying, 'RECALL'::character varying]::text[]))
- inventory_batch_lote_proveedor_check: CHECK (length(lote_proveedor::text) >= 1 AND length(lote_proveedor::text) <= 50)
- inventory_batch_temperatura_recepcion_check: CHECK (temperatura_recepcion >= '-30'::integer::numeric AND temperatura_recepcion <= 60::numeric)
- inventory_batch_ubicacion_id_check: CHECK (ubicacion_id::text ~~ 'UBIC-%'::text)

### selemti.item_vendor
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (item_vendor_unidad_presentacion_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| item_id | text | No |  |  |  |
| vendor_id | text | No |  |  |  |
| presentacion | text | No |  |  |  |
| unidad_presentacion_id | integer(32,0) | No |  |  |  |
| factor_a_canonica | numeric(14,6) | No |  |  |  |
| costo_ultimo | numeric(14,6) | No | 0 |  |  |
| moneda | text | No | 'MXN'::text |  |  |
| lead_time_dias | integer(32,0) | Sí |  |  |  |
| codigo_proveedor | text | Sí |  |  |  |
| activo | boolean | No | true |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- item_vendor_pkey: item_id, vendor_id, presentacion

#### Llaves foráneas
- item_vendor_item_id_fkey: (item_id) ➜ selemti.items (id)
- item_vendor_unidad_presentacion_id_fkey: (unidad_presentacion_id) ➜ selemti.unidades_medida (id)

#### Índices
- item_vendor_pkey [PK, UNIQUE] (item_id, vendor_id, presentacion) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- item_vendor_factor_a_canonica_check: CHECK (factor_a_canonica > 0::numeric)

### selemti.items
- Descripción: Maestro de todos los ítems del sistema
- Filas estimadas: ~0
- Flags: faltan índices para FKs (items_unidad_compra_id_fkey, items_unidad_medida_id_fkey, items_unidad_salida_id_fkey) | campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | character varying(20) | No |  |  |  |
| nombre | character varying(100) | No |  |  |  |
| descripcion | text | Sí |  |  |  |
| categoria_id | character varying(10) | No |  |  |  |
| unidad_medida | character varying(10) | No | 'PZ'::character varying |  |  |
| perishable | boolean | Sí | false |  |  |
| temperatura_min | integer(32,0) | Sí |  |  |  |
| temperatura_max | integer(32,0) | Sí |  |  |  |
| costo_promedio | numeric(10,2) | Sí | 0.00 |  |  |
| activo | boolean | Sí | true |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |
| unidad_medida_id | integer(32,0) | Sí |  |  |  |
| factor_conversion | numeric(12,6) | Sí | 1.0 |  |  |
| unidad_compra_id | integer(32,0) | Sí |  |  |  |
| factor_compra | numeric(12,6) | Sí | 1.0 |  |  |
| tipo | USER-DEFINED | Sí |  |  |  |
| unidad_salida_id | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- items_pkey: id

#### Llaves foráneas
- items_unidad_compra_id_fkey: (unidad_compra_id) ➜ selemti.unidades_medida (id)
- items_unidad_medida_id_fkey: (unidad_medida_id) ➜ selemti.unidades_medida (id)
- items_unidad_salida_id_fkey: (unidad_salida_id) ➜ selemti.unidades_medida (id)

#### Índices
- items_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- items_categoria_id_check: CHECK (categoria_id::text ~~ 'CAT-%'::text)
- items_check: CHECK (temperatura_max IS NULL OR temperatura_min IS NULL OR temperatura_max >= temperatura_min)
- items_costo_promedio_check: CHECK (costo_promedio >= 0::numeric)
- items_id_check: CHECK (id::text ~ '^[A-Z0-9\-]{1,20}$'::text)
- items_nombre_check: CHECK (length(nombre::text) >= 2)
- items_unidad_medida_check: CHECK (unidad_medida::text = ANY (ARRAY['KG'::character varying, 'LT'::character varying, 'PZ'::character varying, 'BULTO'::character varying, 'CAJA'::character varying]::text[]))

### selemti.job_batches
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | character varying(255) | No |  |  |  |
| name | character varying(255) | No |  |  |  |
| total_jobs | integer(32,0) | No |  |  |  |
| pending_jobs | integer(32,0) | No |  |  |  |
| failed_jobs | integer(32,0) | No |  |  |  |
| failed_job_ids | text | No |  |  |  |
| options | text | Sí |  |  |  |
| cancelled_at | integer(32,0) | Sí |  |  |  |
| created_at | integer(32,0) | No |  |  |  |
| finished_at | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- job_batches_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- job_batches_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.job_recalc_queue
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('job_recalc_queue_id_seq'::regclass) | job_recalc_queue_id_seq |  |
| scope_type | text | No |  |  |  |
| scope_from | date | Sí |  |  |  |
| scope_to | date | Sí |  |  |  |
| item_id | character varying(20) | Sí |  |  |  |
| receta_id | character varying(20) | Sí |  |  |  |
| sucursal_id | character varying(30) | Sí |  |  |  |
| reason | text | Sí |  |  |  |
| created_ts | timestamp without time zone(6) | No | now() |  |  |
| status | text | No | 'PENDING'::text |  |  |
| result | json | Sí |  |  |  |

#### Llave primaria
- job_recalc_queue_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- job_recalc_queue_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- job_recalc_queue_scope_type_check: CHECK (scope_type = ANY (ARRAY['PERIODO'::text, 'ITEM'::text, 'RECETA'::text, 'SUCURSAL'::text]))
- job_recalc_queue_status_check: CHECK (status = ANY (ARRAY['PENDING'::text, 'RUNNING'::text, 'DONE'::text, 'FAILED'::text]))

### selemti.jobs
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('jobs_id_seq'::regclass) | jobs_id_seq |  |
| queue | character varying(255) | No |  |  |  |
| payload | text | No |  |  |  |
| attempts | smallint(16,0) | No |  |  |  |
| reserved_at | integer(32,0) | Sí |  |  |  |
| available_at | integer(32,0) | No |  |  |  |
| created_at | integer(32,0) | No |  |  |  |

#### Llave primaria
- jobs_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- jobs_pkey [PK, UNIQUE] (id) USING BTREE
- jobs_queue_index (queue) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.migrations
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('migrations_id_seq'::regclass) | migrations_id_seq |  |
| migration | character varying(255) | No |  |  |  |
| batch | integer(32,0) | No |  |  |  |

#### Llave primaria
- migrations_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- migrations_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.model_has_permissions
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| permission_id | bigint(64,0) | No |  |  |  |
| model_type | character varying(255) | No |  |  |  |
| model_id | bigint(64,0) | No |  |  |  |

#### Llave primaria
- model_has_permissions_pkey: permission_id, model_id, model_type

#### Llaves foráneas
- model_has_permissions_permission_id_foreign: (permission_id) ➜ selemti.permissions (id)

#### Índices
- model_has_permissions_model_id_model_type_index (model_id, model_type) USING BTREE
- model_has_permissions_pkey [PK, UNIQUE] (permission_id, model_id, model_type) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.model_has_roles
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| role_id | bigint(64,0) | No |  |  |  |
| model_type | character varying(255) | No |  |  |  |
| model_id | bigint(64,0) | No |  |  |  |

#### Llave primaria
- model_has_roles_pkey: role_id, model_id, model_type

#### Llaves foráneas
- model_has_roles_role_id_foreign: (role_id) ➜ selemti.roles (id)

#### Índices
- model_has_roles_model_id_model_type_index (model_id, model_type) USING BTREE
- model_has_roles_pkey [PK, UNIQUE] (role_id, model_id, model_type) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.modificadores_pos
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (modificadores_pos_receta_modificador_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('modificadores_pos_id_seq'::regclass) | modificadores_pos_id_seq |  |
| codigo_pos | character varying(20) | No |  |  |  |
| nombre | character varying(100) | No |  |  |  |
| tipo | character varying(20) | Sí |  |  |  |
| precio_extra | numeric(10,2) | Sí | 0 |  |  |
| receta_modificador_id | character varying(20) | Sí |  |  |  |
| activo | boolean | Sí | true |  |  |

#### Llave primaria
- modificadores_pos_pkey: id

#### Llaves foráneas
- modificadores_pos_receta_modificador_id_fkey: (receta_modificador_id) ➜ selemti.receta_cab (id)

#### Índices
- modificadores_pos_codigo_pos_key [UNIQUE] (codigo_pos) USING BTREE
- modificadores_pos_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- modificadores_pos_codigo_pos_key: codigo_pos

#### Restricciones CHECK
- modificadores_pos_tipo_check: CHECK (tipo::text = ANY (ARRAY['AGREGADO'::character varying, 'SUSTITUCION'::character varying, 'ELIMINACION'::character varying]::text[]))

### selemti.mov_inv
- Descripción: Kardex completo de movimientos de inventario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (mov_inv_lote_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('mov_inv_id_seq'::regclass) | mov_inv_id_seq |  |
| ts | timestamp without time zone(6) | No | now() |  |  |
| item_id | character varying(20) | No |  |  |  |
| lote_id | integer(32,0) | Sí |  |  |  |
| cantidad | numeric(14,6) | No |  |  |  |
| qty_original | numeric(14,6) | Sí |  |  |  |
| uom_original_id | integer(32,0) | Sí |  |  |  |
| costo_unit | numeric(14,6) | Sí | 0 |  |  |
| tipo | character varying(20) | No |  |  |  |
| ref_tipo | character varying(50) | Sí |  |  |  |
| ref_id | bigint(64,0) | Sí |  |  |  |
| sucursal_id | character varying(30) | Sí |  |  |  |
| usuario_id | integer(32,0) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- mov_inv_pkey: id

#### Llaves foráneas
- mov_inv_item_id_fkey: (item_id) ➜ selemti.items (id)
- mov_inv_lote_id_fkey: (lote_id) ➜ selemti.inventory_batch (id)

#### Índices
- idx_mov_inv_item_ts (item_id, ts) USING BTREE
- idx_mov_inv_tipo_fecha (tipo, ts) USING BTREE
- mov_inv_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- mov_inv_tipo_check: CHECK (tipo::text = ANY (ARRAY['ENTRADA'::character varying, 'SALIDA'::character varying, 'AJUSTE'::character varying, 'MERMA'::character varying, 'TRASPASO'::character varying]::text[]))

### selemti.op_produccion_cab
- Descripción: Órdenes de producción para elaborados
- Filas estimadas: ~0
- Flags: faltan índices para FKs (op_produccion_cab_receta_version_id_fkey) | campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('op_produccion_cab_id_seq'::regclass) | op_produccion_cab_id_seq |  |
| receta_version_id | integer(32,0) | No |  |  |  |
| cantidad_planeada | numeric(10,3) | No |  |  |  |
| cantidad_real | numeric(10,3) | Sí |  |  |  |
| fecha_produccion | date | No |  |  |  |
| estado | character varying(20) | Sí | 'PENDIENTE'::character varying |  |  |
| lote_resultado | character varying(50) | Sí |  |  |  |
| usuario_responsable | integer(32,0) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- op_produccion_cab_pkey: id

#### Llaves foráneas
- op_produccion_cab_receta_version_id_fkey: (receta_version_id) ➜ selemti.receta_version (id)

#### Índices
- op_produccion_cab_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- op_produccion_cab_cantidad_planeada_check: CHECK (cantidad_planeada > 0::numeric)
- op_produccion_cab_estado_check: CHECK (estado::text = ANY (ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying, 'COMPLETADA'::character varying, 'CANCELADA'::character varying]::text[]))

### selemti.param_sucursal
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('param_sucursal_id_seq'::regclass) | param_sucursal_id_seq |  |
| sucursal_id | text | No |  |  |  |
| consumo | USER-DEFINED | No | 'FEFO'::consumo_policy |  |  |
| tolerancia_precorte_pct | numeric(8,4) | Sí | 0.02 |  |  |
| tolerancia_corte_abs | numeric(12,4) | Sí | 50.0 |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |
| updated_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- param_sucursal_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- param_sucursal_pkey [PK, UNIQUE] (id) USING BTREE
- param_sucursal_sucursal_id_key [UNIQUE] (sucursal_id) USING BTREE

#### Restricciones UNIQUE
- param_sucursal_sucursal_id_key: sucursal_id

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.password_reset_tokens
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| email | character varying(255) | No |  |  |  |
| token | character varying(255) | No |  |  |  |
| created_at | timestamp without time zone(0) | Sí |  |  |  |

#### Llave primaria
- password_reset_tokens_pkey: email

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- password_reset_tokens_pkey [PK, UNIQUE] (email) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.perdida_log
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (perdida_log_lote_id_fkey, perdida_log_uom_original_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('perdida_log_id_seq'::regclass) | perdida_log_id_seq |  |
| ts | timestamp without time zone(6) | No | now() |  |  |
| item_id | text | No |  |  |  |
| lote_id | bigint(64,0) | Sí |  |  |  |
| sucursal_id | text | Sí |  |  |  |
| clase | USER-DEFINED | No |  |  |  |
| motivo | text | Sí |  |  |  |
| qty_canonica | numeric(14,6) | No |  |  |  |
| qty_original | numeric(14,6) | Sí |  |  |  |
| uom_original_id | integer(32,0) | Sí |  |  |  |
| evidencia_url | text | Sí |  |  |  |
| usuario_id | integer(32,0) | Sí |  |  |  |
| ref_tipo | text | Sí |  |  |  |
| ref_id | bigint(64,0) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- perdida_log_pkey: id

#### Llaves foráneas
- perdida_log_item_id_fkey: (item_id) ➜ selemti.items (id)
- perdida_log_lote_id_fkey: (lote_id) ➜ selemti.inventory_batch (id)
- perdida_log_uom_original_id_fkey: (uom_original_id) ➜ selemti.unidades_medida (id)

#### Índices
- idx_perdida_item_ts (item_id, ts) USING BTREE
- perdida_log_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- perdida_log_qty_canonica_check: CHECK (qty_canonica > 0::numeric)

### selemti.permissions
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: ninguno

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('permissions_id_seq'::regclass) | permissions_id_seq |  |
| name | character varying(255) | No |  |  |  |
| guard_name | character varying(255) | No |  |  |  |
| created_at | timestamp without time zone(0) | Sí |  |  |  |
| updated_at | timestamp without time zone(0) | Sí |  |  |  |

#### Llave primaria
- permissions_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- permissions_name_guard_name_unique [UNIQUE] (name, guard_name) USING BTREE
- permissions_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- permissions_name_guard_name_unique: name, guard_name

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.pos_map
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| pos_system | text | No |  |  |  |
| plu | text | No |  |  |  |
| tipo | text | No |  |  |  |
| receta_id | text | Sí |  |  |  |
| receta_version_id | integer(32,0) | Sí |  |  |  |
| valid_from | date | No |  |  |  |
| valid_to | date | Sí |  |  |  |
| sys_from | timestamp without time zone(6) | No | now() |  |  |
| sys_to | timestamp without time zone(6) | Sí |  |  |  |
| meta | json | Sí |  |  |  |

#### Llave primaria
- pos_map_pkey: pos_system, plu, valid_from, sys_from

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- pos_map_pkey [PK, UNIQUE] (pos_system, plu, valid_from, sys_from) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- pos_map_tipo_check: CHECK (tipo = ANY (ARRAY['PLATO'::text, 'MODIFICADOR'::text, 'COMBO'::text]))

### selemti.postcorte
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('postcorte_id_seq'::regclass) | postcorte_id_seq |  |
| sesion_id | bigint(64,0) | No |  |  |  |
| sistema_efectivo_esperado | numeric(12,2) | No | 0 |  |  |
| declarado_efectivo | numeric(12,2) | No | 0 |  |  |
| diferencia_efectivo | numeric(12,2) | No | 0 |  |  |
| veredicto_efectivo | text | No | 'CUADRA'::text |  |  |
| sistema_tarjetas | numeric(12,2) | No | 0 |  |  |
| declarado_tarjetas | numeric(12,2) | No | 0 |  |  |
| diferencia_tarjetas | numeric(12,2) | No | 0 |  |  |
| veredicto_tarjetas | text | No | 'CUADRA'::text |  |  |
| creado_en | timestamp with time zone(6) | No | now() |  |  |
| creado_por | integer(32,0) | Sí |  |  |  |
| notas | text | Sí |  |  |  |
| sistema_transferencias | numeric(12,2) | No | 0 |  |  |
| declarado_transferencias | numeric(12,2) | No | 0 |  |  |
| diferencia_transferencias | numeric(12,2) | No | 0 |  |  |
| veredicto_transferencias | text | No | 'CUADRA'::text |  |  |
| validado | boolean | No | false |  | TRUE cuando el supervisor valida/cierra el postcorte |
| validado_por | integer(32,0) | Sí |  |  |  |
| validado_en | timestamp with time zone(6) | Sí |  |  |  |

#### Llave primaria
- postcorte_pkey: id

#### Llaves foráneas
- postcorte_sesion_id_fkey: (sesion_id) ➜ selemti.sesion_cajon (id)

#### Índices
- postcorte_pkey [PK, UNIQUE] (id) USING BTREE
- uq_postcorte_sesion_id [UNIQUE] (sesion_id) USING BTREE

#### Restricciones UNIQUE
- uq_postcorte_sesion_id: sesion_id

#### Restricciones CHECK
- postcorte_veredicto_efectivo_check: CHECK (veredicto_efectivo = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))
- postcorte_veredicto_tarjetas_check: CHECK (veredicto_tarjetas = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))
- postcorte_veredicto_transfer_check: CHECK (veredicto_transferencias = ANY (ARRAY['CUADRA'::text, 'A_FAVOR'::text, 'EN_CONTRA'::text]))

### selemti.precorte
- Descripción: sin comentario
- Filas estimadas: ~4
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('precorte_id_seq'::regclass) | precorte_id_seq |  |
| sesion_id | bigint(64,0) | No |  |  |  |
| declarado_efectivo | numeric(12,2) | No | 0 |  |  |
| declarado_otros | numeric(12,2) | No | 0 |  |  |
| estatus | text | No | 'PENDIENTE'::text |  |  |
| creado_en | timestamp with time zone(6) | No | now() |  |  |
| creado_por | integer(32,0) | Sí |  |  |  |
| ip_cliente | inet | Sí |  |  |  |
| notas | text | Sí |  |  |  |

#### Llave primaria
- precorte_pkey: id

#### Llaves foráneas
- precorte_sesion_id_fkey: (sesion_id) ➜ selemti.sesion_cajon (id)

#### Índices
- idx_precorte_sesion_id (sesion_id) USING BTREE
- precorte_pkey [PK, UNIQUE] (id) USING BTREE
- precorte_sesion_id_idx (sesion_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- precorte_estatus_check: CHECK (estatus = ANY (ARRAY['PENDIENTE'::text, 'ENVIADO'::text, 'APROBADO'::text, 'RECHAZADO'::text]))

### selemti.precorte_efectivo
- Descripción: sin comentario
- Filas estimadas: ~26
- Flags: faltan índices para FKs (precorte_efectivo_precorte_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('precorte_efectivo_id_seq'::regclass) | precorte_efectivo_id_seq |  |
| precorte_id | bigint(64,0) | No |  |  |  |
| denominacion | numeric(12,2) | No |  |  |  |
| cantidad | integer(32,0) | No |  |  |  |
| subtotal | numeric(12,2) | No | 0 |  |  |

#### Llave primaria
- precorte_efectivo_pkey: id

#### Llaves foráneas
- precorte_efectivo_precorte_id_fkey: (precorte_id) ➜ selemti.precorte (id)

#### Índices
- precorte_efectivo_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.precorte_otros
- Descripción: sin comentario
- Filas estimadas: ~8
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('precorte_otros_id_seq'::regclass) | precorte_otros_id_seq |  |
| precorte_id | bigint(64,0) | No |  |  |  |
| tipo | text | No |  |  |  |
| monto | numeric(12,2) | No | 0 |  |  |
| referencia | text | Sí |  |  |  |
| evidencia_url | text | Sí |  |  |  |
| notas | text | Sí |  |  |  |
| creado_en | timestamp with time zone(6) | No | now() |  |  |

#### Llave primaria
- precorte_otros_pkey: id

#### Llaves foráneas
- precorte_otros_precorte_id_fkey: (precorte_id) ➜ selemti.precorte (id)

#### Índices
- ix_precorte_otros_precorte (precorte_id) USING BTREE
- precorte_otros_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.proveedor
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | text | No |  |  |  |
| nombre | text | No |  |  |  |
| rfc | text | Sí |  |  |  |
| activo | boolean | No | true |  |  |

#### Llave primaria
- proveedor_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- proveedor_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.recalc_log
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (recalc_log_job_id_fkey) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('recalc_log_id_seq'::regclass) | recalc_log_id_seq |  |
| job_id | bigint(64,0) | Sí |  |  |  |
| step | text | Sí |  |  |  |
| started_ts | timestamp without time zone(6) | Sí |  |  |  |
| ended_ts | timestamp without time zone(6) | Sí |  |  |  |
| ok | boolean | Sí |  |  |  |
| details | json | Sí |  |  |  |

#### Llave primaria
- recalc_log_pkey: id

#### Llaves foráneas
- recalc_log_job_id_fkey: (job_id) ➜ selemti.job_recalc_queue (id)

#### Índices
- recalc_log_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.receta_cab
- Descripción: Cabecera de recetas y platos del menú
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | character varying(20) | No |  |  |  |
| nombre_plato | character varying(100) | No |  |  |  |
| codigo_plato_pos | character varying(20) | Sí |  |  |  |
| categoria_plato | character varying(50) | Sí |  |  |  |
| porciones_standard | integer(32,0) | Sí | 1 |  |  |
| instrucciones_preparacion | text | Sí |  |  |  |
| tiempo_preparacion_min | integer(32,0) | Sí |  |  |  |
| costo_standard_porcion | numeric(10,2) | Sí | 0 |  |  |
| precio_venta_sugerido | numeric(10,2) | Sí | 0 |  |  |
| activo | boolean | Sí | true |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- receta_cab_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- receta_cab_codigo_plato_pos_key [UNIQUE] (codigo_plato_pos) USING BTREE
- receta_cab_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- receta_cab_codigo_plato_pos_key: codigo_plato_pos

#### Restricciones CHECK
- receta_cab_id_check: CHECK (id::text ~ '^REC-[A-Z0-9\-]+$'::text)
- receta_cab_porciones_standard_check: CHECK (porciones_standard > 0)

### selemti.receta_det
- Descripción: Detalle de ingredientes por versión de receta
- Filas estimadas: ~0
- Flags: faltan índices para FKs (receta_det_item_id_fkey, receta_det_receta_version_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('receta_det_id_seq'::regclass) | receta_det_id_seq |  |
| receta_version_id | integer(32,0) | No |  |  |  |
| item_id | character varying(20) | No |  |  |  |
| cantidad | numeric(10,4) | No |  |  |  |
| unidad_medida | character varying(10) | No |  |  |  |
| merma_porcentaje | numeric(5,2) | Sí | 0 |  |  |
| instrucciones_especificas | text | Sí |  |  |  |
| orden | integer(32,0) | Sí | 1 |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- receta_det_pkey: id

#### Llaves foráneas
- receta_det_item_id_fkey: (item_id) ➜ selemti.items (id)
- receta_det_receta_version_id_fkey: (receta_version_id) ➜ selemti.receta_version (id)

#### Índices
- receta_det_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- receta_det_cantidad_check: CHECK (cantidad > 0::numeric)
- receta_det_merma_porcentaje_check: CHECK (merma_porcentaje >= 0::numeric AND merma_porcentaje <= 100::numeric)

### selemti.receta_shadow
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('receta_shadow_id_seq'::regclass) | receta_shadow_id_seq |  |
| codigo_plato_pos | character varying(20) | No |  |  |  |
| nombre_plato | character varying(100) | No |  |  |  |
| estado | character varying(15) | Sí | 'INFERIDA'::character varying |  |  |
| confianza | numeric(5,4) | Sí | 0.0 |  |  |
| total_ventas_analizadas | integer(32,0) | Sí | 0 |  |  |
| fecha_primer_venta | date | Sí |  |  |  |
| fecha_ultima_venta | date | Sí |  |  |  |
| frecuencia_dias | numeric(10,2) | Sí |  |  |  |
| ingredientes_inferidos | json | Sí |  |  |  |
| usuario_validador | integer(32,0) | Sí |  |  |  |
| fecha_validacion | timestamp without time zone(6) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- receta_shadow_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- receta_shadow_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- receta_shadow_confianza_check: CHECK (confianza >= 0::numeric AND confianza <= 1::numeric)
- receta_shadow_estado_check: CHECK (estado::text = ANY (ARRAY['INFERIDA'::character varying, 'VALIDADA'::character varying, 'DESCARTADA'::character varying]::text[]))

### selemti.receta_version
- Descripción: Control de versiones de recetas
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('receta_version_id_seq'::regclass) | receta_version_id_seq |  |
| receta_id | character varying(20) | No |  |  |  |
| version | integer(32,0) | No | 1 |  |  |
| descripcion_cambios | text | Sí |  |  |  |
| fecha_efectiva | date | No |  |  |  |
| version_publicada | boolean | Sí | false |  |  |
| usuario_publicador | integer(32,0) | Sí |  |  |  |
| fecha_publicacion | timestamp without time zone(6) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- receta_version_pkey: id

#### Llaves foráneas
- receta_version_receta_id_fkey: (receta_id) ➜ selemti.receta_cab (id)

#### Índices
- idx_receta_version_publicada (version_publicada) USING BTREE
- receta_version_pkey [PK, UNIQUE] (id) USING BTREE
- receta_version_receta_id_version_key [UNIQUE] (receta_id, version) USING BTREE

#### Restricciones UNIQUE
- receta_version_receta_id_version_key: receta_id, version

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.role_has_permissions
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (role_has_permissions_role_id_foreign) | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| permission_id | bigint(64,0) | No |  |  |  |
| role_id | bigint(64,0) | No |  |  |  |

#### Llave primaria
- role_has_permissions_pkey: permission_id, role_id

#### Llaves foráneas
- role_has_permissions_permission_id_foreign: (permission_id) ➜ selemti.permissions (id)
- role_has_permissions_role_id_foreign: (role_id) ➜ selemti.roles (id)

#### Índices
- role_has_permissions_pkey [PK, UNIQUE] (permission_id, role_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.roles
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: ninguno

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('roles_id_seq'::regclass) | roles_id_seq |  |
| name | character varying(255) | No |  |  |  |
| guard_name | character varying(255) | No |  |  |  |
| created_at | timestamp without time zone(0) | Sí |  |  |  |
| updated_at | timestamp without time zone(0) | Sí |  |  |  |

#### Llave primaria
- roles_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- roles_name_guard_name_unique [UNIQUE] (name, guard_name) USING BTREE
- roles_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- roles_name_guard_name_unique: name, guard_name

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.sesion_cajon
- Descripción: sin comentario
- Filas estimadas: ~8
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('sesion_cajon_id_seq'::regclass) | sesion_cajon_id_seq |  |
| sucursal | text | Sí |  |  |  |
| terminal_id | integer(32,0) | No |  |  |  |
| terminal_nombre | text | Sí |  |  |  |
| cajero_usuario_id | integer(32,0) | No |  |  |  |
| apertura_ts | timestamp with time zone(6) | No | now() |  |  |
| cierre_ts | timestamp with time zone(6) | Sí |  |  |  |
| estatus | text | No | 'ACTIVA'::text |  |  |
| opening_float | numeric(12,2) | No | 0 |  |  |
| closing_float | numeric(12,2) | Sí |  |  |  |
| dah_evento_id | integer(32,0) | Sí |  |  |  |
| skipped_precorte | boolean | No | false |  |  |

#### Llave primaria
- sesion_cajon_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- ix_sesion_cajon_cajero (cajero_usuario_id, apertura_ts) USING BTREE
- ix_sesion_cajon_terminal (terminal_id, apertura_ts) USING BTREE
- sesion_cajon_pkey [PK, UNIQUE] (id) USING BTREE
- sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key [UNIQUE] (terminal_id, cajero_usuario_id, apertura_ts) USING BTREE

#### Restricciones UNIQUE
- sesion_cajon_terminal_id_cajero_usuario_id_apertura_ts_key: terminal_id, cajero_usuario_id, apertura_ts

#### Restricciones CHECK
- sesion_cajon_estatus_check: CHECK (estatus = ANY (ARRAY['ACTIVA'::text, 'LISTO_PARA_CORTE'::text, 'CERRADA'::text]))

### selemti.sessions
- Descripción: sin comentario
- Filas estimadas: ~3
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | character varying(255) | No |  |  |  |
| user_id | bigint(64,0) | Sí |  |  |  |
| ip_address | character varying(45) | Sí |  |  |  |
| user_agent | text | Sí |  |  |  |
| payload | text | No |  |  |  |
| last_activity | integer(32,0) | No |  |  |  |

#### Llave primaria
- sessions_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- sessions_last_activity_index (last_activity) USING BTREE
- sessions_pkey [PK, UNIQUE] (id) USING BTREE
- sessions_user_id_index (user_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.stock_policy
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('stock_policy_id_seq'::regclass) | stock_policy_id_seq |  |
| item_id | text | No |  |  |  |
| sucursal_id | text | No |  |  |  |
| almacen_id | text | Sí |  |  |  |
| min_qty | numeric(14,6) | No | 0 |  |  |
| max_qty | numeric(14,6) | No | 0 |  |  |
| reorder_lote | numeric(14,6) | Sí |  |  |  |
| activo | boolean | No | true |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- stock_policy_pkey: id

#### Llaves foráneas
- stock_policy_item_id_fkey: (item_id) ➜ selemti.items (id)

#### Índices
- idx_stock_policy_item_suc (item_id, sucursal_id) USING BTREE
- idx_stock_policy_unique [UNIQUE] (item_id, sucursal_id, (COALESCE(almacen_id, '_'::text))) USING BTREE
- stock_policy_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.sucursal
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | text | No |  |  |  |
| nombre | text | No |  |  |  |
| activo | boolean | No | true |  |  |

#### Llave primaria
- sucursal_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- sucursal_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.sucursal_almacen_terminal
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('sucursal_almacen_terminal_id_seq'::regclass) | sucursal_almacen_terminal_id_seq |  |
| sucursal_id | text | No |  |  |  |
| almacen_id | text | No |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |
| location | text | Sí |  |  |  |
| descripcion | text | Sí |  |  |  |
| activo | boolean | No | true |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- sucursal_almacen_terminal_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- idx_suc_alm_term_unique [UNIQUE] (sucursal_id, almacen_id, (COALESCE(terminal_id, 0))) USING BTREE
- sucursal_almacen_terminal_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- Sin restricciones CHECK

### selemti.ticket_det_consumo
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (ticket_det_consumo_lote_id_fkey, ticket_det_consumo_uom_original_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('ticket_det_consumo_id_seq'::regclass) | ticket_det_consumo_id_seq |  |
| ticket_id | bigint(64,0) | No |  |  |  |
| ticket_det_id | bigint(64,0) | No |  |  |  |
| item_id | text | No |  |  |  |
| lote_id | bigint(64,0) | Sí |  |  |  |
| qty_canonica | numeric(14,6) | No |  |  |  |
| qty_original | numeric(14,6) | Sí |  |  |  |
| uom_original_id | integer(32,0) | Sí |  |  |  |
| sucursal_id | text | Sí |  |  |  |
| ref_tipo | text | Sí |  |  |  |
| ref_id | bigint(64,0) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | No | now() |  |  |

#### Llave primaria
- ticket_det_consumo_pkey: id

#### Llaves foráneas
- ticket_det_consumo_item_id_fkey: (item_id) ➜ selemti.items (id)
- ticket_det_consumo_lote_id_fkey: (lote_id) ➜ selemti.inventory_batch (id)
- ticket_det_consumo_uom_original_id_fkey: (uom_original_id) ➜ selemti.unidades_medida (id)

#### Índices
- idx_tick_cons_unique [UNIQUE] (ticket_det_id, item_id, lote_id, qty_canonica, (COALESCE(uom_original_id, 0))) USING BTREE
- idx_tickcons_lote (item_id, lote_id) USING BTREE
- idx_tickcons_ticket (ticket_id, ticket_det_id) USING BTREE
- ticket_det_consumo_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- ticket_det_consumo_qty_canonica_check: CHECK (qty_canonica > 0::numeric)

### selemti.ticket_venta_cab
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('ticket_venta_cab_id_seq'::regclass) | ticket_venta_cab_id_seq |  |
| numero_ticket | character varying(50) | No |  |  |  |
| fecha_venta | timestamp without time zone(6) | No | now() |  |  |
| sucursal_id | character varying(10) | No |  |  |  |
| terminal_id | integer(32,0) | Sí |  |  |  |
| total_venta | numeric(12,2) | Sí | 0 |  |  |
| estado | character varying(20) | Sí | 'ABIERTO'::character varying |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- ticket_venta_cab_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- idx_ticket_venta_fecha (fecha_venta) USING BTREE
- ticket_venta_cab_numero_ticket_key [UNIQUE] (numero_ticket) USING BTREE
- ticket_venta_cab_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- ticket_venta_cab_numero_ticket_key: numero_ticket

#### Restricciones CHECK
- ticket_venta_cab_estado_check: CHECK (estado::text = ANY (ARRAY['ABIERTO'::character varying, 'CERRADO'::character varying, 'ANULADO'::character varying]::text[]))

### selemti.ticket_venta_det
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: faltan índices para FKs (fk_ticket_det_cab, ticket_venta_det_receta_shadow_id_fkey, ticket_venta_det_receta_version_id_fkey) | campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | bigint(64,0) | No | nextval('ticket_venta_det_id_seq'::regclass) | ticket_venta_det_id_seq |  |
| ticket_id | bigint(64,0) | No |  |  |  |
| item_id | character varying(20) | No |  |  |  |
| cantidad | numeric(10,3) | No |  |  |  |
| precio_unitario | numeric(10,2) | No |  |  |  |
| subtotal | numeric(12,2) | No |  |  |  |
| receta_version_id | integer(32,0) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| receta_shadow_id | integer(32,0) | Sí |  |  |  |
| reprocesado | boolean | Sí | false |  |  |
| version_reproceso | integer(32,0) | Sí | 1 |  |  |
| modificadores_aplicados | json | Sí |  |  |  |

#### Llave primaria
- ticket_venta_det_pkey: id

#### Llaves foráneas
- fk_ticket_det_cab: (ticket_id) ➜ selemti.ticket_venta_cab (id)
- ticket_venta_det_receta_shadow_id_fkey: (receta_shadow_id) ➜ selemti.receta_shadow (id)
- ticket_venta_det_receta_version_id_fkey: (receta_version_id) ➜ selemti.receta_version (id)

#### Índices
- ticket_venta_det_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- ticket_venta_det_cantidad_check: CHECK (cantidad > 0::numeric)

### selemti.unidades_medida
- Descripción: sin comentario
- Filas estimadas: ~0
- Flags: campos monetarios no uniformes | sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('unidades_medida_id_seq'::regclass) | unidades_medida_id_seq |  |
| codigo | character varying(10) | No |  |  |  |
| nombre | character varying(50) | No |  |  |  |
| tipo | character varying(10) | No |  |  |  |
| categoria | character varying(20) | Sí |  |  |  |
| es_base | boolean | Sí | false |  |  |
| factor_conversion_base | numeric(12,6) | Sí | 1.0 |  |  |
| decimales | integer(32,0) | Sí | 2 |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- unidades_medida_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- unidades_medida_codigo_key [UNIQUE] (codigo) USING BTREE
- unidades_medida_pkey [PK, UNIQUE] (id) USING BTREE

#### Restricciones UNIQUE
- unidades_medida_codigo_key: codigo

#### Restricciones CHECK
- unidades_medida_categoria_check: CHECK (categoria::text = ANY (ARRAY['METRICO'::character varying, 'IMPERIAL'::character varying, 'CULINARIO'::character varying]::text[]))
- unidades_medida_codigo_check: CHECK (codigo::text ~ '^[A-Z]{2,5}$'::text)
- unidades_medida_decimales_check: CHECK (decimales >= 0 AND decimales <= 6)
- unidades_medida_tipo_check: CHECK (tipo::text = ANY (ARRAY['PESO'::character varying, 'VOLUMEN'::character varying, 'UNIDAD'::character varying, 'TIEMPO'::character varying]::text[]))

### selemti.user_roles
- Descripción: Asignación de roles a usuarios (RBAC)
- Filas estimadas: ~0
- Flags: sin timestamps

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| user_id | integer(32,0) | No |  |  |  |
| role_id | character varying(20) | No |  |  |  |
| assigned_at | timestamp without time zone(6) | Sí | now() |  |  |
| assigned_by | integer(32,0) | Sí |  |  |  |

#### Llave primaria
- user_roles_pkey: user_id, role_id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- user_roles_pkey [PK, UNIQUE] (user_id, role_id) USING BTREE

#### Restricciones UNIQUE
- Sin restricciones UNIQUE adicionales

#### Restricciones CHECK
- user_roles_role_id_check: CHECK (role_id::text = ANY (ARRAY['GERENTE'::character varying, 'CHEF'::character varying, 'ALMACEN'::character varying, 'CAJERO'::character varying, 'AUDITOR'::character varying, 'SISTEMA'::character varying]::text[]))

### selemti.users
- Descripción: Usuarios del sistema con sus credenciales y estado
- Filas estimadas: ~0
- Flags: ninguno

#### Columnas
| Columna | Tipo | Nulo | Default | Identidad / Secuencia | Comentario |
| --- | --- | --- | --- | --- | --- |
| id | integer(32,0) | No | nextval('users_id_seq'::regclass) | users_id_seq |  |
| username | character varying(50) | No |  |  |  |
| password_hash | character varying(255) | No |  |  |  |
| email | character varying(255) | Sí |  |  |  |
| nombre_completo | character varying(100) | No |  |  |  |
| sucursal_id | character varying(10) | Sí | 'SUR'::character varying |  |  |
| activo | boolean | Sí | true |  |  |
| fecha_ultimo_login | timestamp without time zone(6) | Sí |  |  |  |
| intentos_login | integer(32,0) | Sí | 0 |  |  |
| bloqueado_hasta | timestamp without time zone(6) | Sí |  |  |  |
| created_at | timestamp without time zone(6) | Sí | now() |  |  |
| updated_at | timestamp without time zone(6) | Sí | now() |  |  |

#### Llave primaria
- users_pkey: id

#### Llaves foráneas
- Sin llaves foráneas

#### Índices
- users_pkey [PK, UNIQUE] (id) USING BTREE
- users_username_key [UNIQUE] (username) USING BTREE

#### Restricciones UNIQUE
- users_username_key: username

#### Restricciones CHECK
- users_email_check: CHECK (email::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)
- users_intentos_login_check: CHECK (intentos_login >= 0)
- users_password_hash_check: CHECK (length(password_hash::text) = 60)
- users_sucursal_id_check: CHECK (sucursal_id::text = ANY (ARRAY['SUR'::character varying, 'NORTE'::character varying, 'CENTRO'::character varying]::text[]))
- users_username_check: CHECK (length(username::text) >= 3)

