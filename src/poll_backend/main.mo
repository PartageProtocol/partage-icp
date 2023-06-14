// the following in a translation of the Partage Protocol v1 into IC smart contract
import Text "mo:base/Text";
import RBTree "mo:base/RBTree";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
/*
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Types "./Types";
*/

// Canister smart contracts are created like actors types.
// actors contain both data and code, and executes in a single thread.
// actors communicate with external world by sending and receiving "messages".
// actors interact with each others through management canister interface.
// Partage canister will interact with token canisters and ledger canister.
actor { 
// data structure
  // variable to host the main question of a poll
  var question: Text = "Do you want to see the Partage Protocol on IC network?";
  // variable to host the answer's data
  var votes: RBTree.RBTree<Text, Nat> = RBTree.RBTree(Text.compare);

  /*
  // variable to host a list of registered accounts
  var accounts = Types.accounts_fromArray(init.accounts);
  */

// read-only functions
  // what is the question to vote for in the header ?
  public query func getQuestion() : async Text {question};
  // what is the result of the vote ?
  public query func getVotes() : async [(Text, Nat)] {Iter.toArray(votes.entries())};
  
  /*
  // what are the registered accounts on this canister
  func account_get(id : Principal) : ?Types.Tokens = Trie.get(accounts, Types.account_key(id), Principal.equal);
  // what is the account balance of the caller
  public query({caller}) func account_balance() : async Types.Tokens {Option.get(account_get(caller), Types.zeroToken)};
  // Returns the balance of the given Bitcoin address.
  public func get_balance(address : BitcoinAddress) : async Satoshi {
    await BitcoinApi.get_balance(NETWORK, address)};
  // return the cycles balance of the current canister 
  public func wallet_balance() : async Nat {
    return Cycles.balance();};
  // who is the owner of this nft/
  public query func ownerOfDip721(token_id: Types.TokenId) : async Types.OwnerResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case (null) {return #Err(#InvalidTokenId);};
      case (?token) {return #Ok(token.owner);};};};
  // what is the uri of this nft ?
  public query func getMetadataDip721(token_id: Types.TokenId) : async Types.MetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {return #Err(#InvalidTokenId);};
      case (?token) {return #Ok(token.metadata);}};};
  */

// action functions
  // The vote function takes an entry to vote for, updates the data and returns the updated hashmap    
  public func vote(entry: Text) : async [(Text, Nat)] {
    //Check if the entry already has votes.
    let votes_for_entry :?Nat = votes.get(entry);
    //Need to be explicit about what to do when it is null or a number so every case is taken care of
    let current_votes_for_entry : Nat = switch votes_for_entry {
      case null 0;
      case (?Nat) Nat;};
    //once we have the number of votes, update the votes for the entry
    votes.put(entry, current_votes_for_entry + 1);
    //Return the number of votes as an array (so frontend can display it)
    Iter.toArray(votes.entries())
  };
  /*
  public func resetVotes() : async [(Text, Nat)] {
      votes.put("yes", 0);
      votes.put("no", 0);
      votes.put("why not?", 0);
      Iter.toArray(votes.entries())
  };
*/
/*
// nft-related functions
  // mint-nft 
    public shared({ caller }) func mintDip721(to: Principal, metadata: Types.MetadataDesc) : async Types.MintReceipt {
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };
    let newId = Nat64.fromNat(List.size(nfts));
    let nft : Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };

    nfts := List.push(nft, nfts);

    transactionId += 1;

    return #Ok({
      token_id = newId;
      id = transactionId;
    });
  };
  // burn-nft 

  // transfer-nft 
  public shared({ caller }) func transferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {
    return transferFrom(from, to, token_id, caller);
  };

  func transferFrom(from: Principal, to: Principal, token_id: Types.TokenId, caller: Principal) : Types.TxReceipt {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        if (
          caller != token.owner and
          not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })
        ) {
          return #Err(#Unauthorized);
        } else if (Principal.notEqual(from, token.owner)) {
          return #Err(#Other);
        } else {
          nfts := List.map(nfts, func (item : Types.Nft) : Types.Nft {
            if (item.id == token.id) {
              let update : Types.Nft = {
                owner = to;
                id = item.id;
                metadata = token.metadata;
              };
              return update;
            } else {
              return item;
            };
          });
          transactionId += 1;
          return #Ok(transactionId);   
        };
      };
    };
  };

  // fractionalize-nft 

  // transfer-fractions ?
  /// Transfer tokens from the caller's account to another account
    public shared({caller}) func transfer(transfer: Types.TransferArgs) : async Types.Result<(), Text> {
        switch (account_get caller) {
        case null { #err "Caller needs an account to transfer funds" };
        case (?from_tokens) {
                 let fee = system_params.transfer_fee.amount_e8s;
                 let amount = transfer.amount.amount_e8s;
                 if (from_tokens.amount_e8s < amount + fee) {
                     #err ("Caller's account has insufficient funds to transfer " # debug_show(amount));
                 } else {
                     let from_amount : Nat = from_tokens.amount_e8s - amount - fee;
                     account_put(caller, { amount_e8s = from_amount });
                     let to_amount = Option.get(account_get(transfer.to), Types.zeroToken).amount_e8s + amount;
                     account_put(transfer.to, { amount_e8s = to_amount });
                     #ok;
                 };
        };
      };
    };

  
  // transfer cycles (payment)
  public func transfer(
    receiver : shared () -> async (),
    amount : Nat) : async { refunded : Nat } {
      Cycles.add(amount);
      await receiver();
      { refunded = Cycles.refunded() };
  };
  // enables the program to receive cycles sent to the canister
  public func wallet_receive() : async { accepted: Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, limit));
    { accepted = Nat64.fromNat(accepted) };
  };

  // burn-fractions
  // Burn half of this actor's cycle balance by provisioning,
  // creating, stopping and deleting a fresh canister
  // (without ever installing any code)
  public func burn() : async () {
    Debug.print("balance before: " # Nat.toText(Cycles.balance()));
    Cycles.add(Cycles.balance()/2);
    let cid = await IC.create_canister({});
    let status = await IC.canister_status(cid);
    Debug.print("cycles: " # Nat.toText(status.cycles));
    await IC.stop_canister(cid);
    await IC.delete_canister(cid);
    Debug.print("balance after: " # Nat.toText(Cycles.balance()));
  };

// marketplace-related functions
  // set-utility-provider
  // set-platform-fees
  // list-nft
  // unlist-nft
  // list-fractions
  // unlist-fractions
  // buy-nft
  // buy-fractions
      */
};

