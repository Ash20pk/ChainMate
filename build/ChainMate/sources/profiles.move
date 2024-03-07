module chainmate::profiles {

    use std::vector;    
    use aptos_framework::randomness;  
    use std::signer;
    use std::hash;
    use std::string::{Self, String};
    use std::option;
    use aptos_framework::object;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::bcs;


    const COLLECTION_NAME: vector<u8> = b"ChainMate";
    const COLLECTION_DESCRIPTION: vector<u8> = b"This is a NFT minted to the user creating a profile on ChainMate";

  struct Profile has key {
    id: vector<u8>,
    profile_score: u64,
  }
  struct GlobalStorage has key{
    next_index: u64,
  }

   /// The Profile token
    struct ProfileToken has key {
        /// Used to mutate the token uri
        mutator_ref: token::MutatorRef,
        /// Used to burn.
        burn_ref: token::BurnRef,
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// the base URI of the token
        base_uri: String,
    }

    fun init_module(sender: &signer) {
        create_profile_collection(sender);
    }

    fun create_profile_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(b"");

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    public entry fun mint_profile_token(
        creator: &signer,
        index: u64,
        base_uri: String,
        soul_bound_to: address,
        profile_uid: vector<u8>,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(COLLECTION_NAME);
        let name = string::utf8(b"ChainMate");
        let description = string::utf8(COLLECTION_DESCRIPTION);
        string::append(&mut name, string::utf8(b" member #"));
        string::append(&mut name, to_string(index));
        let uri = base_uri;
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            name,
            option::none(),
            uri,
        );

        let object_signer = object::generate_signer(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Transfers the token to the `soul_bound_to` address
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, soul_bound_to);

        // Disables ungated transfer, thus making the token soulbound and non-transferable
        object::disable_ungated_transfer(&transfer_ref);

        // Initialize the property map 
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"profile_uid"),
            string::utf8(profile_uid)
        );

        let profile_token = ProfileToken{
            mutator_ref,
            burn_ref,
            property_mutator_ref,
            base_uri
        };
        move_to(&object_signer, profile_token);
    }

    /// Converts a `u64` to its `ascii::String` decimal representation.
    fun to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }
    

  public fun create_profile(creator: &signer, _token_uri: String, data: &mut GlobalStorage ) {
     let base_score = randomness::u64_range(50, 100);
     let address = signer::address_of(creator);
     let profile_UID: vector<u8> = hash::sha2_256(bcs::to_bytes(&address));
     let index = data.next_index + 1;
     data.next_index = index;
     mint_profile_token(
            creator,
            index,
            string::utf8(b"{_token_uri}"),
            signer::address_of(creator),
            profile_UID,
        );
    move_to(creator, Profile{
        id: profile_UID,
        profile_score: base_score

     })

  }

}