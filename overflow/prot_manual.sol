// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract OverflowSeguro {
    uint8 public x = 255;

    // SEM proteção — vai explodir e virar 0
    function incrementarPerigoso() public {
        x++;
    }

    // COM proteção manual — vai reverter com erro
    function incrementarSeguro() public {
        require(x < 255, "Overflow detectado!");
        x++;
    }
}
