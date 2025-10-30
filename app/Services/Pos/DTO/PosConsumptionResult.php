<?php

namespace App\Services\Pos\DTO;

class PosConsumptionResult
{
    /**
     * @param int $ticketId
     * @param string $status "OK" | "ALREADY_PROCESSED" | "REPROCESSED" | "REVERSED" | "ERROR"
     * @param array|null $consumos Lista de consumos: [['item_id'=>..., 'description'=>..., 'qty'=>..., 'uom'=>..., 'costo_unitario'=>..., 'costo_total'=>...]]
     * @param array|null $missing Lista de huecos de mapeo o problemas
     * @param string|null $message Mensaje descriptivo adicional
     * @param array|null $meta Metadata adicional
     */
    public function __construct(
        protected int $ticketId,
        protected string $status,
        protected ?array $consumos = null,
        protected ?array $missing = null,
        protected ?string $message = null,
        protected ?array $meta = null
    ) {
    }

    public function getTicketId(): int
    {
        return $this->ticketId;
    }

    public function getStatus(): string
    {
        return $this->status;
    }

    public function getConsumos(): ?array
    {
        return $this->consumos;
    }

    public function getMissing(): ?array
    {
        return $this->missing;
    }

    public function getMessage(): ?string
    {
        return $this->message;
    }

    public function getMeta(): ?array
    {
        return $this->meta;
    }

    public function isSuccess(): bool
    {
        return in_array($this->status, ['OK', 'ALREADY_PROCESSED', 'REPROCESSED', 'REVERSED']);
    }

    public function isError(): bool
    {
        return $this->status === 'ERROR';
    }

    public function toArray(): array
    {
        return [
            'ticket_id' => $this->ticketId,
            'status' => $this->status,
            'consumos' => $this->consumos,
            'missing' => $this->missing,
            'message' => $this->message,
            'meta' => $this->meta,
            'success' => $this->isSuccess(),
        ];
    }
}
