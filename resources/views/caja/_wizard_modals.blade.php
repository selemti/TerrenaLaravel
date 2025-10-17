{{--
  Modal del Wizard de Precorte
  Debe incluirse ANTES de los <script type="module" ...> de caja.

  Requisitos que usa wizard.js (ver ensureModalRefs):
  - Modal:  #czModalPrecorte (o #modalPrecorte, #wizardPrecorte, data-role="precorte")
  - Steps:  #czStep1, #czStep2, #czStep3 (o #step1, #step2, #step3)
  - Barra:  .progress-bar con data-role="stepbar"
  - Botones: #czBtnGuardarPrecorte, #czBtnContinuarConciliacion, #czBtnSincronizarPOS, #czBtnIrPostcorte, #czBtnCerrarSesion
  - Denoms tbody: #czTablaDenoms (o #tablaDenomsBody)
  - Totales/inputs: #czPrecorteTotal, #czDeclCardCredito, #czDeclCardDebito, #czDeclTransfer, #czNotes
  - Chips: [data-role="chip-fondo"], [data-role="ef-esperado"]
  - Conciliación: #czConciliacionGrid (o #concGrid), #czBannerFaltaCorte
  - Hidden id: #cz_precorte_id (o #precorteId)
--}}

<input type="hidden" id="cz_precorte_id" data-role="precorte-id" value="">

<div class="modal fade" id="czModalPrecorte" data-role="precorte" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <div>
          <h5 class="modal-title mb-0">Precorte</h5>
          <small class="text-muted" style="display:none">Fondo: <span data-role="chip-fondo">$0.00</span> · Efectivo esperado: <span data-role="ef-esperado">$0.00</span></small>
        </div>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>

      <div class="modal-body">
        <!-- Progreso -->
        <div class="progress mb-3" style="height: 8px;">
          <div class="progress-bar" role="progressbar" data-role="stepbar" style="width: 33%;" aria-valuenow="33" aria-valuemin="0" aria-valuemax="100"></div>
        </div>

        <!-- STEP 1: Declaración -->
        <section id="czStep1" data-step="1">
          <div class="row g-3">
            <div class="col-md-7">
              <div class="card">
                <div class="card-header py-2"><strong>Efectivo por denominación</strong></div>
                <div class="card-body p-2">
                  <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0" id="czTablaDenoms">
                      <thead>
                        <tr><th>Denominación</th><th>Cantidad</th><th class="text-end">Importe</th></tr>
                      </thead>
                      <tbody data-role="denoms-body"></tbody>
                    </table>
                  </div>
                </div>
                <div class="card-footer py-2 d-flex justify-content-between align-items-center">
                  <span class="text-muted small">Total efectivo declarado</span>
                  <strong id="czPrecorteTotal" data-role="precorte-total">$0.00</strong>
                </div>
              </div>
            </div>

            <div class="col-md-5">
              <div class="card">
                <div class="card-header py-2"><strong>No efectivo</strong></div>
                <div class="card-body">
                  <div class="mb-2">
                    <label class="form-label mb-1 moneda" for="czDeclCardCredito">Tarjeta crédito</label>
                    <input id="czDeclCardCredito" data-role="decl-credito" type="number" step="0.01" min="0" class="form-control form-control-sm moneda" data-decimals="2" data-negative="0" placeholder="0.00">
                  </div>
                  <div class="mb-2">
                    <label class="form-label mb-1" for="czDeclCardDebito">Tarjeta débito</label>
                    <input id="czDeclCardDebito" data-role="decl-debito" type="number" step="0.01" min="0" class="form-control form-control-sm moneda" data-decimals="2" data-negative="0" placeholder="0.00">
                  </div>
                  <div class="mb-2">
                    <label class="form-label mb-1" for="czDeclTransfer">Transferencias</label>
                    <input id="czDeclTransfer" data-role="decl-transfer" type="number" step="0.01" min="0" class="form-control form-control-sm moneda" data-decimals="2" data-negative="0" placeholder="0.00">
                  </div>
                  <div class="mb-2">
                    <label class="form-label mb-1" for="czNotes">Notas</label>
                    <textarea id="czNotes" data-role="notas-paso1" class="form-control form-control-sm" rows="3" placeholder="Observaciones del precorte..."></textarea>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- STEP 2: Conciliación -->
        <section id="czStep2" data-step="2" class="d-none">
          <div class="alert alert-warning d-none" id="czBannerFaltaCorte" data-role="banner-falta-corte">
            <div class="d-flex align-items-center gap-2">
              <i class="fa-solid fa-triangle-exclamation"></i>
              <div>
                <strong>Falta realizar el corte en Floreant POS.</strong><br>
                Realiza el Drawer Pull Report y luego pulsa <em>Sincronizar</em>.
              </div>
              <button type="button" id="czBtnSincronizarPOS" class="btn btn-sm btn-primary ms-auto" data-action="sincronizar-pos">
                Sincronizar
              </button>
            </div>
          </div>

          <!-- Aquí se pinta la conciliación -->
          <div id="czConciliacionGrid" data-role="conc-grid"></div>
        </section>

        <!-- STEP 3: Postcorte -->
        <section id="czStep3" data-step="3" class="d-none">
          <div class="card mb-2">
            <div class="card-header py-2">Resumen final (Postcorte)</div>
            <div class="card-body p-2">
              <div id="pc3Grid" class="mb-2"></div>
              <div class="mb-2">
                <label for="pc3Notas" class="form-label small mb-1">Notas del postcorte</label>
                <textarea id="pc3Notas" class="form-control" rows="3" placeholder="Observaciones, incidencias, folios..."></textarea>
              </div>
              <div class="d-flex gap-2">
                <button id="btnPCGuardar" class="btn btn-outline-primary" type="button">Guardar borrador</button>
                <button id="btnPCValidar" class="btn btn-success ms-auto" type="button">Validar y cerrar</button>
                <button id="btnPCCancelar" class="btn btn-outline-secondary ms-auto" type="button" data-bs-dismiss="modal">Cerrar</button>
              </div>
            </div>
          </div>
        </section>
      </div>

      <div class="modal-footer">
        <!-- Botones para Paso 1 -->
        <button id="czBtnGuardarPrecorte" data-action="guardar-precorte" type="button" class="btn btn-primary">Guardar precorte</button>
        <button id="czBtnContinuarConciliacion" data-action="continuar-conc" type="button" class="btn btn-outline-primary d-none">Continuar</button>

        <!-- Botones para Paso 2 -->
        <button id="btnSincronizarPOS" type="button" class="btn btn-warning d-none" data-action="sincronizar-pos">Sincronizar POS</button>
        <button id="czBtnIrPostcorte" data-action="ir-postcorte" type="button" class="btn btn-success d-none">Ir a Postcorte</button>

        <!-- Botón general -->
        <button id="czBtnCerrarSesion" data-action="cerrar-sesion" type="button" class="btn btn-outline-secondary d-none">Cerrar sesión</button>
      </div>
    </div>
  </div>
</div>
