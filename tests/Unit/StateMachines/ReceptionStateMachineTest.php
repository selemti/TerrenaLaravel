<?php

namespace Tests\Unit\StateMachines;

use App\Exceptions\Inventory\InvalidInventoryStateException;
use App\Models\Inventory\ReceptionHeader;
use Tests\TestCase;

class ReceptionStateMachineTest extends TestCase
{
    private function makeHeader(string $estado): ReceptionHeader
    {
        $h = new ReceptionHeader;
        $h->estado = $estado;

        return $h;
    }

    public function test_borrador_can_validate(): void
    {
        $this->assertTrue($this->makeHeader(ReceptionHeader::STATUS_BORRADOR)->canValidate());
    }

    public function test_validada_cannot_validate(): void
    {
        $this->assertFalse($this->makeHeader(ReceptionHeader::STATUS_VALIDADA)->canValidate());
    }

    public function test_borrador_can_post(): void
    {
        $this->assertTrue($this->makeHeader(ReceptionHeader::STATUS_BORRADOR)->canPost());
    }

    public function test_validada_can_post(): void
    {
        $this->assertTrue($this->makeHeader(ReceptionHeader::STATUS_VALIDADA)->canPost());
    }

    public function test_posteada_cannot_post(): void
    {
        $this->assertFalse($this->makeHeader(ReceptionHeader::STATUS_POSTEADA)->canPost());
    }

    public function test_borrador_can_cancel(): void
    {
        $this->assertTrue($this->makeHeader(ReceptionHeader::STATUS_BORRADOR)->canCancel());
    }

    public function test_posteada_cannot_cancel(): void
    {
        $this->assertFalse($this->makeHeader(ReceptionHeader::STATUS_POSTEADA)->canCancel());
    }

    public function test_assert_can_transition_passes_for_valid_move(): void
    {
        $header = $this->makeHeader(ReceptionHeader::STATUS_BORRADOR);
        $header->id = 1;

        // Should not throw
        $header->assertCanTransitionTo(ReceptionHeader::STATUS_VALIDADA);
        $this->assertTrue(true);
    }

    public function test_assert_can_transition_throws_for_invalid_move(): void
    {
        $this->expectException(InvalidInventoryStateException::class);

        $header = $this->makeHeader(ReceptionHeader::STATUS_POSTEADA);
        $header->id = 1;
        $header->assertCanTransitionTo(ReceptionHeader::STATUS_VALIDADA);
    }

    public function test_assert_can_transition_throws_when_already_posted(): void
    {
        $this->expectException(InvalidInventoryStateException::class);

        $header = $this->makeHeader(ReceptionHeader::STATUS_POSTEADA);
        $header->id = 99;
        $header->assertCanTransitionTo(ReceptionHeader::STATUS_POSTEADA);
    }

    public function test_is_posted(): void
    {
        $this->assertTrue($this->makeHeader(ReceptionHeader::STATUS_POSTEADA)->isPosted());
        $this->assertFalse($this->makeHeader(ReceptionHeader::STATUS_BORRADOR)->isPosted());
    }

    public function test_constants_delegate_to_service_constants(): void
    {
        // ReceptionService re-uses model constants — assert they match
        $this->assertEquals(ReceptionHeader::STATUS_BORRADOR, 'BORRADOR');
        $this->assertEquals(ReceptionHeader::STATUS_VALIDADA, 'VALIDADA');
        $this->assertEquals(ReceptionHeader::STATUS_POSTEADA, 'POSTEADA');
        $this->assertEquals(ReceptionHeader::STATUS_CANCELADA, 'CANCELADA');
    }
}
