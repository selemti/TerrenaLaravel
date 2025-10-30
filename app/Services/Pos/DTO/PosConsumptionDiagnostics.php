<?php

namespace App\Services\Pos\DTO;

class PosConsumptionDiagnostics
{
    /**
     * @param bool $ticketHeaderOk
     * @param int $itemsTotal
     * @param int $itemsConReceta
     * @param int $itemsSinReceta
     * @param bool $tieneConsumoConfirmado
     * @param string $estadoConsumo "PENDIENTE" | "CONFIRMADO" | "ANULADO" | "SIN_DATOS"
     * @param bool $puedeReprocesar
     * @param bool $puedeReversar
     * @param bool $faltanEmpaquesToGo
     * @param bool $faltanConsumiblesOperativos
     * @param array|null $itemsSinRecetaDetalle Lista de items sin receta con detalles
     * @param array|null $warnings Lista de advertencias
     */
    public function __construct(
        protected bool $ticketHeaderOk,
        protected int $itemsTotal,
        protected int $itemsConReceta,
        protected int $itemsSinReceta,
        protected bool $tieneConsumoConfirmado,
        protected string $estadoConsumo,
        protected bool $puedeReprocesar,
        protected bool $puedeReversar,
        protected bool $faltanEmpaquesToGo,
        protected bool $faltanConsumiblesOperativos,
        protected ?array $itemsSinRecetaDetalle = null,
        protected ?array $warnings = null
    ) {
    }

    public function getTicketHeaderOk(): bool
    {
        return $this->ticketHeaderOk;
    }

    public function getItemsTotal(): int
    {
        return $this->itemsTotal;
    }

    public function getItemsConReceta(): int
    {
        return $this->itemsConReceta;
    }

    public function getItemsSinReceta(): int
    {
        return $this->itemsSinReceta;
    }

    public function getTieneConsumoConfirmado(): bool
    {
        return $this->tieneConsumoConfirmado;
    }

    public function getEstadoConsumo(): string
    {
        return $this->estadoConsumo;
    }

    public function getPuedeReprocesar(): bool
    {
        return $this->puedeReprocesar;
    }

    public function getPuedeReversar(): bool
    {
        return $this->puedeReversar;
    }

    public function getFaltanEmpaquesToGo(): bool
    {
        return $this->faltanEmpaquesToGo;
    }

    public function getFaltanConsumiblesOperativos(): bool
    {
        return $this->faltanConsumiblesOperativos;
    }

    public function getItemsSinRecetaDetalle(): ?array
    {
        return $this->itemsSinRecetaDetalle;
    }

    public function getWarnings(): ?array
    {
        return $this->warnings;
    }

    public function hasIssues(): bool
    {
        return $this->itemsSinReceta > 0
            || $this->faltanEmpaquesToGo
            || $this->faltanConsumiblesOperativos
            || !empty($this->warnings);
    }

    public function toArray(): array
    {
        return [
            'ticket_header_ok' => $this->ticketHeaderOk,
            'items_total' => $this->itemsTotal,
            'items_con_receta' => $this->itemsConReceta,
            'items_sin_receta' => $this->itemsSinReceta,
            'tiene_consumo_confirmado' => $this->tieneConsumoConfirmado,
            'estado_consumo' => $this->estadoConsumo,
            'puede_reprocesar' => $this->puedeReprocesar,
            'puede_reversar' => $this->puedeReversar,
            'faltan_empaques_to_go' => $this->faltanEmpaquesToGo,
            'faltan_consumibles_operativos' => $this->faltanConsumiblesOperativos,
            'items_sin_receta_detalle' => $this->itemsSinRecetaDetalle,
            'warnings' => $this->warnings,
            'has_issues' => $this->hasIssues(),
        ];
    }
}
