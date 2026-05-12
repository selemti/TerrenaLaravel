# Modelo de Negocio y Gobierno (TerrenaLaravel)
**Vigencia:** Abril 2026

## 1. Introducción

El presente documento constituye el mapa integral y verificable del ERP TerrenaLaravel. Su objetivo es articular cómo interactúan realmente las reglas contables, operativas y de control a lo largo de las distintas capas del sistema, describiendo su comportamiento operativo y estructural tal como existe actualmente en producción.

A diferencia de documentos de arquitectura o planeación, este modelo no representa un diseño futuro ni una propuesta de mejora. Tampoco redefine reglas de negocio. Todo su contenido está construido exclusivamente a partir de evidencia empírica obtenida del código fuente activo, el esquema de base de datos (PostgreSQL), las rutas del sistema y la documentación consolidada, eliminando cualquier nivel de especulación.

El alcance del documento cubre la totalidad del ecosistema ERP detectado. No se limita a los módulos transaccionales (Caja, Inventario, Compras, Recetas, Producción, Transferencias), sino que incorpora formalmente las capas transversales que gobiernan el sistema: Seguridad (roles y permisos), Auditoría inmutable, gestión de fondos (Caja Chica) y procesos automatizados (Batch Jobs).

Este documento funge como referencia canónica para entender el estado real del sistema y servirá como base para futuras decisiones de evolución, auditoría y control.

---

## 2. Mapa Integral del ERP TerrenaLaravel

El sistema no opera como un monolito plano. Funciona mediante un ecosistema jerárquico donde los procesos transaccionales están supeditados a una infraestructura de control transversal, sustentando desde la seguridad hasta la viabilidad financiera. Este ecosistema se estratifica en capas fundamentales, integrando tanto los módulos visibles como los andamiajes arquitectónicos ocultos.

### Capa 0: Infraestructura, Gobierno y Seguridad (Núcleo Transversal)
Esta capa define el marco de control del sistema, aunque en la práctica existen implementaciones que pueden operar parcialmente fuera de ella (por ejemplo, inserciones directas en base de datos o lógica sin middleware).
- **Roles, Permisos y Autenticación (Spatie / Sanctum):** Escudo paramétrico que restringe el acceso de usuarios a módulos y acciones. Define estrictamente la identidad.
- **Auditoría Inmutable (Logs Centrales):** Cadena de custodia silenciosa. Registra a nivel de PostgreSQL Puro (`selemti.audit_log`) alteraciones drásticas como borrados, cancelaciones o re-procesos.
- **Procesamiento Asíncrono y Recálculos (Batch Jobs):** Motor de procesamiento asíncrono del ERP. Dispara rutinas durante la madrugada que evalúan mermas retrasadas, consolidan pérdidas puras (`PerdidaLog`) y alivianan la carga de cálculo de inventarios.
- **Parametría Base:** Las reglas de negocio subyacentes, dictaminadas de forma global (Porcentajes de merma permitida, tolerancias, factorías UOM).

### Capa 1: Flujos Financieros y Control de Efectivo
Los módulos responsables de inyectar rigor matemático a los recursos líquidos de la empresa, evitando diferencias y fugas.
- **Caja Operativa (Postcorte):** El árbitro mayor. Cruza lo que las cajas registradoras (Terminales/POS) reportan contra el conteo físico humano, calculando el faltante o sobrante con precisión.
- **Fondo de Caja Chica (Liquidez Descentralizada):** Flujo de erogaciones menudas con vida propia. Absorbe comprobantes, retiros y gastos. Al liquidarse, impacta por deducción el comportamiento del arqueo en Capa 1.
- **Workflow de Aprobaciones:** Semáforo financiero; detiene la viabilidad de un retiro de cuenta o desembolso hasta que existe un *sello de autorización* gerencial, previniendo el fraude por autogestión.

### Capa 1.5: Integración Transaccional (POS_SYNC)
Esta capa actúa como el puente entre el sistema POS (Floreant) y el ERP. Es responsable de sincronizar eventos de venta, pagos y estados operativos hacia el sistema central.
- **POS_SYNC (Floreant Integration):** Canal de entrada de transacciones reales. Introduce tickets, pagos y eventos operativos que impactan simultáneamente caja e inventario.
- **Dependencia temporal:** La consistencia del sistema depende de la alineación de timestamps entre POS y backend.
- **Riesgos asociados:** Desfase de horarios, duplicidad de eventos y fragmentación de descuentos (BUG-04).

### Capa 2: Cadena de Suministro y Valor Logístico (Supply Chain)
El engranaje físico del ERP. Controla el flujo completo de los insumos y productos, desde su compra administrativa hasta su consumo en operación.
- **Compras y Pronósticos (Replenishment):** Motor que convierte alertas históricas en órdenes de requerimiento comercial, inyectando la mercadería al ecosistema en firme.
- **Inventario Maestro (Kardex):** Base del motor de costos (WAC). Mantiene la partida doble ininterrumpida por cada movimiento y locación.
- **Auditorías Físicas (Counts):** Antígeno contra robos. Fuerzan comparativas ciego vs teórico. Esta intervención quirúrgica somete o ajusta la masa contable de la locación y debe ser fiscalizada de cerca.
- **Transferencias (Traspasos):** Movilidad intra-almacenes, fundamentada en rutas demoradas (*Ship / Receive*), con un control intrínseco sobre el "Inventario en Tránsito / Tránsito-Loss".
- **Ingeniería de Menú (RECETAS) y Costeo:** Ponderación y transformación de insumos (BOM) en productos vendibles o intermedios, calculando recursivamente la rentabilidad.
- **Producción Interna:** Transformación en lote. Fabrica sub-ítems aplicando mermas declaradas en su propio taller.
- **Consumo POS (Ticket Intercept):** Deducción algorítmica constante de las recetas en línea, mermando el stock teórico frente a cada platillo marcado en las cajas (*FloreantSync*).

### Capa 3: Inteligencia y Explotación Analítica (Nivel Directivo)
La capa de cosecha consultiva.
- **Diagnóstico y Reportes Gerenciales:** Motor de consolidación (`Dashboards`) que proyecta el valor en bloque de los almacenes, el de las ventas, comanda ratios ("Food Cost") o diagnostica ticket promedio, guiando la toma pura de decisiones de la directiva o contabilidad externa.
- **Dependencia crítica:** Esta capa depende completamente de la consistencia de las capas inferiores. Cualquier desviación en inventario, descuentos o caja impacta directamente la veracidad de los indicadores.

---

## 3. Modelo Financiero (Flujos y Arqueos)

El control de liquidez local se estructura en un modelo dual, segregando terminantemente los ingresos provenientes de la venta directa (Caja Operativa) de los fondos destinados al gasto interno (Caja Chica). En el ecosistema TerrenaLaravel no existe una única "Caja Universal", sino canales paralelos que eventualmente interactúan bajo regulaciones restrictivas.

### 3.1. Dualidad del Efectivo (Dicotomía de Flujo)
- **Caja Operativa (Cajón de Terminal):** Es el punto de consolidación de los flujos financieros provenientes del POS, incluyendo ventas, cancelaciones y ajustes operativos. Su objetivo funcional es validar que el efectivo físico coincida con lo registrado en el sistema al cierre del turno.
- **Caja Chica (CashFund):** Es un fondo de liquidez independiente utilizado para gastos operativos. Funciona bajo un flujo de aprobación y comprobación, sin integrarse automáticamente a la Caja Operativa.
- **Desacoplamiento estructural:** Ambos flujos operan de forma independiente, lo que introduce la necesidad de mecanismos explícitos de conciliación para evitar inconsistencias financieras.

### 3.2. Ciclo de Conciliación y Postcorte
El postcorte es la entidad matemática definitiva diseñada para resolver la colisión entre el mundo físico y el sistema POS. 
- **Responsabilidad financiera:** El Postcorte define formalmente la responsabilidad del operador sobre el efectivo durante su turno.
- **Verificación vs Realidad:** Su principal función es comparar y sentenciar la validación entre la declaración inicial de saldo del operador (precorte) contra la inyección transaccional real que cruzó el sistema.
- **Vulnerabilidad a Reglas de Ventana:** Se rige severamente por cortes temporales en consultas raw dentro de PostgreSQL, sufriendo un margen ciego u orfandad ante tickets que se liquidan instantes después del corte horario físico.

### 3.3. Desalineación entre flujos de efectivo (Caja vs Caja Chica)
El principal riesgo de gobernanza financiera surge cuando los flujos de Caja Operativa y Caja Chica se cruzan sin trazabilidad explícita.
- **Caso típico:** Un gasto autorizado en Caja Chica es cubierto físicamente con efectivo del cajón operativo.
- **Efecto:** Se genera un faltante en el arqueo del Postcorte que no corresponde a un error de operación del cajero, sino a una desviación de flujo no registrada correctamente.
- **Ausencia de conciliación automática:** El sistema no integra de forma nativa estos movimientos, lo que obliga a interpretación manual o procesos adicionales para justificar diferencias.

Este punto representa la principal superficie de riesgo para errores operativos y potencial fraude si no se gestiona correctamente.

---

## 4. Modelo Logístico y Cadena de Valor

El modelo logístico gobierna el ciclo de vida del inventario, dictando cómo la materia prima se abastece, se transforma y se desgasta hasta su venta o pérdida. Cada evento en este trayecto afecta directamente la pureza del costo financiero del negocio, rigiéndose por la tensión constante entre el stock teórico (calculable) y el stock real (tangible).

### 4.1. Kardex y Formación del Costo (WAC)
El Kardex es la fuente de verdad y el motor de valuación en la cadena de suministro.
- **Fuente de Verdad:** Mantiene el registro centralizado ininterrumpido a doble partida de toda entrada y salida de mercancía (`movimientos_inventario`).
- **Formación de Valor (WAC):** El costo unitario no es estático ni subjetivo. Se forma y recalcula en tiempo real mediante el Costo Promedio Ponderado Acumulado (WAC). Cada ingreso físico (Recepción de Compras) re-pondera inmediatamente el esquema contable histórico subyacente.

### 4.2. Consumo POS (Deducción Teórica)
Mecanismo operativo de ventas que transfiere bienes tangibles a registros financieros consumados.
- **Implosión de Recetas (BOM):** Un ticket despachado dispara inyecciones algorítmicas que deducen abstractamente porciones basándose estrictamente en lo estipulado por la ingeniería del producto.
- **Acumulación de Stock Teórico:** La sustracción inmediata se ejecuta sin refrendo o validación de los miligramos servidos auténticamente por cocina. Aísla temporalmente la verdad del Kardex asumiendo un escenario perfecto, creando un inventario "ideal" al corto plazo.

### 4.3. Producción Interna (Transformación)
Fabricación subyacente (Batching / Preparaciones) que consolida valor dentro del mismo almacén.
- **Herencia de WAC:** Extraer materia prima básica (harina, vegetales) para fabricar un sub-produto (salsa) no desaparece el saldo, sino que endosa equitativamente los márgenes de compra previos (WAC orígen) transfiriéndolos al nuevo ítem consolidado en Kardex.
- **Efecto de Merma en Planta:** Si durante la fabricación se registra que se necesitó material extra de lo dictado por lista por defectos operativos, dicho sobrecosto es absorbido implacablemente ensanchando (encareciendo) el WAC final del producto intermedio resultante.

### 4.4. Auditorías Físicas (Inventory Counts)
Intervención correctora humana diseñada para someter el stock teórico del sistema a la evidencia física.
- **Contraste de Realidad:** La acción empírica que blanquea el diferendo existente entre el conteo ciego de un operario y el rezago numérico estimado por el POS en la base de datos.
- **Alteración Retroactiva del Costo (Riesgo):** Las discrepancias severas forzadas por cuadres de inventario dictaminan ajustes netos inyectables al Kardex. Al compensar mercancía inexistente bajo el pretexto de un ajuste, el sistema suprime los montos al valor WAC corriente, contaminando y encubriendo las mediciones de rentabilidad pura (Food Cost).

### 4.5. Mermas (Explícitas e Implícitas)
El desgaste estructural en la cadena de rentabilidad asimilado bajo dos variables de control.
- **Merma Explícita (Documentada):** Dispersión registrada de inmediato por operación humana (Ej. daño, pérdida accidental probada). Detona una deducción del Kardex estampada de motivo, transparentando exactamente cuándo y por qué la inversión liquidó su estatus.
- **Merma Implícita (La Fuga Silenciosa):** Subproducto letal emanado durante los *Inventory Counts*. Refleja todos los ingredientes extra robados o sobre-porcionados que el POS jamás cobró y operación jamás documentó. Su corrección diferida diluye el diferencial como una pérdida de utilidad inexplicable a fin de mes.

---

## 5. Reglas de Gobierno e Intervención

Este apartado establece la normativa estricta para la modificación, mantenimiento y escalamiento técnico del ERP TerrenaLaravel, fundamentada en su arquitectura actual y las vulnerabilidades detectadas.

### 5.1. Principios Arquitectónicos
- **Fuente de Verdad Mixta:** La persistencia y agregación matemática (Kardex, partidas dobles, postcorte) debe calcularse preferentemente en PostgreSQL (Vistas/Funciones/Triggers). Laravel rige exclusivamente la serialización, el enrutado, el control de acceso y el ciclo de vida de las entidades, delegando la contabilidad dura y consolidaciones a la BD.
- **Inmutabilidad Transaccional:** Los registros del Kardex (`movimientos_inventario`) y los logs financieros no pueden modificarse post-inserción mediante el ORM (prohibido `Update`/`Save` sobre existencias finales). Cualquier corrección exige una operación de reversión explícita o un movimiento de inventario compensatorio.

### 5.2. Reglas de Modificación en Base de Datos (PostgreSQL)
- **Bloqueo a Parches DDL Locales:** Queda estrictamente prohibido alterar tablas transaccionales (Ej. `postcorte` o `ticket`) con columnas analíticas locales si estas no han sido homologadas y ratificadas primeramente en el esquema maestro productivo en servidor físico.
- **Mantenimiento Limpio en Rutinas PL/pgSQL:** Las lógicas pesadas contenidas en `fn_generar_postcorte` o el `trg_ticket_inventory_consumption` no deben ser emuladas, re-calculadas ni mitigadas con parches `WHERE` en capa PHP (Livewire/Controllers). Si la regla falla en PRD, la refactorización ocurre dentro del script de la función original SQL.

### 5.3. Reglas de Laravel (Controllers y Services)
- **Anti-duplicación (Service Pattern):** Si una regla de negocio interactúa con modelos cruzados (ej. aprovisionar Traspasos, recibir Compras), la validación operativa debe aislarse en una clase `Service` (Ej. `TransferService`). No debe hospedarse directamente en los métodos de API ni en los controladores Livewire subyacentes.
- **Ruteo Declarativo:** El sistema de `routes/api.php` y `web.php` no debe contener resoluciones abstractas, `DB::table()`, ni validaciones `if/else` inyectadas mediante `Closure` (funciones anónimas). El enrutador delega, no procesa.

### 5.4. Anti-Patrones Detectados (Prácticas Restringidas)
- **Tricotomía MVC:** Evitar la coexistencia simultánea de controladores UI y Controladores REST API compitiendo por gobernar el mismo módulo (Ej. `TransferController` vs `TransferApiController`) replicando validaciones divergentes de negocio. Consolidar siempre bajo un Servicio único subyacente.
- **Spanglish Dominal:** Prohibido escalar módulos arrastrando herencias lingüísticas mixtas profundas (ej. `RecipeCostController` atado a una ruta `/recipes` operando el modelo `App\Models\Rec\Receta` que inyecta en `receta_detalle`). Debe existir un consenso único idiomático por cada nuevo módulo creado.
- **Validaciones de Autoridad Aisladas:** Utilización esporádica de lógicas manuales de autorización *ad-hoc* (como ocurre en las firmas `CashFund`) en vez de recargarse integralmente en Spatie `Policies` y Gates autorizadas de Middleware.

### 5.5. Riesgos Críticos Identificados
- **El Desfase de Timestamps (POS_SYNC):** El Postcorte local asume una ventana estricta con el reloj. Retrasos, latencias o reprocesos en la inyección de tickets por el POS generan orfandad inter-turnos e impactan severamente balances de horas pasadas. 
- **La Fragmentación BUG-04:** La contabilidad arrastra múltiples fuentes simultáneas e incompletas sobre el campo de descuentos de Floreant POS. Ningún desarrollador configurando Módulos de Análisis o Reportes debe crear lógicas deductivas nuevas basadas en estas columnas fantasmas sin remitirse al total transaccional neto reportado estricto.

### 5.6. Reglas de Auditoría y Trazabilidad
- **Preservación Obligatoria del `AuditLog`:** La matriz de custodia actual registra eventos críticos insertando instrucciones SQL en bruto (`DB::insert`) directamente hacia `selemti.audit_log`, a espaldas de Eloquent. Toda refactorización a los controladores involucrados en fondos, anulación de tickets o suspensiones, está obligada técnicamente a preservar dicho segmento ciego de código bajo pena de destruir inadvertidamente la cadena de custodia.
- **Gobernanza de Rutas:** Ningún `Endpoint` ni formulario Livewire nuevo que altere registros debe exponerse masivamente. Todo método destructivo exige ser amparado por los middlewares de Identidad y validación de `Spatie Roles & Permissions` dictando autoridad manifiesta.

---

## 6. Matriz de Decisión y Control Operativo

Esta matriz es el manual de ejecución definitivo. Dictamina **cuándo** y **dónde** se debe intervenir el código ante una falla o evolución funcional, eliminando las decisiones arquitectónicas improvisadas.

### 6.1. Tipos de Intervención por Dominio
- **Tipo A (Capa de Presentación / UI):** Se ejecuta exclusivamente en componentes `Livewire` y vistas `Blade`. Abarca experiencia de usuario, control de validaciones de captura rápida y renders visuales.
- **Tipo B (Capa de Orquestación / Services):** Se ejecuta en clases `Service` de Laravel (`app/Services/*`). Rige flujos de transición de estados (Ej. *Draft → Aprobado*), enrutamiento interno de modelos cruzados y validación cruzada.
- **Tipo C (Persistencia y Precisión Matemática / PostgreSQL):** Se ejecuta exclusivamente en la base de datos (Vistas, Funciones, Triggers). Sostiene cualquier agregación de saldos, cálculo de WAC, cierres temporales de turno y arqueos totales.
- **Tipo D (Capa de Integración POS):** Abarca `POS_SYNC` y los comandos de consola pasivos. Interviene al importar crudos de ventas y sincronizar tiempos remotos.

### 6.2. Reglas de Enrutamiento de Problemas (¿Dónde Reparar?)
- Si el problema es un **error de cálculo financiero, descuadre de rentabilidad o costo de inventario**: La reparación pertenece obligatoriamente a la **Tipo C (PostgreSQL)**.
- Si el problema es un **retraso en el estado del flujo humano o requerimientos de pantallas rotas**: La reparación se delega a la **Tipo B (Laravel Services)** o **Tipo A (UI)**.
- Si el problema expone **inconsistencia de datos pre-existentes frente al cobro físico**: La validación exige auditar el origen asíncrono frente al destino usando la **Tipo D (Integración POS)**.

### 6.3. Semáforo de Riesgo Químico (Niveles de Impacto)
- 🟢 **Riesgo Bajo (UI / Livewire):** Errores localizados. Un fallo transitorio degrada la percepción, pero no corrompe la bóveda financiera estricta (Postgres rechazará ilegalides lógicas desde atrás).
- 🟡 **Riesgo Medio (Laravel Services):** Un re-enrutamiento deficiente que puede estancar transacciones en estatus intermedios ("Zombie") (Ej. retirar presupuesto de Caja Chica atrapándolo permanentemente *En_Revisión*) deteniendo el ritmo corporativo.
- 🔴 **Riesgo Alto (SQL / Kardex / Postcorte / AuditLog):** Un fallo de escrutinio retrospectivo o lógico altera la pureza del balance contable mensual, inyecta mermas falsas y puede suprimir silenciosamente la trazabilidad sobre cobros expuestos.

### 6.4. Prohibiciones Absolutas (Golden Rules)
Cualquier Pull Request, refactor, o aportación humana/IA será irremediablemente rechazada si incurre en:
1. **NO Recalcular Aritmética Creada:** Jamás procesar un cálculo financiero complejo en colecciones de Laravel si dicho cruce de saldos ya ha sido proveído (o debería proveerse nativamente) en un agregador de PostgreSQL.
2. **NO Duplicar Responsabilidades MVC:** Ninguna validación de negocio puede sobrevivir aislada ni convivir polarizada entre dos Contadores diferentes. Abstractar forzosamente a un único `Service` responsable.
3. **NO Inferir Descuentos Huérfanos (BUG-04):** Estrictamente prohibido formular conjeturas intentando cuadrar localmente el porcentaje o causal de un descuento del POS sobre columnas desalineadas (*phanthon columns*). Atenderse únicamente a netos transaccionales absolutos.
4. **NO Atacar el Kardex Directamente:** Queda permanentemente prohibido sobre-escribir saldos vivos de unidades mediante actualizaciones crudas (`UPDATE`). Toda corrección de inventario post-consumo exige su obligado movimiento de sistema constructivo contra-partida a justificar (Merma / Ajuste / Devolución).
