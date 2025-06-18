<?php

namespace Arctgx;

class Foo
{
    private function bar(): void
    {
        echo 'bar';
        echo '2';
        echo '3';
        echo '4';
    }

    private function foo(): void
    {
        $this->bar();
    }

    public function testBrk(): void
    {
        $this->foo();
        print(microtime(true));
    }
}
