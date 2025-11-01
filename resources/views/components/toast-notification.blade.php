{{--
    Toast Notification Component

    Sistema de notificaciones tipo toast para feedback al usuario.
    Compatible con Livewire events.

    Uso en Blade:
    <x-toast-notification />

    Uso en Livewire:
    $this->dispatch('notify', type: 'success', message: 'Guardado exitosamente');
    $this->dispatch('notify', type: 'error', message: 'Error al guardar');
    $this->dispatch('notify', type: 'warning', message: 'Advertencia');
    $this->dispatch('notify', type: 'info', message: 'Información');

    Tipos disponibles: success, error, warning, info
--}}

<div
    x-data="{
        show: false,
        type: 'success',
        message: '',
        timeout: null,

        showToast(type, message, duration = 3000) {
            this.type = type;
            this.message = message;
            this.show = true;

            clearTimeout(this.timeout);
            this.timeout = setTimeout(() => {
                this.show = false;
            }, duration);
        },

        hideToast() {
            this.show = false;
            clearTimeout(this.timeout);
        }
    }"
    @notify.window="showToast($event.detail.type || 'success', $event.detail.message || '', $event.detail.duration || 3000)"
    x-show="show"
    x-transition:enter="transition ease-out duration-300"
    x-transition:enter-start="opacity-0 translate-y-4"
    x-transition:enter-end="opacity-100 translate-y-0"
    x-transition:leave="transition ease-in duration-200"
    x-transition:leave-start="opacity-100 translate-y-0"
    x-transition:leave-end="opacity-0 translate-y-4"
    style="display: none;"
    class="position-fixed bottom-0 end-0 p-3"
    style="z-index: 9999;"
>
    <div
        class="toast show align-items-center border-0"
        :class="{
            'text-bg-success': type === 'success',
            'text-bg-danger': type === 'error',
            'text-bg-warning': type === 'warning',
            'text-bg-info': type === 'info'
        }"
        role="alert"
        aria-live="assertive"
        aria-atomic="true"
    >
        <div class="d-flex">
            <div class="toast-body d-flex align-items-center gap-2">
                {{-- Icono según el tipo --}}
                <span x-show="type === 'success'">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-check-circle-fill" viewBox="0 0 16 16">
                        <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/>
                    </svg>
                </span>
                <span x-show="type === 'error'">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-x-circle-fill" viewBox="0 0 16 16">
                        <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0M5.354 4.646a.5.5 0 1 0-.708.708L7.293 8l-2.647 2.646a.5.5 0 0 0 .708.708L8 8.707l2.646 2.647a.5.5 0 0 0 .708-.708L8.707 8l2.647-2.646a.5.5 0 0 0-.708-.708L8 7.293z"/>
                    </svg>
                </span>
                <span x-show="type === 'warning'">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-exclamation-triangle-fill" viewBox="0 0 16 16">
                        <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5m.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2"/>
                    </svg>
                </span>
                <span x-show="type === 'info'">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                        <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2"/>
                    </svg>
                </span>

                <span x-text="message"></span>
            </div>
            <button
                type="button"
                class="btn-close btn-close-white me-2 m-auto"
                @click="hideToast()"
                aria-label="Cerrar"
            ></button>
        </div>
    </div>
</div>
