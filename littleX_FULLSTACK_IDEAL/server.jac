"""Little X - Social graph backend (idiomatic Jac).

Declarations: nodes, edges, walker signatures, and node abilities.
Implementations live in server.impl.jac.
"""

import datetime;

# ============================================================================
# Utility
# ============================================================================

def _now() -> str;

# ============================================================================
# Graph: Nodes
# ============================================================================

node Profile {
    has username: str = "",
        bio: str = "",
        created_at: str = "";

    can setup with setup_profile entry;
    can get with get_profile entry;
    can tweet with create_tweet entry;
    can do_feed with load_feed entry;
    can do_create_channel with create_channel entry;
    can do_channel_tweet with create_channel_tweet entry;
}

node Tweet {
    has content: str = "",
        author_username: str = "",
        created_at: str = "";

    def get_tweet_dict(is_mine: bool = False) -> dict;
}

node Comment {
    has content: str = "",
        author_username: str = "",
        created_at: str = "";
}

node Channel {
    has name: str = "",
        description: str = "",
        creator_username: str = "",
        created_at: str = "";

    def get_member_count() -> int;
    def is_member_of(profile: Profile) -> bool;
    def get_channel_dict(my_profile: Profile = None) -> dict;
}

# ============================================================================
# Graph: Edges
# ============================================================================

edge Follow {
    has since: str = "";
}

edge Post {}

edge Like {
    has created_at: str = "";
}

edge Replied {}

edge Member {
    has joined_at: str = "";
}

edge ChannelPost {}

# ============================================================================
# Base walker: visit_profile
# ============================================================================

walker visit_profile {
    can go_to_profile with Root entry;
}

# ============================================================================
# Profile walkers (inherit visit_profile)
# ============================================================================

walker setup_profile(visit_profile) {
    has username: str = "",
        bio: str = "";
}

walker get_profile(visit_profile) {}

walker load_feed(visit_profile) {
    has search_query: str = "";
}

walker create_tweet(visit_profile) {
    has content: str;
}

walker create_channel(visit_profile) {
    has name: str,
        description: str = "";
}

walker create_channel_tweet(visit_profile) {
    has channel_id: str,
        content: str;
}

# ============================================================================
# Standalone walkers
# ============================================================================

walker:pub get_all_profiles {
    obj __specs__ {
        static has auth: bool = False;
    }
    can run with Root entry;
}

walker follow_user {
    has target_id: str;
    can run with Root entry;
}

walker unfollow_user {
    has target_id: str;
    can run with Root entry;
}

walker delete_tweet {
    has tweet_id: str;
    can run with Root entry;
}

walker like_tweet {
    has tweet_id: str;
    can run with Root entry;
}

walker add_comment {
    has tweet_id: str,
        content: str;
    can run with Root entry;
}

walker get_trending {
    can run with Root entry;
}

walker join_channel {
    has channel_id: str;
    can run with Root entry;
}

walker leave_channel {
    has channel_id: str;
    can run with Root entry;
}

walker get_channels {
    can run with Root entry;
}

walker get_channel_detail {
    has channel_id: str;
    can run with Root entry;
}
