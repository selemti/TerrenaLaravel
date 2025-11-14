<?php

namespace Tests\Unit\Components;

use Tests\TestCase;

class UiComponentsTest extends TestCase
{
    public function test_card_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/card.blade.php'));
    }

    public function test_table_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/table.blade.php'));
    }

    public function test_advanced_table_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/advanced-table.blade.php'));
    }

    public function test_input_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/input.blade.php'));
    }

    public function test_select_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/select.blade.php'));
    }

    public function test_checkbox_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/checkbox.blade.php'));
    }

    public function test_toast_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/toast.blade.php'));
    }

    public function test_banner_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/banner.blade.php'));
    }

    public function test_date_picker_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/date-picker.blade.php'));
    }

    public function test_search_input_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/search-input.blade.php'));
    }

    public function test_loading_skeleton_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/loading-skeleton.blade.php'));
    }

    public function test_dropdown_component_exists(): void
    {
        $this->assertFileExists(resource_path('views/components/ui/dropdown.blade.php'));
    }
}
