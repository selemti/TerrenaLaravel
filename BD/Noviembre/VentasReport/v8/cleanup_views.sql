-- ============================================================================
-- Terrena · Reportes de Ventas - Script Corregido con CASCADE
-- ============================================================================
SET TIME ZONE 'America/Mexico_City';
SET search_path TO public, selemti;

-- Eliminar vistas dependientes primero
DROP VIEW IF EXISTS public.vw_diag_drawer_vs_cash_transactions CASCADE;
DROP VIEW IF EXISTS public.vw_daily_diagnostics_summary CASCADE;
DROP VIEW IF EXISTS public.vw_item_mods_detailed_today CASCADE;
DROP VIEW IF EXISTS public.vw_item_mods_daily_summary CASCADE;
DROP VIEW IF EXISTS public.vw_item_mods_by_item_today CASCADE;
DROP VIEW IF EXISTS public.vw_sales_mix_payment_today CASCADE;

-- Ahora eliminar funciones
DROP FUNCTION IF EXISTS public.f_diag_drawer_vs_cash_transactions_on(date) CASCADE;
DROP FUNCTION IF EXISTS public.f_daily_diagnostics_summary_on(date) CASCADE;
DROP FUNCTION IF EXISTS public.f_item_mods_detailed_on(date) CASCADE;
DROP FUNCTION IF EXISTS public.f_sales_mix_payment_on(date) CASCADE;

SELECT 'Vistas y funciones eliminadas con CASCADE' as status;
