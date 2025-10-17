<?php
$bd = __DIR__ . '/../BD';
$export = 'D:/Tavo/2025/UX/BD/Octubre/Local_Recetas_17_10_2025.sql';
if (!is_file($export)) { fwrite(STDERR, "Export not found: $export\n"); exit(1); }
$glob = glob($bd.'/DEPLOY_CONSOLIDADO_FULL_PG95-v3-*.sql');
if (!$glob) { fwrite(STDERR, "Consolidated v3 not found in $bd\n"); exit(2); }
usort($glob, function($a,$b){ return filemtime($b)-filemtime($a); });
$conso = $glob[0];

function readUtf8($f){ $s = @file_get_contents($f); if ($s===false) return ''; return preg_replace('/^\xEF\xBB\xBF/', '', $s); }
function splitBlocks($sql){
  $blocks=[]; $buf=''; $inDo=false; $len=strlen($sql);
  for($i=0;$i<$len;$i++){
    if (!$inDo && preg_match('/^do\s*\$\$/i', substr($sql,$i,6))) $inDo=true;
    $ch=$sql[$i]; $buf.=$ch;
    if ($inDo && $ch===';' && preg_match('/\$\$\s*;\s*$/s', substr($buf,-5))) { $blocks[]=trim($buf); $buf=''; $inDo=false; }
    elseif(!$inDo && $ch===';'){ $blocks[]=trim($buf); $buf=''; }
  }
  if (trim($buf)!=='') $blocks[]=trim($buf);
  return $blocks;
}
function detect($blk){
  if (preg_match('/^\s*create\s+schema\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)/i',$blk,$m)) return ['schema', strtolower(trim($m[1],'"'))];
  if (preg_match('/^\s*create\s+type\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)/i',$blk,$m)) return ['type', strtolower(trim($m[1],'"'))];
  if (preg_match('/^\s*create\s+(?:temporary\s+|unlogged\s+)?table\s+(?:if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)/i',$blk,$m)) return ['table', strtolower(trim($m[1],'"'))];
  if (preg_match('/^\s*alter\s+table\s+([a-z0-9_\.\"]+)\s+add\s+constraint\s+([a-z0-9_\.\"]+)/i',$blk,$m)) return ['constraint', strtolower(trim($m[1],'"')).'::'.strtolower(trim($m[2],'"'))];
  if (preg_match('/^\s*create\s+(?:unique\s+)?index\s+(?:concurrently\s+)?(?:if\s+not\s+exists\s+)?([a-z0-9_\.\"]+)\s+on\s+([a-z0-9_\.\"]+)/i',$blk,$m)) return ['index', strtolower(trim($m[1],'"')).'::'.strtolower(trim($m[2],'"'))];
  if (preg_match('/^\s*create\s+view\s+([a-z0-9_\.\"]+)\s+as/i',$blk,$m)) return ['view', strtolower(trim($m[1],'"'))];
  if (preg_match('/^\s*create\s+function\s+([a-z0-9_\.\"]+)\s*\(/i',$blk,$m)) return ['function', strtolower(trim($m[1],'"'))];
  if (preg_match('/^\s*create\s+trigger\s+([a-z0-9_\.\"]+)\s+.*?\s+on\s+([a-z0-9_\.\"]+)/is',$blk,$m)) return ['trigger', strtolower(trim($m[1],'"')).'@'.strtolower(trim($m[2],'"'))];
  return [null,null];
}
function catalog($file){ $sql=readUtf8($file); $blocks=splitBlocks($sql); $cat=[ 'schema'=>[], 'type'=>[], 'table'=>[], 'constraint'=>[], 'index'=>[], 'view'=>[], 'function'=>[], 'trigger'=>[] ]; foreach($blocks as $b){ list($k,$n)=detect($b); if($k&&$n){ $cat[$k][$n]=true; } } return $cat; }

$catExport = catalog($export);
$catConso  = catalog($conso);
$kinds = array_keys($catExport);
$miss = [];
foreach($kinds as $k){ $miss[$k] = array_diff(array_keys($catExport[$k]), array_keys($catConso[$k])); }
$extra = [];
foreach($kinds as $k){ $extra[$k] = array_diff(array_keys($catConso[$k]), array_keys($catExport[$k])); }

$rep=[]; $rep[] = '# Compare Export vs Consolidado v3';
$rep[] = '- Export: '.$export; $rep[]='- Consolidado: '.$conso; $rep[]='';
foreach($kinds as $k){ $rep[] = "## $k"; $a=$miss[$k]; if($a){ $rep[] = '- En export pero NO en consolidado:'; $rep[] = '  - '.implode("\n  - ", array_slice($a,0,100)); } else { $rep[]='- Sin diferencias a favor del export.'; }
  $b=$extra[$k]; if($b){ $rep[] = '- En consolidado pero NO en export (ok si son nuevos):'; $rep[]='  - '.implode("\n  - ", array_slice($b,0,100)); } else { $rep[]='- Sin diferencias a favor del consolidado.'; }
}
$repFile = $bd.'/COMPARE_EXPORT_vs_CONSOLIDADO-'.date("Ymd-His").'.md'; file_put_contents($repFile, implode("\n", $rep));

echo "OK\n$repFile\n";

