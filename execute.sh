#!/bin/bash
shopt -s extglob
#Removing old unecessary files
rm -rfv !("execute.sh"|*.circom|"input.json")

/"""
--r1cs: it generates the file multiplier2.r1cs that contains the R1CS constraint system of the circuit in binary format.
--wasm: it generates the directory multiplier2_js that contains the Wasm code (multiplier2.wasm) and other files needed to generate the witness.
--sym : it generates the file multiplier2.sym , a symbols file required for debugging or for printing the constraint system in an annotated mode.
--c : it generates the directory multiplier2_cpp that contains several files (multiplier2.cpp, multiplier2.dat, 
    and other common files for every compiled program like main.cpp, MakeFile, etc) needed to compile the C code to generate the witness.
"""/
#This following line of code produces the above files, make sure the correct file is compiled
circom circuit.circom --r1cs --wasm --sym --c 

#Computing our witness
/"""
    Before creating the proof, we need to calculate all the signals of the circuit that match all the constraints of the circuit. 
For that, we will use the Wasm module generated bycircom that helps to do this job.
    We need to create a file named input.json containing the inputs written in the 
standard json format.
"""/

#Computing the witness with WebAssembly
cd circuit_js
node generate_witness.js circuit.wasm ../input.json witness.wtns

#copy a copy of the witness.wtns to project root directory
cp witness.wtns ../witness.wtns 

#move into the root directory
cd ..       

#uncomment necessary for zeroknowledge proof.
#Proving circuits
/"""After compiling the circuit and running the witness calculator with an appropriate input, 
we will have a file with extension .wtns that contains all the computed signals and, 
a file with extension .r1cs that contains the constraints describing the circuit. 
Both files will be used to create our proof.

We will use the snarkjs tool to generate and validate a proof for our input
"""/
#Powers of Tau / Phase 1
#we start a new "powers of tau" ceremony
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v #uncomment

#Then, we contribute to the ceremony:
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v -e="rand text" #uncomment

#Phase 2
#Generation of this phase:
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v #uncomment

#Next, we generate a new .zkey  file that will contain the proving and verification keys together with all phase 2 contributions.
snarkjs groth16 setup circuit.r1cs pot12_final.ptau circuit_0000.zkey #uncomment

#Contributing to phase 2 of the ceremony:
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v -e="rand text" #uncomment

#Exporting the verification key:
snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json #uncomment

#Generating a Zk Proof
/"""
Once the witness is computed and the trusted setup is already executed, 
we can generate a zk-proof associated to the circuit and the witness:
"""/
#snarkjs groth16 prove circuit_0001.zkey witness.wtns proof.json public.json #uncomment
/"""
This above command generates a Groth16 proof and outputs two files:
    proof.json: it contains the proof.
    public.json: it contains the values of the public inputs and outputs.
"""/

#Verifying a Proof
#To verify the proof, execute the following 
#snarkjs groth16 verify verification_key.json public.json proof.json #uncomment
/"""
Note: A valid proof not only proves that we know a set of signals that satisfy the circuit, but also that the public inputs and 
outputs that we use match the ones described in the public.json file.
"""/
#Optional
#Verifying from a Smart Contract
​#Generating a Solidity verifier that allows verifying proofs on Ethereum blockchain.

#snarkjs zkey export solidityverifier circuit_0001.zkey verifier.sol #uncomment
/"""This command takes validation key multiplier2_0001.zkey and outputs Solidity code in a file named verifier.sol. 
You can take the code from this file and cut and paste it in Remix. You will see that the code contains two 
contracts: Pairing and Verifier. You only need to deploy the Verifier contract.
"""/
#Genarating the parameters of the call
#snarkjs generatecall #uncomment
shopt -u extglob



