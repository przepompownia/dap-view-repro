<?php

if (!extension_loaded('xdebug')) {
    throw new Exception('Xdebug extension not loaded');
};

use Arctgx\Foo;

require dirname(__DIR__) . '/vendor/autoload.php';

$foo = new Foo();
$foo->testBrk();
