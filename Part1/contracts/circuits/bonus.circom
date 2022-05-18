// [bonus] implement an example game from part d
pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template CiaoCiao(numPlayers) {
    // Private inputs.
    signal input privNumInit;
    signal input privSalt;
    signal input privNumFin;

    // Public inputs.
    signal input pubNums[numPlayers-1];
    signal input pubHashInit;

    // Output.
    signal output hashInitOut;

    // Checks that the input signals are legitimate
    // pubNums
    component lessThan[numPlayers+1];
    for (var i = 0; i < numPlayers - 1; i++) {
        lessThan[i] = LessThan(4);
        lessThan[i].in[0] <== pubNums[i];
        lessThan[i].in[1] <== 6;
        lessThan[i].out === 1;
    }
    // privNumInit
    lessThan[numPlayers-1] = LessThan(4);
    lessThan[numPlayers-1].in[0] <== privNumInit;
    lessThan[numPlayers-1].in[1] <== 6;
    lessThan[numPlayers-1].out === 1;
    // privNumFin
    lessThan[numPlayers] = LessThan(4);
    lessThan[numPlayers].in[0] <== privNumFin;
    lessThan[numPlayers].in[1] <== 6;
    lessThan[numPlayers].out === 1;
 
    signal sums[numPlayers];
    sums[0] <== privNumInit;
    for (var i = 0; i < numPlayers - 1; i++) {
        sums[i+1] <== sums[i] + pubNums[i];
    }
    privNumFin === sums[numPlayers - 1];
 
    // Constraint related to hashes.
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privNumInit;
    hashInitOut <== poseidon.out;
    pubHashInit === hashInitOut;
}

component main {public [pubNums, pubHashInit]} = CiaoCiao(4);
