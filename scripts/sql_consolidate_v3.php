<?php
$bd = __DIR__ . '/../BD';
if (!is_dir($bd)) { fwrite(STDERR, "BD folder not found\n"); exit(1); }
$ts = date('Ymd-His');
$out = "$bd/DEPLOY_CONSOLIDADO_FULL_PG95-v3-$ts.sql";
$report = "$bd/DEPLOY_REPORT-v3-$ts.md";

function readFileUtf8($f){ $s = file_get_contents($f); if ($s === false) return ''; return preg_replace('/^\xEF\xBB\xBF/', '', $s); }
function keyNorm($s){ return strtolower(trim($s)); }
function patchCompat($sql){
  // Replace GENERATED ALWAYS AS ... STORED (PG95) -> keep just the column definition before GENERATED
  $sql = preg_replace('/(\bnumeric\(\d+,\d+\)\s+)GENERATED\s+ALWAYS\s+AS\s*\([^\)]*\)\s+STORED/i','${1}', $sql);
  return $sql;
}
function extractBlocks($sql){
  $blocks=[]; $buf=''; $inDo=false; $len=strlen($sql);
  for($i=0;$i<$len;$i++){
    $chunk = substr($sql,$i,2);
    if (!$inDo && preg_match('/^do\s*\$\$/i', substr($sql,$i,6))) { $inDo=true; }
    $ch = $sql[$i];
    $buf.=$ch;
    if ($inDo && $ch===';' && preg_match('/\$\$\s*;\s*$/s', substr($buf,-5))){ $blocks[]=trim($buf); $buf=''; $inDo=false; }
    elseif(!$inDo && $ch===';'){ $blocks[]=trim($buf); $buf=''; }
  }
  if (trim($buf)!=='') $blocks[]=trim($buf);
  return $blocks;
}
function detectObject($blk){
  $b = strtolower($blk);
  if (preg_match('/^\s*create\s+schema\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\."\\]+)/i',$blk,$m)) return ['schema', trim($m[1],'"')];
  if (preg_match('/^\s*create\s+type\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\."\\]+)/i',$blk,$m)) return ['type', trim($m[1],'"')];
  if (preg_match('/^\s*create\s+(?:temporary\s+|unlogged\s+)?table\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\."\\]+)/i',$blk,$m)) return ['table', trim($m[1],'"')];
  if (preg_match('/^\s*alter\s+table\s+([a-z0-9_\."\\]+)\s+add\s+constraint\s+([a-z0-9_\."\\]+)/i',$blk,$m)) return ['constraint', trim($m[1],'"').'::'.trim($m[2],'"')];
  if (preg_match('/^\s*create\s+(?:unique\s+)?index\s+(?:concurrently\s+)?(?:if\s+not\s+exists\s+)?([a-z0-9_\."\\]+)\s+on\s+([a-z0-9_\."\\]+)/i',$blk,$m)) return ['index', trim($m[1],'"').'::'.trim($m[2],'"')];
  if (preg_match('/^\s*create\s+view\s+([a-z0-9_\."\\]+)\s+as/i',$blk,$m)) return ['view', trim($m[1],'"')];
  if (preg_match('/^\s*create\s+function\s+([a-z0-9_\."\\]+)\s*\(/i',$blk,$m)) return ['function', trim($m[1],'"')];
  if (preg_match('/^\s*create\s+trigger\s+([a-z0-9_\."\\]+)\s+.*?\s+on\s+([a-z0-9_\."\\]+)/is',$blk,$m)) return ['trigger', trim($m[1],'"').'@'.trim($m[2],'"')];
  if (preg_match('/^\s*do\s*\$\$/i',$b)) return ['do', 'do$$'];
  if (preg_match('/^\s*insert\s+/i',$b)) return ['dml','insert'];
  if (preg_match('/^\s*update\s+/i',$b)) return ['dml','update'];
  if (preg_match('/^\s*delete\s+/i',$b)) return ['dml','delete'];
  return [null,null];
}

$baseCandidates = [
  '000.  SISTEMA SELEMTI - ESQUEMA COMPLETO DE BASE DE DATOS- OK.sql',
  '000. deploy_selemti_full.sql',
  'selemti_deploy_inventarios_PG95_CONSOLIDADO_FINAL.sql'
];
$base = null; foreach($baseCandidates as $bn){ $fp = "$bd/$bn"; if (is_file($fp)) { $base=$fp; break; } }
if (!$base) { fwrite(STDERR, "Base file not found\n"); exit(2); }
$all = glob($bd.'/*.sql');
$others = array_values(array_filter($all, function($f) use ($base){ return realpath($f) !== realpath($base); }));
sort($others, SORT_NATURAL|SORT_FLAG_CASE);

$seen = [ 'schema'=>[], 'type'=>[], 'table'=>[], 'constraint'=>[], 'index'=>[], 'view'=>[], 'function'=>[], 'trigger'=>[] ];
$dups = [];
function reg(&$seen,&$dups,$kind,$name){ $k=keyNorm($name); if (!$kind) return true; if(isset($seen[$kind][$k])){ $dups[$kind][]=$name; return false; } $seen[$kind][$k]=true; return true; }

$stages = [ 'schema'=>[], 'type'=>[], 'table'=>[], 'constraint'=>[], 'index'=>[], 'view'=>[], 'function'=>[], 'trigger'=>[], 'do'=>[], 'dml'=>[], 'misc'=>[] ];

function pushBlock(&$stages,$kind,$blk){ if(isset($stages[$kind])) $stages[$kind][]= $blk; else $stages['misc'][]=$blk; }

function feedFile($file, &$stages, &$seen, &$dups){ $raw = readFileUtf8($file); $raw = patchCompat($raw); $blocks = extractBlocks($raw); foreach($blocks as $blk){ if ($blk==='') continue; list($kind,$obj)=detectObject($blk); if($kind && !reg($seen,$dups,$kind,$obj)) continue; pushBlock($stages,$kind?:'misc',$blk); } }

// Pass 1: base
feedFile($base, $stages, $seen, $dups);
// Pass 2: others
foreach($others as $f){ feedFile($f, $stages, $seen, $dups); }

// Write output ordered stages
$header = [];
$header[] = '-- CONSOLIDATED OUTPUT V3 (ordered)';
$header[] = '-- Generated: '.date('c');
$header[] = 'SET client_min_messages TO warning;';
$header[] = 'SET search_path TO selemti, public;';
$header[] = "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'selemti') THEN EXECUTE 'CREATE SCHEMA selemti'; END IF; END $$;";
file_put_contents($out, implode("\n", $header)."\n\n");

$order = ['schema','type','table','constraint','index','view','function','trigger','do','dml','misc'];
foreach($order as $k){ if (empty($stages[$k])) continue; file_put_contents($out, "\n-- ==== $k ====\n", FILE_APPEND); foreach($stages[$k] as $blk){ file_put_contents($out, $blk."\n", FILE_APPEND); } }

// Add subtotal triggers again (ensure present)
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
$rm[] = '# Consolidation Report V3';
$rm[] = '- Base: '.basename($base);
$rm[] = '- Output: '.basename($out);
$rm[] = '## Objects added (counts)';
foreach($seen as $k=>$v){ $rm[] = "- $k: ".count($v); }
$rm[] = '## Duplicates skipped (samples)';
foreach($dups as $k=>$arr){ $rm[] = "- $k: ".count($arr); if ($arr) $rm[] = '  - '.implode(", ", array_slice(array_unique($arr),0,10)); }
file_put_contents($report, implode("\n", $rm));

echo "OK\n$out\n$report\n";
