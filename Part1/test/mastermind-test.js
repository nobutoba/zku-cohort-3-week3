//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;
const assert = chai.assert;


// validates colorPubGuess, colorPrivSoln, shapePubGuess, or shapePrivSoln
function validate(arr) {
    // arr must have length 3
    if (arr.length !== 3) {
        throw new Error;
    }
    // each element of arr must be 0, 1, 2, 3, or 4
    for (const elem of arr) {
        if (elem < 0 || elem > 4) {
            throw new Error;
        }
    }
    // elements of arr must be distinct
    for (let i = 0; i < 3; i++) {
        // (i, j) = (0, 1), (1, 2), or (2, 0)
        let j = (i + 1) % 3;
        if (arr[i] === arr[j]) {
            throw new Error;
        }
    }
}


// calculate hit and blow
function hitAndBlow(pubGuess, privSoln) {
    let hit = 0;
    let blow = 0;
    for (let i = 0; i < pubGuess.length; i++) {
        for (let j = 0; j < privSoln.length; j++) {
            if (pubGuess[i] === privSoln[j]) {
                blow += 1;
                if (i === j) {
                    hit += 1;
                    blow -= 1;
                }
            }
        }
    }
    return [hit, blow];
}


// a factory function to create valid input signals as a single object
const createValidInputSignals = (
    poseidon,
    colorPubGuess,
    colorPrivSoln,
    shapePubGuess,
    shapePrivSoln,
    privSalt = BigInt(0),
) => {
    validate(colorPubGuess);
    validate(colorPrivSoln);
    validate(shapePubGuess);
    validate(shapePrivSoln);
    const [colorPubNumHit, colorPubNumBlow] = hitAndBlow(colorPubGuess, colorPrivSoln);
    const [shapePubNumHit, shapePubNumBlow] = hitAndBlow(shapePubGuess, shapePrivSoln);
    return {
        "colorPubGuess": colorPubGuess,
        "colorPrivSoln": colorPrivSoln,
        "colorPubNumHit": colorPubNumHit,
        "colorPubNumBlow": colorPubNumBlow,
        "shapePubGuess": shapePubGuess,
        "shapePrivSoln": shapePrivSoln,
        "shapePubNumHit": shapePubNumHit,
        "shapePubNumBlow": shapePubNumBlow,
        "pubSolnHash": poseidonCircomlibjs(
            poseidon, [privSalt, ...colorPrivSoln, ...shapePrivSoln]
        ),
        "privSalt": privSalt,
    }
}


// Poseidon from circomlibjs
// special thanks to:
//  https://discord.com/channels/942318442340560917/969554923396153345/978222168825556992
function poseidonCircomlibjs(poseidon, arr) {
    return BigInt(poseidon.F.toString(poseidon(arr)));
}


describe("Mastermind test", function ()  {
    this.timeout(100000);
    
    it("Should create a MastermindVariation circuit", async () => {
        const poseidon = await buildPoseidon();
        const signals = createValidInputSignals(
            poseidon, [0, 4, 2], [2, 3, 4], [3, 2, 1], [1, 2, 3], BigInt(1234567890),
        )
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        const witness = await circuit.calculateWitness(signals, true);
        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(signals.pubSolnHash)));
    });
});
