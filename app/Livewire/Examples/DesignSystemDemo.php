<?php

namespace App\Livewire\Examples;

use Livewire\Component;

class DesignSystemDemo extends Component
{
    public $name = '';
    public $email = '';
    public $message = '';
    public $selectedOption = '';
    public $isSubscribed = false;
    public $date = '';
    public $searchTerm = '';
    
    public $showToast = false;
    public $toastType = 'info';
    public $toastTitle = '';
    public $toastMessage = '';
    
    protected $options = [
        ['value' => 'option1', 'label' => 'Opción 1'],
        ['value' => 'option2', 'label' => 'Opción 2'],
        ['value' => 'option3', 'label' => 'Opción 3'],
    ];
    
    protected $headers = [
        ['label' => 'ID', 'class' => 'w-16'],
        ['label' => 'Nombre', 'class' => 'w-1/4'],
        ['label' => 'Email', 'class' => 'w-1/4'],
        ['label' => 'Fecha', 'class' => 'w-1/4'],
        ['label' => 'Acciones', 'class' => 'w-1/6 text-right'],
    ];
    
    protected $tableData = [
        ['id' => 1, 'name' => 'Juan Pérez', 'email' => 'juan@example.com', 'date' => '2023-01-15'],
        ['id' => 2, 'name' => 'María López', 'email' => 'maria@example.com', 'date' => '2023-01-16'],
        ['id' => 3, 'name' => 'Carlos García', 'email' => 'carlos@example.com', 'date' => '2023-01-17'],
    ];

    public function render()
    {
        return view('livewire.examples.design-system-demo');
    }
    
    public function showToast($type, $title, $message)
    {
        $this->toastType = $type;
        $this->toastTitle = $title;
        $this->toastMessage = $message;
        $this->showToast = true;
        
        // Hide toast after 5 seconds
        $this->dispatch('show-toast', [
            'type' => $type,
            'title' => $title,
            'message' => $message
        ]);
    }
    
    public function submitForm()
    {
        $this->validate([
            'name' => 'required|min:3',
            'email' => 'required|email',
            'message' => 'required|min:10',
        ]);
        
        // Simulate form submission
        $this->showToast('success', 'Formulario enviado', 'Los datos se han guardado correctamente.');
        
        // Reset form
        $this->reset(['name', 'email', 'message']);
    }
}