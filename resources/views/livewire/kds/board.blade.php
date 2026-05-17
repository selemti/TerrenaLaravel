<div class="container-fluid py-4">
    @if(! $hasAccess)
        <div class="alert alert-danger d-flex align-items-center gap-3">
            <i class="fa-solid fa-lock fa-2x"></i>
            <div>
                <h5 class="mb-1">Acceso restringido</h5>
                <p class="mb-0">
                    No tienes permiso para ver el panel de cocina (KDS).
                    Contacta al administrador del sistema.
                </p>
            </div>
        </div>
    @else
        <div class="text-center text-muted py-5">
            <i class="fa-solid fa-desktop fa-3x mb-3"></i>
            <h4>Panel KDS</h4>
            <p>Módulo en construcción.</p>
        </div>
    @endif
</div>
