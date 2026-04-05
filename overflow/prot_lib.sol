// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0; // <-- usa 0.7 pra simular o passado

import "@openzeppelin/contracts/math/SafeMath.sol";

contract OverflowSeguro {
    using SafeMath for uint8;
    
    uint8 public x = 255;

    function incrementarSemProtecao() public {
        x++; // explode silenciosamente no 0.7
    }

    function incrementarComSafeMath() public {
        x = x.add(1); // reverte com erro no 0.7
    }
}
