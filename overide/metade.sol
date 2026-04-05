constructor() {
    totalSupply = MAX_SUPPLY;
    balanceOf[msg.sender] = MAX_SUPPLY / 2;        // metade pra sua carteira
    balanceOf[address(this)] = MAX_SUPPLY / 2;     // metade pro contrato
}
