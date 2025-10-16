@props([
  'title' => 'Formulario',
  'size'  => 'max-w-xl',   {{-- max-w-lg | max-w-xl | max-w-2xl --}}
  'modalId' => 'appModal',
])

<div
    x-data="{ open:false, onOpen(){ this.open = true }, onClose(){ this.open = false } }"
    x-on:open-modal.window="if($event.detail.id==='{{ $modalId }}') onOpen()"
    x-on:close-modal.window="if($event.detail.id==='{{ $modalId }}') onClose()"
    x-show="open"
    x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/30"
    aria-modal="true" role="dialog"
>
  <div class="bg-white rounded-lg shadow-lg w-[95%] {{ $size }}" @click.away="onClose()">
    <div class="px-4 py-3 border-b flex items-center justify-between">
      <h2 class="font-semibold text-lg">{{ $title }}</h2>
      <button class="text-gray-500" @click="onClose()" aria-label="Cerrar">✕</button>
    </div>

    <div class="p-4">
      {{ $slot }}
    </div>

    @if(isset($footer))
      <div class="px-4 py-3 border-t">
        {{ $footer }}
      </div>
    @endif
  </div>
</div>
