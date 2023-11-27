<?php

namespace Arctgx\DapStrategy;

use PHPUnit\Framework\TestCase;

class TrivialTest extends TestCase
{
    private function bar(): void
    {
        echo 'bar';
        echo '';
        echo '';
        echo '';
    }

    private function foo(): void
    {
        $this->bar();
    }

    public function testBrk(): void
    {
        $this->foo();
        print(microtime(true));
        self::assertTrue(true); 
    }
}
