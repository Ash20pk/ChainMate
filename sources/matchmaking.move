module chainmate::match_making {
    use std::vector;
    use chainmate::profiles::{Self, Profile};

    struct Match has key {
        users: vector<address>,
    }

    public fun create_match(user1: address, user2: address) {
        let users = vector[user1, user2];
        let match = Match { users };
        move_to(&@chainmate, match);
    }

    public fun find_matches(user: address, max_matches: u64) acquires Profile {
        let user_profile = borrow_global<Profile>(user);
        let potential_matches = vector::empty<address>();

        // Find all user profiles and add them to potential matches
        // We can optimize this by maintaining a separate collection of profiles
        aptos_framework::account::for_all(|address| {
            if (exists<Profile>(address) && address != user) {
                vector::push_back(&mut potential_matches, address);
            }
        });

        // Sort potential matches by profile score in descending order
        vector::sort(&mut potential_matches, |a, b| {
            let profile_a = borrow_global<Profile>(a);
            let profile_b = borrow_global<Profile>(b);
            profile_a.profile_score > profile_b.profile_score
        });

        // Create matches with top profiles
        let i = 0;
        while (i < max_matches && i < vector::length(&potential_matches)) {
            let matched_user = vector::borrow(&potential_matches, i);
            create_match(user, *matched_user);
            i = i + 1;
        };
    }
}