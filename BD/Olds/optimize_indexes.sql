SET search_path TO selemti, public;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='mov_inv') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_ts') THEN
      EXECUTE 'CREATE INDEX ix_mov_ts ON selemti.mov_inv (ts)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_tipo') THEN
      EXECUTE 'CREATE INDEX ix_mov_tipo ON selemti.mov_inv (tipo)';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='mov_inv' AND column_name='item_id') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_item_id') THEN
        EXECUTE 'CREATE INDEX ix_mov_item_id ON selemti.mov_inv (item_id)';
      END IF;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='mov_inv' AND column_name='insumo_id') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_insumo_id') THEN
        EXECUTE 'CREATE INDEX ix_mov_insumo_id ON selemti.mov_inv (insumo_id)';
      END IF;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='mov_inv' AND column_name='sucursal_id') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_sucursal') THEN
        EXECUTE 'CREATE INDEX ix_mov_sucursal ON selemti.mov_inv (sucursal_id)';
      END IF;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='mov_inv' AND column_name='ref_tipo') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_mov_ref') THEN
        EXECUTE 'CREATE INDEX ix_mov_ref ON selemti.mov_inv (ref_tipo, ref_id)';
      END IF;
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='inventory_batch') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_ib_item_caduc') THEN
      EXECUTE 'CREATE INDEX ix_ib_item_caduc ON selemti.inventory_batch (item_id, fecha_caducidad)';
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='pos_map') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_pm_plu') THEN
      EXECUTE 'CREATE INDEX ix_pm_plu ON selemti.pos_map (plu)';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='selemti' AND table_name='pos_map' AND column_name='vigente_hasta') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_pm_vigencia') THEN
        EXECUTE 'CREATE INDEX ix_pm_vigencia ON selemti.pos_map (vigente_hasta)';
      END IF;
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='hist_cost_insumo') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_hist_cost_insumo') THEN
      EXECUTE 'CREATE INDEX ix_hist_cost_insumo ON selemti.hist_cost_insumo (insumo_id, fecha_efectiva DESC)';
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='receta_version') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_rv_id') THEN
      EXECUTE 'CREATE INDEX ix_rv_id ON selemti.receta_version (id)';
    END IF;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='receta_insumo') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_ri_rv') THEN
      EXECUTE 'CREATE INDEX ix_ri_rv ON selemti.receta_insumo (receta_version_id)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_ri_insumo') THEN
      EXECUTE 'CREATE INDEX ix_ri_insumo ON selemti.receta_insumo (insumo_id)';
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selemti' AND table_name='stock_policy') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='selemti' AND indexname='ix_sp_item_suc') THEN
      EXECUTE 'CREATE INDEX ix_sp_item_suc ON selemti.stock_policy (item_id, sucursal_id)';
    END IF;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='ticket') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='ix_ticket_date_term') THEN
      EXECUTE 'CREATE INDEX ix_ticket_date_term ON public.ticket (closing_date, terminal_id)';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ticket' AND column_name='location') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='ix_ticket_location') THEN
        EXECUTE 'CREATE INDEX ix_ticket_location ON public.ticket (location)';
      END IF;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='ticket' AND column_name='branch_key') THEN
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND indexname='ix_ticket_branch') THEN
        EXECUTE 'CREATE INDEX ix_ticket_branch ON public.ticket (branch_key)';
      END IF;
    END IF;
  END IF;
END $$;
