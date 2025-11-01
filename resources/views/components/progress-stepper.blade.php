@props([
    'steps' => [],
    'current' => 1,
])

@php($current = (int) $current)
<div class="progress-stepper d-flex align-items-center mb-4">
    @foreach($steps as $index => $step)
        @php
            $number = $step['number'] ?? ($index + 1);
            $isCompleted = $number < $current;
            $isActive = $number === $current;
        @endphp
        <div class="step flex-fill {{ $isCompleted ? 'completed' : '' }} {{ $isActive ? 'active' : '' }}">
            <div class="step-circle">
                @if($isCompleted)
                    <i class="fa-solid fa-check"></i>
                @else
                    {{ $number }}
                @endif
            </div>
            <div class="step-label">{{ $step['label'] ?? 'Paso ' . $number }}</div>
        </div>
        @if(! $loop->last)
            <div class="step-divider"></div>
        @endif
    @endforeach
</div>
