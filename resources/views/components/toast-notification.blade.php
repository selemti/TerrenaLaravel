@if (session()->has('ok') || session()->has('error') || session()->has('warn'))
    <div class="toast-container position-fixed top-0 end-0 p-3" style="z-index: 1080;">
        @if(session()->has('ok'))
            <div class="toast align-items-center text-white bg-success border-0 show shadow" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-check-circle me-2"></i>
                        {{ session('ok') }}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Cerrar"></button>
                </div>
            </div>
        @endif

        @if(session()->has('error'))
            <div class="toast align-items-center text-white bg-danger border-0 show shadow" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-exclamation-triangle me-2"></i>
                        {{ session('error') }}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Cerrar"></button>
                </div>
            </div>
        @endif

        @if(session()->has('warn'))
            <div class="toast align-items-center text-dark bg-warning border-0 show shadow" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="bi bi-info-circle me-2"></i>
                        {{ session('warn') }}
                    </div>
                    <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast" aria-label="Cerrar"></button>
                </div>
            </div>
        @endif
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            document.querySelectorAll('.toast').forEach((toastEl) => {
                const toast = bootstrap.Toast.getOrCreateInstance(toastEl, { delay: 5000 });
                toast.show();
            });
        });
    </script>
@endif
