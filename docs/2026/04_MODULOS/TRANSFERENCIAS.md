# 📦 MÓDULO: Transferencias y Traspasos (Transfers)

> **Clasificación:** SOPORTE  
> **Estado:** Implementado (Con Severa Duplicidad Técnica)  
> **Última revisión:** Abril 2026  
> **Fuente principal de verdad:** Mixta (Laravel orquesta los 5 estados del flujo, PostgreSQL ejecuta la partida doble del inventario)

---

## 1. Misión Funcional
Administrar el movimiento físico de existencias valorizadas entre diferentes almacenes internos (traspasos), garantizando una cadena de custodia formal que rebaje inventario en el origen y lo sume en el destino de manera controlada y auditada.

## 2. Resumen Operativo Rápido
- **Endpoints principales:** `/transfers/*` (Web Livewire), `/api/transfers/*` y `/api/inventory/transfers/*` (API).
- **UI principal:** `App\Livewire\Transfers\*` (`Index`, `Create`, `TransferDetail`, `TransferDispatch`, `TransferReceive`)
- **Controller / Service central:** `TransferService` (Core). A nivel HTTP existe una **tricotomía ruteada:** `TransferController`, `TransferApiController`, y un tercer `Api\Inventory\TransferController`.
- **Fuente de verdad en PGSQL:** Tablas base `selemti.traspaso_cab` y `selemti.traspaso_det`.
- **Dependencia crítica:** INVENTARIO (Kardex) y UOM.
- **Pendiente prioritario:** Erradicar la duplicidad y orfandad de los tres Controladores REST que exponen el mismo servicio en dos URIs diferentes.

---

## 3. Flujo Funcional
El flujo se segmenta en estados que diferencian el poder local frente a la injerencia de Kardex:
`Borrador (Draft) → Aprobado (Approve) → Salida Física del Origen (Ship) → Inspección de Ingreso Mermado (Receive) → Afectación Definitiva en Kardex Destino (Post)`

- **Estado Implícito Crítico ("Inventario en Tránsito"):** Representa existencias que ya fueron descontadas de la visibilidad y stock local del origen, pero que aún no caen en potestad del destino. Este estado no vive como una tabla física o métrica estática, sino como la inercia logística o consecuencia del desfase obligado entre el *Ship* y el *Receive*.

## 4. Mapa Tecnológico Canónico
**Endpoints relacionados**
- **Web:** 
  - `/transfers`
  - `/transfers/create`
  - `/transfers/{id}/detail`
  - `/transfers/{id}/dispatch` 
  - `/transfers/{id}/receive`
- **API (Duplicada en Rutas):** 
  - RAMA A: `/api/transfers/*` (`create`, `approve`, `ship`, `receive`, `post`)
  - RAMA B: `/api/inventory/transfers/*` (`store`, `approve`, `ship`, `receive`, `post`)
- **Legacy:** N/A directo.

**Componentes Arquitectónicos Base**
- **Controllers:** 
  - `Http\Controllers\Inventory\TransferController`
  - `Http\Controllers\Api\Inventory\TransferApiController`
  - `Http\Controllers\Api\Inventory\TransferController`
- **Services:** `Services\Inventory\TransferService`
- **Livewire:** `Livewire\Transfers\*`
- **Models:** `Models\Inventory\TransferHeader`, `Models\Inventory\TransferLine`

## 5. Base de Datos Crítica
- **Tablas:** `selemti.traspaso_cab`, `selemti.traspaso_det`
- **Tablas Subordinadas:** `selemti.kardex_diario` o tablas de auditoria (`movimientos`) interceptadas por sus sub-sistemas de kardex.
- **Vistas Específicas Activas:** N/A

## 6. Contrato de Datos / Reglas Base de Datos
- **Origen de datos:** Bodega / Terminal local.
- **Destino de datos:** Tablas vectoriales de Movimientos en el módulo INVENTARIO.
- **Reglas críticas:** 
  - **Doble Impacto Diferido:** El despacho decrementa stock en origen e incrementa "en tránsito". La recepción final incrementa stock en destino. El sistema permite transferir productos elaborados (ej. Tortas) cuyo stock es gestionado por la lógica de conmutación del [Motor de Consumo (Doc 24)](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/24_MOTOR_DE_CONSUMO_RECURSIVO.md). A diferencia de Ajustes o Producción, la Transferencia tiene 2 transacciones separadas por el "Vuelo Logístico". Postear 'Ship' rebaja el almacén de salida. Postear 'Receive' sube el almacén de entrada. Un traspaso en el aire es inventario virtual flotante.
  - **UOM de Conversión:** Requiere asimetría pre-configurada (Puedes enviar 1 Caja en el almacén central, y el almacén foráneo debe desempacar la llegada y contar 24 Unidades).
  - **Traspaso de Elaborados:** El sistema permite transferir productos resultantes de una OP (ej. Tortas preparadas en cocina central). Estos se mueven bajo su propio ID de ítem y costo acumulado, afectando el inventario del destino como producto de venta final o semiterminado, sin necesidad de explotar sus ingredientes en el destino.

## 7. Fuente de Verdad Real (Mixta)
- **Lógica en Laravel:** Única dueña autoritaria del Workflow logístico. Orquesta todo el diagrama de estados, rechazos y autorizaciones. Valida mermas en tránsito (lo que salió vs lo que llegó). La integridad material recae aquí.
- **Lógica en PostgreSQL:** Actúa como el ejecutor final definitivo del impacto contable al Kardex, resguardando la pura persistencia. Sin embargo, PostgreSQL *no* audita las variables lógicas de transporte; por lo que el peso total y salud del recorrido recae completamente en la protección de Laravel.

## 8. Dependencias con Otros Módulos
- **Depende de:**
  - **INVENTARIO:** Para pre-validar saldo y aplicar el saldo final.
  - **UOM (Catalogs):** Factor indispensable para la paridad de la mensurabilidad entre el origen y el destino. Ver [Doc 21](file:///C:/xampp3/htdocs/TerrenaLaravel/docs/2026/21_CATALOGO_UOM_Y_CONVERSIONES.md).
  - **RECETAS / POS_SYNC:** Impacta indirectamente si el traspaso es de un producto final sincronizado del POS.
- **Impacta a:**
  - **INVENTARIO:** Partida doble (OUT Origen, IN Destino). Un traspaso debe honrar indefectiblemente el axioma de mantener la exactitud del valor total consolidado de la empresa (Lo que sale de uno es lo que entra a otro).
  - **COMPRAS (Indirecto):** Un traspaso no validado disfraza o infla los niveles críticos, provocando desabasto y engañando falsamente a los sugeridos de _Replenishment_.

## 9. Estado Real Desglosado
- **Nivel de Confianza Documental:** Medio - La lógica central fluye mediante Livewire y Service, pero la entropía de nombres de Controllers contamina el análisis inicial.
- **Implementado:** Sí. Modelado sobre el Framework de la Fase 2 en Livewire.
- **Operativo:** Totalmente activo bajo el esquema API/Livewire.
- **Histórico / Legacy:** Sin vínculos letales con el archivo histórico antiguo.

## 10. Problemas Conocidos / Bugs
- **Bug:** Colisión Masiva de Controladores API (Duplicidad Viva).
- **Causa:** Sub-equipos o IAs crearon e indexaron simultáneamente múltiples controladores bajo `routes/api.php` sin refinar responsabilidades:
  `TransferController` (Rama principal en `Inventory/...`)
  `TransferApiController` (Rama duplicada en `Api/Inventory/...`)
  `TransferController` (Otra rama en `Api/Inventory/...`)
- **Impacto:** Mantener un estado o parche requerirá reescribirlo en 3 lugares o descubrir tardíamente que el Frontend consume uno obsoleto.
- **Estado:** Reportado como Deuda Técnica Crítica.

## 11. Riesgos si se Modifica
**Validación UOM del Transit-Loss:** Si el mecanismo de calibrado del diferencial (lo que sale del origen vs lo que llega al foráneo) se altera sin precaución, organizará existencias fantasma (inventariadas por doble UOM) o mermas monetarias irrecuperables en el costeo globalizado.

**Riesgo de Doble Posteo:** Si las secuencias end-point de `"Receive"` o `"Post"` son invocadas repetidamente y/o simultáneamente sin los blindajes restrictuos transaccionales del backend (`DB::transaction` / *Race conditions lock*), la plataforma podría inyectar dobles y hasta triples dotaciones de saldo material al almacén destino sin rebajar el origen.

**Riesgo de Desalineación Temporal (Inventario Flotante Indefinido):** Si el estado de partida `"Ship"` se aplica formalmente, pero la contraparte de llegada (`"Receive"` / `"Post"`) se retrasa injustificadamente, cancela o falla técnicamente, el sistema arrastrará un volumen de "inventario en tránsito" indefinidamente, vaciando el origen y ahogando contablemente la conciliación entre sucursales.

## 12. Documentación Relacionada
**Interna (Vigente):**
- `docs/2026/04_MODULOS/00_MATRIZ_MAESTRA_MODULOS.md`
- `docs/2026/04_MODULOS/INVENTARIO.md`
- `docs/2026/20_PROTOCOLO_ALINEACION_POS_ERP.md`
- `docs/2026/21_CATALOGO_UOM_Y_CONVERSIONES.md`
- `AI_COORDINATION/STATUS.md`

## 13. Backlog Técnico Prioritario
- [ ] Centralizar y unificar los 3 Controladores API hacia un solo punto de entrada oficial en Routing.
- [ ] Revisar la inyección a Kardex en el `TransferService->post()` cerciorando que su ejecución esté recubierta por `DB::transaction()` como red de seguridad.

---
## 14. Regla de Intervención Previa
⚠️ **ESTRICTO - ANTES DE MODIFICAR ESTE MÓDULO:**
1. **Verificar el Routing:** Localiza a qué endpoint en específico está disparando el Front o Livewire de tu entorno antes de corregir un Bug en uno de los tres controladores hermanos obsoletos.
2. **Pre-Validación en Staging:** Debes operar tú mismo el vuelo completo: `Draft → Ship → Receive → Post`. Revisa explícitamente en el Kardex si el costeo (`WAC`) no sufrió desnaturalización en ese salto de sucursal a sucursal.
