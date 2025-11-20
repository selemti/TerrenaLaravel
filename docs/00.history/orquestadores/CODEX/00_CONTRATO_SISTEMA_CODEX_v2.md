# CONTRATO SISTEMA TERRENA · ORQUESTADOR DOCUMENTAL V2 (CODEX)

## 1. Propósito
Garantizar que cualquier decisión documental o técnica se base únicamente en la evidencia consolidada durante la auditoría del **13 de noviembre de 2025** (FASES 1–6) y en la estructura oficial `docs/V4.0/`. El orquestador CODEX se compromete a custodiar y ejecutar el plan acordado sin crear módulos nuevos ni alterar la topología vigente.

## 2. Fuentes autorizadas
1. **Compendio Documental** – `docs/00.history/auditorias/AUDITORIA_2025_11_13/FASE1_COMPENDIO_DOCUMENTACION.md`
2. **Análisis V4.0** – `FASE2_ANALISIS_V4.0.md`
3. **Estructura Integrada** – `FASE3_ESTRUCTURA_INTEGRADA.md`
4. **Análisis de Código** – `FASE4_ANALISIS_CODIGO.md`
5. **Análisis BD selemti** – `FASE5_ANALISIS_BD_SELEMTI.md`
6. **Evaluación UI/UX** – `FASE6_EVALUACION_UI_UX.md`
7. **Estado actual V4.0** (19 documentos, 11 módulos cubiertos al 73%)

Ninguna otra fuente puede invocarse.

## 3. Principios de operación
| # | Principio | Descripción |
|---|-----------|-------------|
| P1 | **“Doc antes de code”** | Toda brecha debe documentarse en `docs/V4.0/` antes de tocar código (FASE3). |
| P2 | **Integridad histórica** | Ningún archivo en `docs/V4.0/` se elimina; los legados se mueven a `_reference` según FASE3. |
| P3 | **Trazabilidad cruzada** | Cada hallazgo debe enlazar código (FASE4), tablas (FASE5) y UX (FASE6). |
| P4 | **Sin módulos nuevos** | Solo se trabaja sobre los 15 módulos identificados en FASE1 y su cobertura V4.0. |

## 4. Responsabilidades CODEX
- Custodiar la **matriz de alineación** (FASE2 + FASE3).
- Mantener el **backlog de sprints** con prioridades 🔴/🟡/🟢 (FASE3).
- Proveer síntesis ejecutiva (FASE1) y riesgos técnicos (FASE4/FASE5/FASE6).
- Validar que cada entrega documente **estado actual vs. gaps** (FASE2) y adjunte evidencias.

## 5. Restricciones
1. No alterar la estructura física de `docs/V4.0/`.
2. No generar specs fuera de los cuatro archivos del orquestador.
3. No inventar funcionalidades: solo se admiten las descritas en FASE1–FASE6.
4. No degradar la puntuación lograda (76% V4.0 según FASE2); todo plan debe aumentar cobertura.

## 6. Criterios de éxito
- **Cobertura documental ≥ 90%** (meta de FASE2).
- **Código huérfano < 10%** (FASE4 detectó 39%; se debe reducir).
- **Tablas legacy ≤ 3** y funciones críticas documentadas (FASE5).
- **UX score ≥ 8/10** mediante solución de los tres gaps críticos (FASE6).

Firmado digitalmente por **CODEX – Orquestador Documental V2**.
