import Trie "mo:base/Trie";
import Text "mo:base/Text";
import RBTree "mo:base/RBTree";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Types "./Types";

actor {
  // canister are created with actors.
  // it contains both data and code, and executes in a single thread.
  // Actors communicate with external world by sending and receiving "messages".
  
  // create a variable to host the main question of the poll
  var question: Text = "Do you want to see the Partage Protocol on ICP?";
  // create a variable to host the answer's data
  var votes: RBTree.RBTree<Text, Nat> = RBTree.RBTree(Text.compare);

  // query the main question
  public query func getQuestion() : async Text { 
    question 
  };

  // query the list of entries and votes for each one
  public query func getVotes() : async [(Text, Nat)] {
        Iter.toArray(votes.entries())
    };

  // The vote function takes an entry to vote for, updates the data and returns the updated hashmap    
  public func vote(entry: Text) : async [(Text, Nat)] {
    //Check if the entry already has votes.
    let votes_for_entry :?Nat = votes.get(entry);
    //Need to be explicit about what to do when it is null or a number so every case is taken care of
    let current_votes_for_entry : Nat = switch votes_for_entry {
      case null 0;
      case (?Nat) Nat;
    };
    //once we have the number of votes, update the votes for the entry
    votes.put(entry, current_votes_for_entry + 1);
    //Return the number of votes as an array (so frontend can display it)
    Iter.toArray(votes.entries())
  };

  func account_get(id : Principal) : ?Types.Tokens = Trie.get(accounts, Types.account_key(id), Principal.equal);

  /// Return the account balance of the caller
    public query({caller}) func account_balance() : async Types.Tokens {
        Option.get(account_get(caller), Types.zeroToken)
    };

  /* burn function?
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
*/
};
