// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract overflow{
uint8 public x = 255;

    function incrementar()public {
    unchecked {
                 x++;
        }

    }
}
/antes do versão 0.8.0 , havia problema do overflow, mas voe utilizaria o safemath.
