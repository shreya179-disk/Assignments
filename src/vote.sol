// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote{
    
    uint[]  public Voterids;
    struct Voter{
        uint Voterid;
        string Voter_name;
        bool Voted;
    }
    mapping(uint => Voter) public voters;

    function addnew_Voter(uint _Voterid, string memory _Voter_name, bool ) public {
        require(voters[_Voterid].Voterid == 0, "voter already registered");
        voters[ _Voterid] = Voter({
            Voterid: _Voterid,
            Voter_name: _Voter_name,
            Voted: false
        });
        Voterids.push(_Voterid);
    }
     
    function getvoterid() public view returns(uint[] memory){
        return Voterids;
    }

    //Function to increase a voter's ID by 5
    function  increaseVoterIdBy5(uint _Voterid ) public{
        require(voters[_Voterid].Voterid != 0, "Voter is not registered");
        Voter storage voter = voters[_Voterid];
        uint newVoterId = voter.Voterid +5;
    
     voters[ newVoterId] = Voter({
            Voterid:  newVoterId,
            Voter_name: voter.Voter_name,
            Voted: voter.Voted
        });

        delete voters[_Voterid];

        for (uint i = 0; i < Voterids.length; i++) {
            if (Voterids[i] == _Voterid) {
                Voterids[i] = newVoterId;
                break;
            }
    
}}
}
  
//In the fixed version, `returns(uint[] memory)` indicates that your function will be returning a dynamic array (i.e., one whose length can change). It's important to use `memory` in this case because you are returning an existing state variable that is stored on the blockchain. If it were local to the function, you would use `calldata` instead of `memory`.





