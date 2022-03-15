pragma circom 2.0.0;

// Import the hash function MiMCSponge
include "mimcsponge.circom";
template Mthash(N){
    signal input leaves[N];
    signal output mkroot;
    // initial leaf position
    var Tn = 2*N-1;
    component Mthash[Tn];
    
    var init_pos=N-1;
    // merkle tree concept. all nodes are accessed to compute every hash
    signal mkt[Tn];
    for(var i=Tn-1;i >= 0;i--){
        if(i >= init_pos){
            Mthash[i] = MiMCSponge(1,220,1);
            Mthash[i].k <== 0;
            // Compute the hash of the leaf
            Mthash[i].ins[0]<==leaves[i-init_pos];
            
        }
        else{
            // computing the hash of left child using the right child. Note this is not a leaf.
            Mthash[i]=MiMCSponge(2,220,1);
            Mthash[i].k<==0;
            Mthash[i].ins[0]<==mkt[2*i+1]; // compute hash of left child
            Mthash[i].ins[1]<==mkt[2*i+2]; // compute hash of right child
        }
        //update ith merkle tree with computed hash
        mkt[i]<==Mthash[i].outs[0];
    }
    // The merkle root, the merkle tree at position 0
    mkroot <== mkt[0];
}

template Main(N){
    signal input inp[N];
    signal output out;
    component merkle_tree_component = Mthash(N);
    //populating merkle tree leafs using the public input.
    for(var i=0;i<N;i++){
        merkle_tree_component.leaves[i]<==inp[i];
    }
    // assigning the output with the merkle tree root.
    out<==merkle_tree_component.mkroot;
}
// inputs are public
component main {public [inp]} = Main(8);