
# ERD_SALES.md (esquema lógico mínimo)

Entidades relevantes:
- public.ticket (paid, voided, folio_date, terminal_id, branch_key, totals...)
- public.ticket_item (ticket_id, item_name, item_quantity, unit/total opcional)
- public.transactions (ticket_id, payment_type, transaction_type, amount, voided)
- public.terminal (id, name, location)
- public.menu_item (id, name, price) [opcional para reporting]
- public.ticket_item_modifier (id, ticket_item_id?, modifier_name, total_price, ...)
- public.ticket_item_modifier_relation (ticket_item_id, modifier_id)

Relaciones:
ticket 1—N ticket_item
ticket 1—N transactions
ticket_item 1—N ticket_item_modifier (directo) O N—N mediante ticket_item_modifier_relation
terminal 1—N ticket
