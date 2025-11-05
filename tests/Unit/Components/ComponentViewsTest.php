<?php

namespace Tests\Unit\Components;

use Tests\TestCase;

class ComponentViewsTest extends TestCase
{
    public function test_ui_components_can_be_rendered(): void
    {
        // Test that we can render a view that includes our components
        $view = view('components.ui.card', [
            'title' => 'Test Card',
            'subtitle' => 'Test Subtitle'
        ])->render();
        
        $this->assertStringContainsString('Test Card', $view);
        $this->assertStringContainsString('Test Subtitle', $view);
    }

    public function test_input_component_can_be_rendered(): void
    {
        $view = view('components.ui.input', [
            'id' => 'test-input',
            'label' => 'Test Label'
        ])->render();
        
        $this->assertStringContainsString('Test Label', $view);
        $this->assertStringContainsString('test-input', $view);
    }

    public function test_select_component_can_be_rendered(): void
    {
        $view = view('components.ui.select', [
            'id' => 'test-select',
            'label' => 'Test Label',
            'options' => [
                ['value' => '1', 'label' => 'Option 1']
            ]
        ])->render();
        
        $this->assertStringContainsString('Test Label', $view);
        $this->assertStringContainsString('Option 1', $view);
    }
}