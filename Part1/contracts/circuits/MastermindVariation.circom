pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindVariation() {
    // Public/private inputs related to colors
    signal input colorPubGuess[3];
    signal input colorPrivSoln[3];
    signal input colorPubNumHit;
    signal input colorPubNumBlow;

    // Public/private inputs related to shapes
    signal input shapePubGuess[3];
    signal input shapePrivSoln[3];
    signal input shapePubNumHit;
    signal input shapePubNumBlow;

    // One last public input. Hash value of the salted solution.
    signal input pubSolnHash;

    // One last private input. Salt.
    signal input privSalt;

    // Output
   signal output solnHashOut;

    // Check whether colors are legitimate.
    // 1. Create constraints that the solution and guess digits for colors are all less than 5.
    // 2. Create constraints that the solution and guess digits for colors are distinct.
    component colorLessThan[6];  // 6 = 3 + 3
    component colorEqualGuess[3];  // 3 = (3 choose 2)
    component colorEqualSoln[3];  // 3 = (3 choose 2)
    for(var j = 0; j < 3; j++) {
        // Checks elements of colorPubGuess are less than 5.
        // Assumes these signals have 4-bit representations.
        colorLessThan[j] = LessThan(4);
        colorLessThan[j].in[0] <== colorPubGuess[j];
        colorLessThan[j].in[1] <== 5;
        colorLessThan[j].out === 1;

        // Checks elements of colorPrivSoln are less than 5.
        // Assumes these signals have 4-bit representations.
        colorLessThan[j+3] = LessThan(4);
        colorLessThan[j+3].in[0] <== colorPrivSoln[j];
        colorLessThan[j+3].in[1] <== 5;
        colorLessThan[j+3].out === 1;

        // There is no nested for loop because (3 choose 2) = 3.
        // Index to compare with. (j, k) = (0, 1), (1, 2), (2, 0).
        var k = (j+1) % 3;

        // Checks elements of colorPubGuess are distinct.
        colorEqualGuess[j] = IsEqual();
        colorEqualGuess[j].in[0] <== colorPubGuess[j];
        colorEqualGuess[j].in[1] <== colorPubGuess[k];
        colorEqualGuess[j].out === 0;

        // Checks elements of colorPrivSoln are distinct.
        colorEqualSoln[j] = IsEqual();
        colorEqualSoln[j].in[0] <== colorPrivSoln[j];
        colorEqualSoln[j].in[1] <== colorPrivSoln[k];
        colorEqualSoln[j].out === 0;
    }

    // Check whether shapes are legitimate.
    // 1. Create constraints that the solution and guess digits for shapes are all less than 5.
    // 2. Create constraints that the solution and guess digits for shapes are distinct.
    component shapeLessThan[6];  // 6 = 3 + 3
    component shapeEqualGuess[3];  // 3 = (3 choose 2)
    component shapeEqualSoln[3];  // 3 = (3 choose 2)
    for(var j = 0; j < 3; j++) {
        // Checks elements of shapePubGuess are less than 5.
        // Assumes these signals have 4-bit representations.
        shapeLessThan[j] = LessThan(4);
        shapeLessThan[j].in[0] <== shapePubGuess[j];
        shapeLessThan[j].in[1] <== 5;
        shapeLessThan[j].out === 1;

        // Checks elements of shapePrivSoln are less than 5.
        // Assumes these signals have 4-bit representations.
        shapeLessThan[j+3] = LessThan(4);
        shapeLessThan[j+3].in[0] <== shapePrivSoln[j];
        shapeLessThan[j+3].in[1] <== 5;
        shapeLessThan[j+3].out === 1;

        // There is no nested for loop because (3 choose 2) happens to be equal to 3 itself.
        // Index to compare with. (j, k) = (0, 1), (1, 2), (2, 0).
        var k = (j+1) % 3;

        // Checks elements of shapePubGuess are distinct.
        shapeEqualGuess[j] = IsEqual();
        shapeEqualGuess[j].in[0] <== shapePubGuess[j];
        shapeEqualGuess[j].in[1] <== shapePubGuess[k];
        shapeEqualGuess[j].out === 0;

        // Checks elements of shapePrivSoln are distinct.
        shapeEqualSoln[j] = IsEqual();
        shapeEqualSoln[j].in[0] <== shapePrivSoln[j];
        shapeEqualSoln[j].in[1] <== shapePrivSoln[k];
        shapeEqualSoln[j].out === 0;
    }

    // Count hit & blow for colors
    var colorHit = 0;
    var colorBlow = 0;
    component colorEqualHB[9];  // 9 = 3 * 3
    for (var j=0; j<3; j++) {
        for (var k=0; k<3; k++) {
            colorEqualHB[3*j+k] = IsEqual();
            colorEqualHB[3*j+k].in[0] <== colorPrivSoln[j];
            colorEqualHB[3*j+k].in[1] <== colorPubGuess[k];
            colorBlow += colorEqualHB[3*j+k].out;
            if (j == k) {
                colorHit += colorEqualHB[3*j+k].out;
                colorBlow -= colorEqualHB[3*j+k].out;
            }
        }
    }

    // Create a constraint around the number of hit & blow for colors
    component colorEqualHit = IsEqual();
    colorEqualHit.in[0] <== colorPubNumHit;
    colorEqualHit.in[1] <== colorHit;
    colorEqualHit.out === 1;
    component colorEqualBlow = IsEqual();
    colorEqualBlow.in[0] <== colorPubNumBlow;
    colorEqualBlow.in[1] <== colorBlow;
    colorEqualBlow.out === 1;

    // Count hit & blow for shapes
    var shapeHit = 0;
    var shapeBlow = 0;
    component shapeEqualHB[9];  // 9 = 3 * 3
    for (var j=0; j<3; j++) {
        for (var k=0; k<3; k++) {
            shapeEqualHB[3*j+k] = IsEqual();
            shapeEqualHB[3*j+k].in[0] <== shapePrivSoln[j];
            shapeEqualHB[3*j+k].in[1] <== shapePubGuess[k];
            shapeBlow += shapeEqualHB[3*j+k].out;
            if (j == k) {
                shapeHit += shapeEqualHB[3*j+k].out;
                shapeBlow -= shapeEqualHB[3*j+k].out;
            }
        }
    }

    // Create a constraint around the number of hit & blow for shapes
    component shapeEqualHit = IsEqual();
    shapeEqualHit.in[0] <== shapePubNumHit;
    shapeEqualHit.in[1] <== shapeHit;
    shapeEqualHit.out === 1;
    component shapeEqualBlow = IsEqual();
    shapeEqualBlow.in[0] <== shapePubNumBlow;
    shapeEqualBlow.in[1] <== shapeBlow;
    shapeEqualBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(7);  // 7 = 1 + 3 + 3
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== colorPrivSoln[0];
    poseidon.inputs[2] <== colorPrivSoln[1];
    poseidon.inputs[3] <== colorPrivSoln[2];
    poseidon.inputs[4] <== shapePrivSoln[0];
    poseidon.inputs[5] <== shapePrivSoln[1];
    poseidon.inputs[6] <== shapePrivSoln[2];
    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
}

component main {public [
        colorPubGuess, colorPubNumHit, colorPubNumBlow,
        shapePubGuess, shapePubNumHit, shapePubNumBlow,
        pubSolnHash
    ]
} = MastermindVariation();
