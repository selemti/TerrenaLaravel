<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PurchaseDocument extends Model
{
    protected $connection = 'pgsql';
    protected $table = 'purchase_documents';
    protected $guarded = [];

    /**
     * Tipos de documentos
     */
    const TIPO_COTIZACION = 'COTIZACION';
    const TIPO_ORDEN_COMPRA = 'ORDEN_COMPRA';
    const TIPO_FACTURA = 'FACTURA';
    const TIPO_REMISION = 'REMISION';
    const TIPO_CONTRATO = 'CONTRATO';
    const TIPO_ESPECIFICACION = 'ESPECIFICACION';
    const TIPO_CERTIFICADO = 'CERTIFICADO';
    const TIPO_OTRO = 'OTRO';

    // ==================== RELATIONSHIPS ====================

    /**
     * Solicitud de compra asociada (si aplica)
     */
    public function purchaseRequest(): BelongsTo
    {
        return $this->belongsTo(PurchaseRequest::class, 'request_id');
    }

    /**
     * Cotización asociada (si aplica)
     */
    public function vendorQuote(): BelongsTo
    {
        return $this->belongsTo(VendorQuote::class, 'quote_id');
    }

    /**
     * Orden de compra asociada (si aplica)
     */
    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class, 'order_id');
    }

    /**
     * Usuario que subió el documento
     */
    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    // ==================== ACCESSORS ====================

    /**
     * Badge HTML del tipo de documento
     */
    public function getTipoBadgeAttribute(): string
    {
        return match($this->tipo) {
            self::TIPO_COTIZACION => '<span class="badge bg-info">Cotización</span>',
            self::TIPO_ORDEN_COMPRA => '<span class="badge bg-primary">Orden de Compra</span>',
            self::TIPO_FACTURA => '<span class="badge bg-success">Factura</span>',
            self::TIPO_REMISION => '<span class="badge bg-warning">Remisión</span>',
            self::TIPO_CONTRATO => '<span class="badge bg-secondary">Contrato</span>',
            self::TIPO_ESPECIFICACION => '<span class="badge bg-info">Especificación</span>',
            self::TIPO_CERTIFICADO => '<span class="badge bg-success">Certificado</span>',
            self::TIPO_OTRO => '<span class="badge bg-light text-dark">Otro</span>',
            default => '<span class="badge bg-secondary">' . $this->tipo . '</span>',
        };
    }

    /**
     * Nombre del archivo (extraído de la URL)
     */
    public function getFileNameAttribute(): string
    {
        return basename($this->file_url);
    }

    /**
     * Extensión del archivo
     */
    public function getFileExtensionAttribute(): string
    {
        return strtolower(pathinfo($this->file_url, PATHINFO_EXTENSION));
    }

    /**
     * Indica si es un PDF
     */
    public function getIsPdfAttribute(): bool
    {
        return $this->file_extension === 'pdf';
    }

    /**
     * Indica si es una imagen
     */
    public function getIsImageAttribute(): bool
    {
        return in_array($this->file_extension, ['jpg', 'jpeg', 'png', 'gif', 'webp']);
    }

    /**
     * Icono de Font Awesome según el tipo de archivo
     */
    public function getFileIconAttribute(): string
    {
        return match($this->file_extension) {
            'pdf' => 'fa-file-pdf text-danger',
            'doc', 'docx' => 'fa-file-word text-primary',
            'xls', 'xlsx' => 'fa-file-excel text-success',
            'jpg', 'jpeg', 'png', 'gif', 'webp' => 'fa-file-image text-info',
            'zip', 'rar', '7z' => 'fa-file-zipper text-warning',
            default => 'fa-file text-secondary',
        };
    }

    /**
     * Referencia del documento (qué documento padre tiene)
     */
    public function getReferenciaAttribute(): string
    {
        if ($this->request_id) {
            return "Solicitud #{$this->request_id}";
        }
        if ($this->quote_id) {
            return "Cotización #{$this->quote_id}";
        }
        if ($this->order_id) {
            return "Orden #{$this->order_id}";
        }
        return "Sin referencia";
    }

    // ==================== SCOPES ====================

    /**
     * Scope por tipo de documento
     */
    public function scopePorTipo($query, string $tipo)
    {
        return $query->where('tipo', $tipo);
    }

    /**
     * Scope por solicitud
     */
    public function scopePorRequest($query, int $requestId)
    {
        return $query->where('request_id', $requestId);
    }

    /**
     * Scope por cotización
     */
    public function scopePorQuote($query, int $quoteId)
    {
        return $query->where('quote_id', $quoteId);
    }

    /**
     * Scope por orden
     */
    public function scopePorOrder($query, int $orderId)
    {
        return $query->where('order_id', $orderId);
    }

    /**
     * Scope para documentos PDF
     */
    public function scopePdfs($query)
    {
        return $query->where('file_url', 'like', '%.pdf');
    }

    /**
     * Scope para imágenes
     */
    public function scopeImagenes($query)
    {
        return $query->where(function ($q) {
            $q->where('file_url', 'like', '%.jpg')
              ->orWhere('file_url', 'like', '%.jpeg')
              ->orWhere('file_url', 'like', '%.png')
              ->orWhere('file_url', 'like', '%.gif')
              ->orWhere('file_url', 'like', '%.webp');
        });
    }
}
