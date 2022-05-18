// [bonus] unit test for bonus.circom
const chai = require("chai");
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;
const assert = chai.assert;


// Poseidon from circomlibjs
function poseidonCircomlibjs(poseidon, arr) {
    return BigInt(poseidon.F.toString(poseidon(arr)));
}


describe("Bonus test", function ()  {
    this.timeout(100000);
    
    it("Should create a CiaoCiao circuit", async () => {
        const privNumInit = 0;
        const privSalt = 1234567890n;
        const poseidon = await buildPoseidon();
        const signals = {
            privNumInit: privNumInit,
            privSalt: privSalt,
            privNumFin: 1,
            pubNums: [5, 0, 2],
            pusHashInit: poseidonCircomlibjs(poseidon, [privSalt, privNumInit]),
        }
        const circuit = await wasm_tester("contracts/circuits/bonus.circom");
        const witness = await circuit.calculateWitness(signals, true);
        assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]), Fr.e(signals.pubHashInit)));
    });
});
