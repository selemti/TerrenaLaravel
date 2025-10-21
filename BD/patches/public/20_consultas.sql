-- AUTO-GENERATED from backup_pre_deploy_20251017_221857.sql
BEGIN;
SET search_path = selemti, public;
DROP VIEW IF EXISTS kds_orders_enhanced CASCADE;
CREATE OR REPLACE VIEW kds_orders_enhanced AS
 SELECT kt.id AS kitchen_ticket_id,
    kt.ticket_id,
    kt.create_date AS kds_created_at,
    kt.sequence_number,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    lpad((t.daily_folio)::text, 4, '0'::text) AS folio_display,
    t.number_of_guests,
    t.ticket_type,
    term.name AS terminal_name,
        CASE
            WHEN ((t.daily_folio >= 1) AND (t.daily_folio <= 20)) THEN 'PRIORITARIO'::text
            WHEN ((t.daily_folio >= 21) AND (t.daily_folio <= 50)) THEN 'NORMAL'::text
            ELSE 'ALTO_VOLUMEN'::text
        END AS prioridad_voceo
   FROM ((kitchen_ticket kt
     JOIN ticket t ON ((t.id = kt.ticket_id)))
     LEFT JOIN terminal term ON ((t.terminal_id = term.id)));



DROP VIEW IF EXISTS ticket_folio_complete CASCADE;
CREATE OR REPLACE VIEW ticket_folio_complete AS
 SELECT t.id,
    t.daily_folio,
    t.folio_date,
    t.branch_key,
    t.total_price,
    t.paid_amount,
    t.create_date,
    to_char((t.folio_date)::timestamp with time zone, 'DD/MM/YYYY'::text) AS folio_date_txt,
    lpad((t.daily_folio)::text, 4, '0'::text) AS folio_display,
    COALESCE(term.location, 'DEFAULT'::character varying) AS sucursal_completa,
    term.name AS terminal_name,
    to_char((t.folio_date)::timestamp with time zone, 'YYYY-MM'::text) AS periodo_mes,
    date_part('hour'::text, t.create_date) AS hora_venta,
    date_part('dow'::text, t.folio_date) AS dia_semana,
        CASE
            WHEN t.voided THEN 'CANCELADO'::text
            WHEN (t.paid_amount > (0)::double precision) THEN 'PAGADO'::text
            ELSE 'PENDIENTE'::text
        END AS status_simple
   FROM (ticket t
     LEFT JOIN terminal term ON ((t.terminal_id = term.id)));



DROP VIEW IF EXISTS vw_reconciliation_status CASCADE;
CREATE OR REPLACE VIEW vw_reconciliation_status AS
 SELECT (t.closing_date)::date AS report_date,
    t.terminal_id,
    count(DISTINCT t.id) AS tickets_count,
    count(tx.id) FILTER (WHERE ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[])))) AS transactions_count,
    (sum((t.total_price - t.total_discount)))::numeric(12,2) AS correct_total,
    (sum(
        CASE
            WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
            ELSE (0)::double precision
        END))::numeric(12,2) AS current_system_total,
    ((sum(
        CASE
            WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
            ELSE (0)::double precision
        END) - sum((t.total_price - t.total_discount))))::numeric(12,2) AS discrepancy,
        CASE
            WHEN (NULLIF(sum((t.total_price - t.total_discount)), (0)::double precision) IS NULL) THEN (0)::numeric
            ELSE round(((((sum(
            CASE
                WHEN ((tx.voided = false) AND ((tx.transaction_type)::text = 'CREDIT'::text) AND ((tx.payment_type)::text <> ALL ((ARRAY['REFUND'::character varying, 'VOID_TRANS'::character varying])::text[]))) THEN tx.amount
                ELSE (0)::double precision
            END) - sum((t.total_price - t.total_discount))) / sum((t.total_price - t.total_discount))) * (100)::double precision))::numeric, 2)
        END AS discrepancy_percent
   FROM (ticket t
     LEFT JOIN transactions tx ON ((tx.ticket_id = t.id)))
  WHERE ((t.paid = true) AND (t.voided = false) AND ((t.closing_date)::date >= (('now'::text)::date - '7 days'::interval)))
  GROUP BY ((t.closing_date)::date), t.terminal_id;



REVOKE ALL ON TABLE action_history FROM PUBLIC;
REVOKE ALL ON TABLE action_history FROM floreant;
GRANT ALL ON TABLE action_history TO floreant;
GRANT SELECT ON TABLE action_history TO selemti_user;


REVOKE ALL ON TABLE attendence_history FROM PUBLIC;
REVOKE ALL ON TABLE attendence_history FROM floreant;
GRANT ALL ON TABLE attendence_history TO floreant;
GRANT SELECT ON TABLE attendence_history TO selemti_user;


REVOKE ALL ON TABLE cash_drawer FROM PUBLIC;
REVOKE ALL ON TABLE cash_drawer FROM floreant;
GRANT ALL ON TABLE cash_drawer TO floreant;
GRANT SELECT ON TABLE cash_drawer TO selemti_user;


REVOKE ALL ON TABLE cash_drawer_reset_history FROM PUBLIC;
REVOKE ALL ON TABLE cash_drawer_reset_history FROM floreant;
GRANT ALL ON TABLE cash_drawer_reset_history TO floreant;
GRANT SELECT ON TABLE cash_drawer_reset_history TO selemti_user;


REVOKE ALL ON TABLE cooking_instruction FROM PUBLIC;
REVOKE ALL ON TABLE cooking_instruction FROM floreant;
GRANT ALL ON TABLE cooking_instruction TO floreant;
GRANT SELECT ON TABLE cooking_instruction TO selemti_user;


REVOKE ALL ON TABLE coupon_and_discount FROM PUBLIC;
REVOKE ALL ON TABLE coupon_and_discount FROM floreant;
GRANT ALL ON TABLE coupon_and_discount TO floreant;
GRANT SELECT ON TABLE coupon_and_discount TO selemti_user;


REVOKE ALL ON TABLE currency FROM PUBLIC;
REVOKE ALL ON TABLE currency FROM floreant;
GRANT ALL ON TABLE currency TO floreant;
GRANT SELECT ON TABLE currency TO selemti_user;


REVOKE ALL ON TABLE currency_balance FROM PUBLIC;
REVOKE ALL ON TABLE currency_balance FROM floreant;
GRANT ALL ON TABLE currency_balance TO floreant;
GRANT SELECT ON TABLE currency_balance TO selemti_user;


REVOKE ALL ON TABLE custom_payment FROM PUBLIC;
REVOKE ALL ON TABLE custom_payment FROM floreant;
GRANT ALL ON TABLE custom_payment TO floreant;
GRANT SELECT ON TABLE custom_payment TO selemti_user;


REVOKE ALL ON TABLE customer FROM PUBLIC;
REVOKE ALL ON TABLE customer FROM floreant;
GRANT ALL ON TABLE customer TO floreant;
GRANT SELECT ON TABLE customer TO selemti_user;


REVOKE ALL ON TABLE customer_properties FROM PUBLIC;
REVOKE ALL ON TABLE customer_properties FROM floreant;
GRANT ALL ON TABLE customer_properties TO floreant;
GRANT SELECT ON TABLE customer_properties TO selemti_user;


REVOKE ALL ON TABLE daily_folio_counter FROM PUBLIC;
REVOKE ALL ON TABLE daily_folio_counter FROM floreant;
GRANT ALL ON TABLE daily_folio_counter TO floreant;
GRANT SELECT ON TABLE daily_folio_counter TO selemti_user;


REVOKE ALL ON TABLE data_update_info FROM PUBLIC;
REVOKE ALL ON TABLE data_update_info FROM floreant;
GRANT ALL ON TABLE data_update_info TO floreant;
GRANT SELECT ON TABLE data_update_info TO selemti_user;


REVOKE ALL ON TABLE delivery_address FROM PUBLIC;
REVOKE ALL ON TABLE delivery_address FROM floreant;
GRANT ALL ON TABLE delivery_address TO floreant;
GRANT SELECT ON TABLE delivery_address TO selemti_user;


REVOKE ALL ON TABLE delivery_charge FROM PUBLIC;
REVOKE ALL ON TABLE delivery_charge FROM floreant;
GRANT ALL ON TABLE delivery_charge TO floreant;
GRANT SELECT ON TABLE delivery_charge TO selemti_user;


REVOKE ALL ON TABLE delivery_configuration FROM PUBLIC;
REVOKE ALL ON TABLE delivery_configuration FROM floreant;
GRANT ALL ON TABLE delivery_configuration TO floreant;
GRANT SELECT ON TABLE delivery_configuration TO selemti_user;


REVOKE ALL ON TABLE delivery_instruction FROM PUBLIC;
REVOKE ALL ON TABLE delivery_instruction FROM floreant;
GRANT ALL ON TABLE delivery_instruction TO floreant;
GRANT SELECT ON TABLE delivery_instruction TO selemti_user;


REVOKE ALL ON TABLE drawer_assigned_history FROM PUBLIC;
REVOKE ALL ON TABLE drawer_assigned_history FROM floreant;
GRANT ALL ON TABLE drawer_assigned_history TO floreant;
GRANT SELECT ON TABLE drawer_assigned_history TO selemti_user;


REVOKE ALL ON TABLE drawer_pull_report FROM PUBLIC;
REVOKE ALL ON TABLE drawer_pull_report FROM floreant;
GRANT ALL ON TABLE drawer_pull_report TO floreant;
GRANT SELECT ON TABLE drawer_pull_report TO selemti_user;


REVOKE ALL ON TABLE drawer_pull_report_voidtickets FROM PUBLIC;
REVOKE ALL ON TABLE drawer_pull_report_voidtickets FROM floreant;
GRANT ALL ON TABLE drawer_pull_report_voidtickets TO floreant;
GRANT SELECT ON TABLE drawer_pull_report_voidtickets TO selemti_user;


REVOKE ALL ON TABLE employee_in_out_history FROM PUBLIC;
REVOKE ALL ON TABLE employee_in_out_history FROM floreant;
GRANT ALL ON TABLE employee_in_out_history TO floreant;
GRANT SELECT ON TABLE employee_in_out_history TO selemti_user;


REVOKE ALL ON TABLE global_config FROM PUBLIC;
REVOKE ALL ON TABLE global_config FROM floreant;
GRANT ALL ON TABLE global_config TO floreant;
GRANT SELECT ON TABLE global_config TO selemti_user;


REVOKE ALL ON TABLE gratuity FROM PUBLIC;
REVOKE ALL ON TABLE gratuity FROM floreant;
GRANT ALL ON TABLE gratuity TO floreant;
GRANT SELECT ON TABLE gratuity TO selemti_user;


REVOKE ALL ON TABLE group_taxes FROM PUBLIC;
REVOKE ALL ON TABLE group_taxes FROM floreant;
GRANT ALL ON TABLE group_taxes TO floreant;
GRANT SELECT ON TABLE group_taxes TO selemti_user;


REVOKE ALL ON TABLE guest_check_print FROM PUBLIC;
REVOKE ALL ON TABLE guest_check_print FROM floreant;
GRANT ALL ON TABLE guest_check_print TO floreant;
GRANT SELECT ON TABLE guest_check_print TO selemti_user;


REVOKE ALL ON TABLE inventory_group FROM PUBLIC;
REVOKE ALL ON TABLE inventory_group FROM floreant;
GRANT ALL ON TABLE inventory_group TO floreant;
GRANT SELECT ON TABLE inventory_group TO selemti_user;


REVOKE ALL ON TABLE inventory_item FROM PUBLIC;
REVOKE ALL ON TABLE inventory_item FROM floreant;
GRANT ALL ON TABLE inventory_item TO floreant;
GRANT SELECT ON TABLE inventory_item TO selemti_user;


REVOKE ALL ON TABLE inventory_location FROM PUBLIC;
REVOKE ALL ON TABLE inventory_location FROM floreant;
GRANT ALL ON TABLE inventory_location TO floreant;
GRANT SELECT ON TABLE inventory_location TO selemti_user;


REVOKE ALL ON TABLE inventory_meta_code FROM PUBLIC;
REVOKE ALL ON TABLE inventory_meta_code FROM floreant;
GRANT ALL ON TABLE inventory_meta_code TO floreant;
GRANT SELECT ON TABLE inventory_meta_code TO selemti_user;


REVOKE ALL ON TABLE inventory_transaction FROM PUBLIC;
REVOKE ALL ON TABLE inventory_transaction FROM floreant;
GRANT ALL ON TABLE inventory_transaction TO floreant;
GRANT SELECT ON TABLE inventory_transaction TO selemti_user;


REVOKE ALL ON TABLE inventory_unit FROM PUBLIC;
REVOKE ALL ON TABLE inventory_unit FROM floreant;
GRANT ALL ON TABLE inventory_unit TO floreant;
GRANT SELECT ON TABLE inventory_unit TO selemti_user;


REVOKE ALL ON TABLE inventory_vendor FROM PUBLIC;
REVOKE ALL ON TABLE inventory_vendor FROM floreant;
GRANT ALL ON TABLE inventory_vendor TO floreant;
GRANT SELECT ON TABLE inventory_vendor TO selemti_user;


REVOKE ALL ON TABLE inventory_warehouse FROM PUBLIC;
REVOKE ALL ON TABLE inventory_warehouse FROM floreant;
GRANT ALL ON TABLE inventory_warehouse TO floreant;
GRANT SELECT ON TABLE inventory_warehouse TO selemti_user;


REVOKE ALL ON TABLE item_order_type FROM PUBLIC;
REVOKE ALL ON TABLE item_order_type FROM floreant;
GRANT ALL ON TABLE item_order_type TO floreant;
GRANT SELECT ON TABLE item_order_type TO selemti_user;


REVOKE ALL ON TABLE kitchen_ticket FROM PUBLIC;
REVOKE ALL ON TABLE kitchen_ticket FROM floreant;
GRANT ALL ON TABLE kitchen_ticket TO floreant;
GRANT SELECT ON TABLE kitchen_ticket TO selemti_user;


REVOKE ALL ON TABLE terminal FROM PUBLIC;
REVOKE ALL ON TABLE terminal FROM floreant;
GRANT ALL ON TABLE terminal TO floreant;
GRANT SELECT ON TABLE terminal TO selemti_user;


REVOKE ALL ON TABLE ticket FROM PUBLIC;
REVOKE ALL ON TABLE ticket FROM floreant;
GRANT ALL ON TABLE ticket TO floreant;
GRANT SELECT ON TABLE ticket TO selemti_user;


REVOKE ALL ON TABLE kds_orders_enhanced FROM PUBLIC;
REVOKE ALL ON TABLE kds_orders_enhanced FROM floreant;
GRANT ALL ON TABLE kds_orders_enhanced TO floreant;
GRANT SELECT ON TABLE kds_orders_enhanced TO selemti_user;


REVOKE ALL ON TABLE kds_ready_log FROM PUBLIC;
REVOKE ALL ON TABLE kds_ready_log FROM floreant;
GRANT ALL ON TABLE kds_ready_log TO floreant;
GRANT SELECT ON TABLE kds_ready_log TO selemti_user;


REVOKE ALL ON TABLE kit_ticket_table_num FROM PUBLIC;
REVOKE ALL ON TABLE kit_ticket_table_num FROM floreant;
GRANT ALL ON TABLE kit_ticket_table_num TO floreant;
GRANT SELECT ON TABLE kit_ticket_table_num TO selemti_user;


REVOKE ALL ON TABLE kitchen_ticket_item FROM PUBLIC;
REVOKE ALL ON TABLE kitchen_ticket_item FROM floreant;
GRANT ALL ON TABLE kitchen_ticket_item TO floreant;
GRANT SELECT ON TABLE kitchen_ticket_item TO selemti_user;


REVOKE ALL ON TABLE menu_category FROM PUBLIC;
REVOKE ALL ON TABLE menu_category FROM floreant;
GRANT ALL ON TABLE menu_category TO floreant;
GRANT SELECT ON TABLE menu_category TO selemti_user;


REVOKE ALL ON TABLE menu_group FROM PUBLIC;
REVOKE ALL ON TABLE menu_group FROM floreant;
GRANT ALL ON TABLE menu_group TO floreant;
GRANT SELECT ON TABLE menu_group TO selemti_user;


REVOKE ALL ON TABLE menu_item FROM PUBLIC;
REVOKE ALL ON TABLE menu_item FROM floreant;
GRANT ALL ON TABLE menu_item TO floreant;
GRANT SELECT ON TABLE menu_item TO selemti_user;


REVOKE ALL ON TABLE menu_item_properties FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_properties FROM floreant;
GRANT ALL ON TABLE menu_item_properties TO floreant;
GRANT SELECT ON TABLE menu_item_properties TO selemti_user;


REVOKE ALL ON TABLE menu_item_size FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_size FROM floreant;
GRANT ALL ON TABLE menu_item_size TO floreant;
GRANT SELECT ON TABLE menu_item_size TO selemti_user;


REVOKE ALL ON TABLE menu_item_terminal_ref FROM PUBLIC;
REVOKE ALL ON TABLE menu_item_terminal_ref FROM floreant;
GRANT ALL ON TABLE menu_item_terminal_ref TO floreant;
GRANT SELECT ON TABLE menu_item_terminal_ref TO selemti_user;


REVOKE ALL ON TABLE menu_modifier FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier FROM floreant;
GRANT ALL ON TABLE menu_modifier TO floreant;
GRANT SELECT ON TABLE menu_modifier TO selemti_user;


REVOKE ALL ON TABLE menu_modifier_group FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier_group FROM floreant;
GRANT ALL ON TABLE menu_modifier_group TO floreant;
GRANT SELECT ON TABLE menu_modifier_group TO selemti_user;


REVOKE ALL ON TABLE menu_modifier_properties FROM PUBLIC;
REVOKE ALL ON TABLE menu_modifier_properties FROM floreant;
GRANT ALL ON TABLE menu_modifier_properties TO floreant;
GRANT SELECT ON TABLE menu_modifier_properties TO selemti_user;


REVOKE ALL ON TABLE menucategory_discount FROM PUBLIC;
REVOKE ALL ON TABLE menucategory_discount FROM floreant;
GRANT ALL ON TABLE menucategory_discount TO floreant;
GRANT SELECT ON TABLE menucategory_discount TO selemti_user;


REVOKE ALL ON TABLE menugroup_discount FROM PUBLIC;
REVOKE ALL ON TABLE menugroup_discount FROM floreant;
GRANT ALL ON TABLE menugroup_discount TO floreant;
GRANT SELECT ON TABLE menugroup_discount TO selemti_user;


REVOKE ALL ON TABLE menuitem_discount FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_discount FROM floreant;
GRANT ALL ON TABLE menuitem_discount TO floreant;
GRANT SELECT ON TABLE menuitem_discount TO selemti_user;


REVOKE ALL ON TABLE menuitem_modifiergroup FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_modifiergroup FROM floreant;
GRANT ALL ON TABLE menuitem_modifiergroup TO floreant;
GRANT SELECT ON TABLE menuitem_modifiergroup TO selemti_user;


REVOKE ALL ON TABLE menuitem_pizzapirce FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_pizzapirce FROM floreant;
GRANT ALL ON TABLE menuitem_pizzapirce TO floreant;
GRANT SELECT ON TABLE menuitem_pizzapirce TO selemti_user;


REVOKE ALL ON TABLE menuitem_shift FROM PUBLIC;
REVOKE ALL ON TABLE menuitem_shift FROM floreant;
GRANT ALL ON TABLE menuitem_shift TO floreant;
GRANT SELECT ON TABLE menuitem_shift TO selemti_user;


REVOKE ALL ON TABLE menumodifier_pizzamodifierprice FROM PUBLIC;
REVOKE ALL ON TABLE menumodifier_pizzamodifierprice FROM floreant;
GRANT ALL ON TABLE menumodifier_pizzamodifierprice TO floreant;
GRANT SELECT ON TABLE menumodifier_pizzamodifierprice TO selemti_user;


REVOKE ALL ON TABLE migrations FROM PUBLIC;
REVOKE ALL ON TABLE migrations FROM postgres;
GRANT ALL ON TABLE migrations TO postgres;
GRANT SELECT ON TABLE migrations TO selemti_user;


REVOKE ALL ON TABLE modifier_multiplier_price FROM PUBLIC;
REVOKE ALL ON TABLE modifier_multiplier_price FROM floreant;
GRANT ALL ON TABLE modifier_multiplier_price TO floreant;
GRANT SELECT ON TABLE modifier_multiplier_price TO selemti_user;


REVOKE ALL ON TABLE multiplier FROM PUBLIC;
REVOKE ALL ON TABLE multiplier FROM floreant;
GRANT ALL ON TABLE multiplier TO floreant;
GRANT SELECT ON TABLE multiplier TO selemti_user;


REVOKE ALL ON TABLE order_type FROM PUBLIC;
REVOKE ALL ON TABLE order_type FROM floreant;
GRANT ALL ON TABLE order_type TO floreant;
GRANT SELECT ON TABLE order_type TO selemti_user;


REVOKE ALL ON TABLE packaging_unit FROM PUBLIC;
REVOKE ALL ON TABLE packaging_unit FROM floreant;
GRANT ALL ON TABLE packaging_unit TO floreant;
GRANT SELECT ON TABLE packaging_unit TO selemti_user;


REVOKE ALL ON TABLE payout_reasons FROM PUBLIC;
REVOKE ALL ON TABLE payout_reasons FROM floreant;
GRANT ALL ON TABLE payout_reasons TO floreant;
GRANT SELECT ON TABLE payout_reasons TO selemti_user;


REVOKE ALL ON TABLE payout_recepients FROM PUBLIC;
REVOKE ALL ON TABLE payout_recepients FROM floreant;
GRANT ALL ON TABLE payout_recepients TO floreant;
GRANT SELECT ON TABLE payout_recepients TO selemti_user;


REVOKE ALL ON TABLE pizza_crust FROM PUBLIC;
REVOKE ALL ON TABLE pizza_crust FROM floreant;
GRANT ALL ON TABLE pizza_crust TO floreant;
GRANT SELECT ON TABLE pizza_crust TO selemti_user;


REVOKE ALL ON TABLE pizza_modifier_price FROM PUBLIC;
REVOKE ALL ON TABLE pizza_modifier_price FROM floreant;
GRANT ALL ON TABLE pizza_modifier_price TO floreant;
GRANT SELECT ON TABLE pizza_modifier_price TO selemti_user;


REVOKE ALL ON TABLE pizza_price FROM PUBLIC;
REVOKE ALL ON TABLE pizza_price FROM floreant;
GRANT ALL ON TABLE pizza_price TO floreant;
GRANT SELECT ON TABLE pizza_price TO selemti_user;


REVOKE ALL ON TABLE printer_configuration FROM PUBLIC;
REVOKE ALL ON TABLE printer_configuration FROM floreant;
GRANT ALL ON TABLE printer_configuration TO floreant;
GRANT SELECT ON TABLE printer_configuration TO selemti_user;


REVOKE ALL ON TABLE printer_group FROM PUBLIC;
REVOKE ALL ON TABLE printer_group FROM floreant;
GRANT ALL ON TABLE printer_group TO floreant;
GRANT SELECT ON TABLE printer_group TO selemti_user;


REVOKE ALL ON TABLE printer_group_printers FROM PUBLIC;
REVOKE ALL ON TABLE printer_group_printers FROM floreant;
GRANT ALL ON TABLE printer_group_printers TO floreant;
GRANT SELECT ON TABLE printer_group_printers TO selemti_user;


REVOKE ALL ON TABLE purchase_order FROM PUBLIC;
REVOKE ALL ON TABLE purchase_order FROM floreant;
GRANT ALL ON TABLE purchase_order TO floreant;
GRANT SELECT ON TABLE purchase_order TO selemti_user;


REVOKE ALL ON TABLE recepie FROM PUBLIC;
REVOKE ALL ON TABLE recepie FROM floreant;
GRANT ALL ON TABLE recepie TO floreant;
GRANT SELECT ON TABLE recepie TO selemti_user;


REVOKE ALL ON TABLE recepie_item FROM PUBLIC;
REVOKE ALL ON TABLE recepie_item FROM floreant;
GRANT ALL ON TABLE recepie_item TO floreant;
GRANT SELECT ON TABLE recepie_item TO selemti_user;


REVOKE ALL ON TABLE restaurant FROM PUBLIC;
REVOKE ALL ON TABLE restaurant FROM floreant;
GRANT ALL ON TABLE restaurant TO floreant;
GRANT SELECT ON TABLE restaurant TO selemti_user;


REVOKE ALL ON TABLE restaurant_properties FROM PUBLIC;
REVOKE ALL ON TABLE restaurant_properties FROM floreant;
GRANT ALL ON TABLE restaurant_properties TO floreant;
GRANT SELECT ON TABLE restaurant_properties TO selemti_user;


REVOKE ALL ON TABLE shift FROM PUBLIC;
REVOKE ALL ON TABLE shift FROM floreant;
GRANT ALL ON TABLE shift TO floreant;
GRANT SELECT ON TABLE shift TO selemti_user;


REVOKE ALL ON TABLE shop_floor FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor FROM floreant;
GRANT ALL ON TABLE shop_floor TO floreant;
GRANT SELECT ON TABLE shop_floor TO selemti_user;


REVOKE ALL ON TABLE shop_floor_template FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor_template FROM floreant;
GRANT ALL ON TABLE shop_floor_template TO floreant;
GRANT SELECT ON TABLE shop_floor_template TO selemti_user;


REVOKE ALL ON TABLE shop_floor_template_properties FROM PUBLIC;
REVOKE ALL ON TABLE shop_floor_template_properties FROM floreant;
GRANT ALL ON TABLE shop_floor_template_properties TO floreant;
GRANT SELECT ON TABLE shop_floor_template_properties TO selemti_user;


REVOKE ALL ON TABLE shop_table FROM PUBLIC;
REVOKE ALL ON TABLE shop_table FROM floreant;
GRANT ALL ON TABLE shop_table TO floreant;
GRANT SELECT ON TABLE shop_table TO selemti_user;


REVOKE ALL ON TABLE shop_table_status FROM PUBLIC;
REVOKE ALL ON TABLE shop_table_status FROM floreant;
GRANT ALL ON TABLE shop_table_status TO floreant;
GRANT SELECT ON TABLE shop_table_status TO selemti_user;


REVOKE ALL ON TABLE shop_table_type FROM PUBLIC;
REVOKE ALL ON TABLE shop_table_type FROM floreant;
GRANT ALL ON TABLE shop_table_type TO floreant;
GRANT SELECT ON TABLE shop_table_type TO selemti_user;


REVOKE ALL ON TABLE table_booking_info FROM PUBLIC;
REVOKE ALL ON TABLE table_booking_info FROM floreant;
GRANT ALL ON TABLE table_booking_info TO floreant;
GRANT SELECT ON TABLE table_booking_info TO selemti_user;


REVOKE ALL ON TABLE table_booking_mapping FROM PUBLIC;
REVOKE ALL ON TABLE table_booking_mapping FROM floreant;
GRANT ALL ON TABLE table_booking_mapping TO floreant;
GRANT SELECT ON TABLE table_booking_mapping TO selemti_user;


REVOKE ALL ON TABLE table_ticket_num FROM PUBLIC;
REVOKE ALL ON TABLE table_ticket_num FROM floreant;
GRANT ALL ON TABLE table_ticket_num TO floreant;
GRANT SELECT ON TABLE table_ticket_num TO selemti_user;


REVOKE ALL ON TABLE table_type_relation FROM PUBLIC;
REVOKE ALL ON TABLE table_type_relation FROM floreant;
GRANT ALL ON TABLE table_type_relation TO floreant;
GRANT SELECT ON TABLE table_type_relation TO selemti_user;


REVOKE ALL ON TABLE tax FROM PUBLIC;
REVOKE ALL ON TABLE tax FROM floreant;
GRANT ALL ON TABLE tax TO floreant;
GRANT SELECT ON TABLE tax TO selemti_user;


REVOKE ALL ON TABLE tax_group FROM PUBLIC;
REVOKE ALL ON TABLE tax_group FROM floreant;
GRANT ALL ON TABLE tax_group TO floreant;
GRANT SELECT ON TABLE tax_group TO selemti_user;


REVOKE ALL ON TABLE terminal_printers FROM PUBLIC;
REVOKE ALL ON TABLE terminal_printers FROM floreant;
GRANT ALL ON TABLE terminal_printers TO floreant;
GRANT SELECT ON TABLE terminal_printers TO selemti_user;


REVOKE ALL ON TABLE terminal_properties FROM PUBLIC;
REVOKE ALL ON TABLE terminal_properties FROM floreant;
GRANT ALL ON TABLE terminal_properties TO floreant;
GRANT SELECT ON TABLE terminal_properties TO selemti_user;


REVOKE ALL ON TABLE ticket_discount FROM PUBLIC;
REVOKE ALL ON TABLE ticket_discount FROM floreant;
GRANT ALL ON TABLE ticket_discount TO floreant;
GRANT SELECT ON TABLE ticket_discount TO selemti_user;


REVOKE ALL ON TABLE ticket_folio_complete FROM PUBLIC;
REVOKE ALL ON TABLE ticket_folio_complete FROM floreant;
GRANT ALL ON TABLE ticket_folio_complete TO floreant;
GRANT SELECT ON TABLE ticket_folio_complete TO selemti_user;


REVOKE ALL ON TABLE ticket_item FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item FROM floreant;
GRANT ALL ON TABLE ticket_item TO floreant;
GRANT SELECT ON TABLE ticket_item TO selemti_user;


REVOKE ALL ON TABLE ticket_item_addon_relation FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_addon_relation FROM floreant;
GRANT ALL ON TABLE ticket_item_addon_relation TO floreant;
GRANT SELECT ON TABLE ticket_item_addon_relation TO selemti_user;


REVOKE ALL ON TABLE ticket_item_cooking_instruction FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_cooking_instruction FROM floreant;
GRANT ALL ON TABLE ticket_item_cooking_instruction TO floreant;
GRANT SELECT ON TABLE ticket_item_cooking_instruction TO selemti_user;


REVOKE ALL ON TABLE ticket_item_discount FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_discount FROM floreant;
GRANT ALL ON TABLE ticket_item_discount TO floreant;
GRANT SELECT ON TABLE ticket_item_discount TO selemti_user;


REVOKE ALL ON TABLE ticket_item_modifier FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_modifier FROM floreant;
GRANT ALL ON TABLE ticket_item_modifier TO floreant;
GRANT SELECT ON TABLE ticket_item_modifier TO selemti_user;


REVOKE ALL ON TABLE ticket_item_modifier_relation FROM PUBLIC;
REVOKE ALL ON TABLE ticket_item_modifier_relation FROM floreant;
GRANT ALL ON TABLE ticket_item_modifier_relation TO floreant;
GRANT SELECT ON TABLE ticket_item_modifier_relation TO selemti_user;


REVOKE ALL ON TABLE ticket_properties FROM PUBLIC;
REVOKE ALL ON TABLE ticket_properties FROM floreant;
GRANT ALL ON TABLE ticket_properties TO floreant;
GRANT SELECT ON TABLE ticket_properties TO selemti_user;


REVOKE ALL ON TABLE ticket_table_num FROM PUBLIC;
REVOKE ALL ON TABLE ticket_table_num FROM floreant;
GRANT ALL ON TABLE ticket_table_num TO floreant;
GRANT SELECT ON TABLE ticket_table_num TO selemti_user;


REVOKE ALL ON TABLE transaction_properties FROM PUBLIC;
REVOKE ALL ON TABLE transaction_properties FROM floreant;
GRANT ALL ON TABLE transaction_properties TO floreant;
GRANT SELECT ON TABLE transaction_properties TO selemti_user;


REVOKE ALL ON TABLE transactions FROM PUBLIC;
REVOKE ALL ON TABLE transactions FROM floreant;
GRANT ALL ON TABLE transactions TO floreant;
GRANT SELECT ON TABLE transactions TO selemti_user;


REVOKE ALL ON TABLE user_permission FROM PUBLIC;
REVOKE ALL ON TABLE user_permission FROM floreant;
GRANT ALL ON TABLE user_permission TO floreant;
GRANT SELECT ON TABLE user_permission TO selemti_user;


REVOKE ALL ON TABLE user_type FROM PUBLIC;
REVOKE ALL ON TABLE user_type FROM floreant;
GRANT ALL ON TABLE user_type TO floreant;
GRANT SELECT ON TABLE user_type TO selemti_user;


REVOKE ALL ON TABLE user_user_permission FROM PUBLIC;
REVOKE ALL ON TABLE user_user_permission FROM floreant;
GRANT ALL ON TABLE user_user_permission TO floreant;
GRANT SELECT ON TABLE user_user_permission TO selemti_user;


REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE users FROM floreant;
GRANT ALL ON TABLE users TO floreant;
GRANT SELECT ON TABLE users TO selemti_user;


REVOKE ALL ON TABLE virtual_printer FROM PUBLIC;
REVOKE ALL ON TABLE virtual_printer FROM floreant;
GRANT ALL ON TABLE virtual_printer TO floreant;
GRANT SELECT ON TABLE virtual_printer TO selemti_user;


REVOKE ALL ON TABLE virtualprinter_order_type FROM PUBLIC;
REVOKE ALL ON TABLE virtualprinter_order_type FROM floreant;
GRANT ALL ON TABLE virtualprinter_order_type TO floreant;
GRANT SELECT ON TABLE virtualprinter_order_type TO selemti_user;


REVOKE ALL ON TABLE void_reasons FROM PUBLIC;
REVOKE ALL ON TABLE void_reasons FROM floreant;
GRANT ALL ON TABLE void_reasons TO floreant;
GRANT SELECT ON TABLE void_reasons TO selemti_user;


REVOKE ALL ON TABLE vw_reconciliation_status FROM PUBLIC;
REVOKE ALL ON TABLE vw_reconciliation_status FROM postgres;
GRANT ALL ON TABLE vw_reconciliation_status TO postgres;
GRANT SELECT ON TABLE vw_reconciliation_status TO selemti_user;


REVOKE ALL ON TABLE zip_code_vs_delivery_charge FROM PUBLIC;
REVOKE ALL ON TABLE zip_code_vs_delivery_charge FROM floreant;
GRANT ALL ON TABLE zip_code_vs_delivery_charge TO floreant;
GRANT SELECT ON TABLE zip_code_vs_delivery_charge TO selemti_user;


SET search_path = selemti, pg_catalog;

COMMIT;
