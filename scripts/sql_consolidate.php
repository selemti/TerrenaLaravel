<?php
// Consolidate SQL files in BD directory into a single PG 9.5-compatible deploy
// Passes: 1) base include; 2) append others skipping duplicates; 3) patch compat + add known triggers

$bd = __DIR__ . '/../BD';
if (!is_dir($bd)) { fwrite(STDERR, "BD folder not found\n"); exit(1); }

$ts = date('Ymd-His');
$out = "$bd/DEPLOY_CONSOLIDADO_FULL_PG95-v2-$ts.sql";
$report = "$bd/DEPLOY_REPORT-$ts.md";

function readFileUtf8($f){ $s = file_get_contents($f); if ($s === false) return ''; // strip BOM
  return preg_replace('/^\xEF\xBB\xBF/', '', $s);
}

// Choose base
$baseCandidates = [
  '000.  SISTEMA SELEMTI - ESQUEMA COMPLETO DE BASE DE DATOS- OK.sql',
  '000. deploy_selemti_full.sql',
  'selemti_deploy_inventarios_PG95_CONSOLIDADO_FINAL.sql'
];
$base = null; foreach($baseCandidates as $bn){ $fp = "$bd/$bn"; if (is_file($fp)) { $base=$fp; break; } }
if (!$base) { fwrite(STDERR, "Base file not found\n"); exit(2); }

// Collect others
$all = glob($bd.'/*.sql');
$others = array_values(array_filter($all, function($f) use ($base){ return realpath($f) !== realpath($base); }));
sort($others, SORT_NATURAL|SORT_FLAG_CASE);

// Registry for duplicates
$seen = [ 'schema'=>[], 'type'=>[], 'table'=>[], 'index'=>[], 'constraint'=>[], 'view'=>[], 'function'=>[], 'trigger'=>[] ];
$dups = [];

function keyNorm($s){ return strtolower(trim($s)); }

function registerObject(&$seen, &$dups, $kind, $name){ $k = keyNorm($name); if (isset($seen[$kind][$k])) { $dups[$kind][] = $name; return false; } $seen[$kind][$k]=true; return true; }

function patchCompat($sql){
  // Remove GENERATED ALWAYS AS ... STORED (PG95) and leave column as declared before GENERATED
  $sql = preg_replace('/(\bnumeric\(\d+,\d+\)\s+)GENERATED\s+ALWAYS\s+AS\s*\([^\)]*\)\s+STORED/i','${1}', $sql);
  return $sql;
}

function extractBlocks($sql){
  // Very crude split by semicolon retaining it; also keep DO $$ ... $$; as a single block
  $blocks=[]; $buf=''; $inDo=false; $i=0; $len=strlen($sql);
  while($i<$len){
    $ch=$sql[$i];
    if (!$inDo && stripos(substr($sql,$i,3),'DO ')===0 && preg_match('/DO\s*\$\$/Ai', substr($sql,$i,6))){ $inDo=true; }
    $buf.=$ch;
    if ($inDo && $ch===';' && preg_match('/\$\$\s*;\s*$/s', substr($buf,-5))){ $blocks[]=trim($buf); $buf=''; $inDo=false; }
    elseif(!$inDo && $ch===';'){ $blocks[]=trim($buf); $buf=''; }
    $i++;
  }
  if (trim($buf)!=='') $blocks[]=trim($buf);
  return $blocks;
}

function detectObject($blk){
  $b = strtolower($blk);
  // remove comments heads
  // Schemas
  if (preg_match('/create\s+schema\s+(if\s+not\s+exists\s+)?([a-z0-9_\.]+)/i',$blk,$m)) return ['schema', $m[2]];
  if (preg_match('/create\s+type\s+(if\s+not\s+exists\s+)?([a-z0-9_\.]+)/i',$blk,$m)) return ['type', $m[2]];
  if (preg_match('/create\s+(?:temporary\s+|unlogged\s+)?table\s+(if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)/i',$blk,$m)) return ['table', trim($m[2],'"')];
  if (preg_match('/create\s+(unique\s+)?index\s+(?:concurrently\s+)?(if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)\s+on\s+([a-z0-9_\.\"]+)/i',$blk,$m)) return ['index', trim($m[3],'"') . '::' . trim($m[4],'"')];
  if (preg_match('/alter\s+table\s+([a-z0-9_\.\"]+)\s+add\s+constraint\s+([a-z0-9_\.\"]+)/i',$blk,$m)) return ['constraint', trim($m[1],'"').'::'.trim($m[2],'"')];
  if (preg_match('/create\s+view\s+([a-z0-9_\.\"]+)\s+as/i',$blk,$m)) return ['view', trim($m[1],'"')];
  if (preg_match('/create\s+function\s+([a-z0-9_\.\"]+)\s*\(/i',$blk,$m)) return ['function', trim($m[1],'"')];
  if (preg_match('/create\s+trigger\s+([a-z0-9_\.\"]+)\s+.*?\s+on\s+([a-z0-9_\.\"]+)/is',$blk,$m)) return ['trigger', trim($m[1],'"').'@'.trim($m[2],'"')];
  return [null,null];
}

function consolidate($baseFile, $otherFiles, $out, &$seen, &$dups){
  $header = [];
  $header[] = '-- CONSOLIDATED OUTPUT';
  $header[] = '-- Generated: '.date('c');
  $header[] = 'SET client_min_messages TO warning;';
  $header[] = 'SET search_path TO selemti, public;';
  $header[] = "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'selemti') THEN EXECUTE 'CREATE SCHEMA selemti'; END IF; END $$;";
  file_put_contents($out, implode("\n", $header)."\n\n");

  $order = array_merge([$baseFile], $otherFiles);
  foreach($order as $f){ $name = basename($f); $raw = readFileUtf8($f); $raw = patchCompat($raw); $blocks = extractBlocks($raw);
    file_put_contents($out, "\n-- BEGIN $name\n", FILE_APPEND);
    foreach($blocks as $blk){ if ($blk==='') continue; list($kind,$obj) = detectObject($blk);
      if ($kind){ if (!registerObject($seen,$dups,$kind,$obj)) { continue; } }
      file_put_contents($out, $blk."\n", FILE_APPEND);
    }
    file_put_contents($out, "-- END $name\n", FILE_APPEND);
  }
}

consolidate($base, $others, $out, $seen, $dups);

// Append triggers for subtotal (public & selempos)
$tr = [];
$tr[] = "\n-- PG95 compatibility triggers for subtotal";
$tr[] = "DO $$ BEGIN";
$tr[] = "IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='pc_precorte_cash_count') THEN";
$tr[] = "  EXECUTE $$CREATE OR REPLACE FUNCTION public.pc_precorte_cash_count_biu() RETURNS trigger AS $$ BEGIN NEW.subtotal := NEW.denom * NEW.qty; RETURN NEW; END; $$ LANGUAGE plpgsql;$$;";
$tr[] = "  EXECUTE $$DO $$ BEGIN BEGIN CREATE TRIGGER pc_precorte_cash_count_biu BEFORE INSERT OR UPDATE ON public.pc_precorte_cash_count FOR EACH ROW EXECUTE FUNCTION public.pc_precorte_cash_count_biu(); EXCEPTION WHEN duplicate_object THEN NULL; END; END $$;$$;";
$tr[] = "END IF;";
$tr[] = "IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='selempos' AND table_name='selempos_precorte_cash') THEN";
$tr[] = "  EXECUTE $$CREATE OR REPLACE FUNCTION selempos.selempos_precorte_cash_biu() RETURNS trigger AS $$ BEGIN NEW.subtotal := NEW.denom * NEW.qty; RETURN NEW; END; $$ LANGUAGE plpgsql;$$;";
$tr[] = "  EXECUTE $$DO $$ BEGIN BEGIN CREATE TRIGGER selempos_precorte_cash_biu BEFORE INSERT OR UPDATE ON selempos.selempos_precorte_cash FOR EACH ROW EXECUTE FUNCTION selempos.selempos_precorte_cash_biu(); EXCEPTION WHEN duplicate_object THEN NULL; END; END $$;$$;";
$tr[] = "END IF;";
$tr[] = "END $$;\n";
file_put_contents($out, implode("\n", $tr), FILE_APPEND);

// Report
$rm = [];
$rm[] = '# Consolidation Report';
$rm[] = '- Base: '.basename($base);
$rm[] = '- Output: '.basename($out);
$rm[] = '## Objects added (counts)';
foreach($seen as $k=>$v){ $rm[] = "- $k: ".count($v); }
$rm[] = '## Duplicates skipped (samples)';
foreach($dups as $k=>$arr){ $rm[] = "- $k: ".count($arr); if ($arr) $rm[] = '  - '.implode(", ", array_slice(array_unique($arr),0,10)); }
file_put_contents($report, implode("\n", $rm));

echo "OK\n$out\n$report\n";
