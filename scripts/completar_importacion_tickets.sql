-- SCRIPT PARA COMPLETAR IMPORTACIÓN DE TICKETS FALTANTES
-- Se detuvo en ticket_id = 46276, necesitamos importar hasta 98,851

-- Verificar estado actual
SELECT 'ESTADO ACTUAL:' as info;
SELECT 'Tickets importados:' as descripcion, COUNT(*) as total FROM public.ticket;
SELECT 'ID máximo importado:' as descripcion, MAX(id) as max_id FROM public.ticket;
SELECT 'Tickets faltantes:' as descripcion, 98851 - COUNT(*) as faltantes FROM public.ticket;

-- Continuar importación desde donde se detuvo
-- Necesitamos importar los INSERT INTO public.ticket con id > 46276