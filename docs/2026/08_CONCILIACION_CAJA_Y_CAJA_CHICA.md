# Conciliación Caja y Caja Chica (AS-IS)
**Vigencia:** Abril 2026

## 1. Definición del Problema
En la arquitectura financiera del ERP TerrenaLaravel coexisten dos canales paralelos de liquidez que no logran una integración algorítmica automatizada y segura. Por un lado, la **Caja Operativa** (ingresos netos de Terminal POS) y por otro la **Caja Chica / CashFund** (gastos y retiros inyectados administrativamente). 

El problema raíz radica en el desacoplamiento estructural: cuando un gasto operativo de urgencia es gestionado en el módulo de *CashFund*, a menudo los fondos físicos se sustraen materialmente de la *Caja Operativa* (del cajón), pero el sistema carece de un mecanismo bidireccional asíncrono que justifique o inyecte esta deducción en el arqueo inmutable del cierre de turno. Esto obliga al sistema a reportar **faltantes conforme al modelo contable actual**, aunque operativamente esos faltantes puedan corresponder a una salida legítima no conciliada.

---

## 2. Flujo actual de Caja Operativa
- **Origen:** Exclusivo de los ingresos reportados por la facturación (POS_SYNC) hacia las tablas `public.ticket` y `public.transactions`.
- **Estructura Transaccional:** El ciclo de vida está ceñido estrictamente a las ventanas de turno y gobernado en capa relacional por `selemti.fn_generar_postcorte`.
- **Mecanismo de Cierre (Postcorte):** Sentencia la validación matemática contrastando implacablemente el saldo declarado a ciegas por el cajero (Precorte) contra el flujo que cruzó el sistema.
- **Evidencia Física:** El dinero efectivo depositado contablemente debe existir moneda a moneda de manera física en las gavetas.

---

## 3. Flujo actual de Caja Chica
- **Origen:** Flujo nominal descendente inyectado operativamente bajo autoridad y gestionado por vistas Livewire (`CashFund`). Se compone de ingresos puente (fondeo) y deducciones explícitas.
- **Disonancia Temporal (Livewire Workflow):** Imita rutinas burocráticas humanas con estados aislados. Un retiro inicia en estado de creación (`Draft`), requiere cargar evidencias físicas (`Receipts`), y transita hasta congelarse (`En_Revisión`) esperando autorización mediante firma gerencial. 
- **Cierre (Arqueos CashFund):** Ejecuta su propia sumatoria (`caja_fondo_arqueo`), evaluando si los vales emitidos, los retiros y el remanente inyectado concuerdan de forma contenida en su propio submódulo.

---

## 4. Punto exacto de desacoplamiento
Las colisiones estallan sistemáticamente al interponer "el dinero trazado vs el dinero real en gaveta".
1. **La Fricción Material:** El dinero asignado a la "Caja Chica" a nivel local rara vez habita una bóveda física apartada. Operación toma los billetes reales de la *Caja Operativa* para pagarle al albañil o al flete el gasto documentado de *Caja Chica*.
2. **Ceguera Algorítmica (BD):** La función de Postcorte es impermeable. No reconoce orgánicamente que el cajero extrajo los $500 faltantes debido a un "Débito Autorizado" documentado y sellado en el modelo paralelo `CashFund`.
3. **Consolidación Humana:** La integración entre ambos cajones descansa trágicamente en el juicio y memoria fotográfica del auditor, quien debe repasar visualmente el Faltante del Turno de Ventas frente a la Autorización asíncrona de Livewire para justificar que "el dinero no fue robado, se usó en el foco roto".

---

## 5. Riesgos operativos y de fraude
1. **Faltantes Simulados Constantes:** Extraer efectivo para propósitos operativos y ser penalizado formalmente en hoja tabular debido al choque de ventanas temporales.
2. **Doble Deducción (Fraude de Reembolso):** Retirar dinero líquido de la caja operativa en vivo, y a posteriori reclamar una inyección formal de reembolso del fondo a Dirección desde el Dashboard de CashFund engañando auditoría.
3. **Incapacidad Fiscal Activa:** El estado `En_Revisión` inmoviliza crónicamente su afectación. Si un turno físico cierra durante dicho letargo gerencial de aprobación, el postcorte registrará inexorablemente un robo o faltante, alterando la psicología y confianza del cajero.

---

## 6. Evidencia en código y BD
- **Livewire Components (`app/Livewire/CashFund/*`):** Reflejan la burocracia documental. El código avanza estados alterando `status` sin desencadenar interfaces o `Events` que notifiquen al modelo de Turnos sobre el flujo monetario real.
- **Islas Relacionales:** Las tablas `selemti.caja_fondo`, `caja_fondo_mov` y `caja_fondo_arqueo` no poseen restricciones foráneas de impacto (`ON CASCADE/UPDATE`), ni Triggers fiscales que compensen el monto de `selemti.postcorte`.
- **El Vacío en PostgreSQL:** La función rectora `fn_generar_postcorte` no instruye variables ni lógicas condincionales para sumar depósitos extractivos o deducir rembolsos originados desde `caja_fondo_mov` interceptando IDs de cajeros o firmas.

---

## 7. Qué sí concilia hoy y qué no
- **SÍ CONCILIA (Flujos Encapsulados):**
  - El monto crudo transaccional proveniente del POS frente a la declaración ciega en el Postcorte (Bóveda A vs Bóveda A).
  - Los arqueos manuales de los comprobantes internos contra los saldos líquidos pre-inyectados al CashFund (Bóveda B vs Bóveda B).
- **NO CONCILIA (Flujos Cruzados):**
  - La evaporación de liquidez al realizar préstamos físicos de urgencia (Bóveda A ↔ Bóveda B).
  - El pago físico efectuado el Lunes Vs El vale burocrático firmado hasta el Viernes por la Gerencia.
  - El escrutinio y sanción final de todo el circulante líquido de la corporación bajo una macro vista de "Total en Riesgo" central.

---

## 8. Reglas de gobierno actuales
De cara a las prácticas estipuladas en `06_MODELO_NEGOCIO_Y_GOBIERNO.md`:
1. Las aritméticas sancionatorias dictaminadas por Postcorte y Caja_Fondo deben continuar operando en compartimentos asilados de PostgreSQL si no existe una tabla Pivote oficial dictada por la matriz DDL.
2. Está tácitamente prohibido crear validaciones *ad-hoc* en Controladores Laravel y manipular sumatorias transitorias en PHP inyectando deducciones de `CashFund` a reportes contables de ventas para "forzar saldos en verde".
3. Todo retiro del Cajón de facturación que no goce de su contra-partida contable en ingreso de Terminal, debe sentenciarse y pervivir estructuralmente como un Faltante Crudo, evitando maquillar los Postcortes con parches locales.

---

## 9. Delimitación del problema
Esta radiografía sella formalmente el abismo algorítmico entre ambos módulos, advirtiendo claramente las limitantes operativas para cualquier agente:
- **Ausencia de Gobernanza Conductual:** No se erradicará el problema decretando "políticas formativas" a piso, exigiéndole a los meseros que "sean ordenados poniendo una nota en el ticket Z". Es ingobernable.
- **Origen Estructural:** No representa un error ortográfico en el código, es un innegable vacío de diseño lógico fundacional. 
- La arquitectura nativa de `TerrenaLaravel` está bifurcada con dos propósitos excelentes por sí mismos: Uno para dominar el torrente ininterrumpido y agresivo de clientes, y otro para solventar la friccionalidad de gastos asíncronos y jerárquicos. Carecen de un puente unificador robusto (Core Central del Flujo de Efectivo).
