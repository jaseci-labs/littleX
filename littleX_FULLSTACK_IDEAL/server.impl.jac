"""Little X - Implementation of all abilities."""

# ============================================================================
# Utility
# ============================================================================

impl _now -> str {
    return datetime.datetime.utcnow().isoformat() + "Z";
}

# ============================================================================
# Node: Tweet — materialize graph data into frontend-compatible dict
# ============================================================================

impl Tweet.get_tweet_dict(is_mine: bool = False) -> dict {
    likes_list: list = [prof.username for prof in [self->:Like:->(?:Profile)]];
    comments_list: list = [
        {"username": c.author_username, "content": c.content, "created_at": c.created_at}
        for c in [self-->(?:Comment)]
    ];
    return {
        "id": jid(self),
        "content": self.content,
        "author_username": self.author_username,
        "created_at": self.created_at,
        "likes": likes_list,
        "comments": comments_list,
        "is_mine": is_mine
    };
}

# ============================================================================
# Node: Channel — helper methods
# ============================================================================

impl Channel.get_member_count -> int {
    members: list = [];
    for r in allroots() {
        p_list = [r-->(?:Profile)];
        if p_list and [edge p_list[0] ->:Member:-> self] {
            members.append(p_list[0]);
        }
    }
    return len(members);
}

impl Channel.is_member_of(profile: Profile) -> bool {
    return bool([edge profile ->:Member:-> self]);
}

impl Channel.get_channel_dict(my_profile: Profile = None) -> dict {
    is_mem = self.is_member_of(my_profile) if my_profile else False;
    return {
        "id": jid(self),
        "name": self.name,
        "description": self.description,
        "creator_username": self.creator_username,
        "created_at": self.created_at,
        "member_count": self.get_member_count(),
        "is_member": is_mem
    };
}

# ============================================================================
# Base walker: visit_profile
# ============================================================================

impl visit_profile.go_to_profile {
    visit [-->(?:Profile)] else {
        new_profile = here ++> Profile(created_at=_now());
        grant(new_profile[0], level=ConnectPerm);
        visit new_profile;
    }
}

# ============================================================================
# Profile abilities (triggered when walkers arrive at Profile)
# ============================================================================

impl Profile.setup {
    if visitor.username {
        self.username = visitor.username;
    }
    if visitor.bio {
        self.bio = visitor.bio;
    }
    if not self.created_at {
        self.created_at = _now();
    }
    report {
        "id": jid(self),
        "username": self.username,
        "bio": self.bio,
        "created_at": self.created_at
    };
}

impl Profile.get {
    my_id = jid(self);
    followers: list = [];
    following: list = [];

    for r in allroots() {
        other_list = [r-->(?:Profile)];
        if other_list {
            other = other_list[0];
            if jid(other) != my_id {
                if [edge other ->:Follow:-> self] {
                    followers.append({"id": jid(other), "username": other.username});
                }
                if [edge self ->:Follow:-> other] {
                    following.append({"id": jid(other), "username": other.username});
                }
            }
        }
    }

    tweets = sorted([t.get_tweet_dict() for t in [self-->(?:Tweet)]], key=lambda t: t["created_at"], reverse=True);

    report {
        "id": my_id,
        "username": self.username,
        "bio": self.bio,
        "followers": followers,
        "following": following,
        "tweets": tweets
    };
}

impl Profile.tweet {
    tweet_node = self +>:Post():+> Tweet(
        content=visitor.content,
        author_username=self.username,
        created_at=_now()
    );
    grant(tweet_node[0], level=ConnectPerm);
    report tweet_node[0].get_tweet_dict();
}

impl Profile.do_feed {
    all_tweets = [tweet.get_tweet_dict(is_mine=True) for tweet in [self-->(?:Tweet)]];

    for followed in [self->:Follow:->(?:Profile)] {
        all_tweets += [tweet.get_tweet_dict(is_mine=False) for tweet in [followed-->(?:Tweet)]];
    }

    if visitor.search_query {
        q = visitor.search_query.lower().strip();
        all_tweets = [t for t in all_tweets if q in t["content"].lower()];
    }

    report sorted(all_tweets, key=lambda t: t["created_at"], reverse=True);
}

impl Profile.do_create_channel {
    channel_nodes = self +>:Member(joined_at=_now()):+> Channel(
        name=visitor.name,
        description=visitor.description,
        creator_username=self.username,
        created_at=_now()
    );
    ch = channel_nodes[0];
    grant(ch, level=ConnectPerm);
    report ch.get_channel_dict(my_profile=self);
}

impl Profile.do_channel_tweet {
    for ch in [self-->(?:Channel)] {
        if jid(ch) == visitor.channel_id {
            tweet = ch +>:ChannelPost():+> Tweet(
                content=visitor.content,
                author_username=self.username,
                created_at=_now()
            );
            grant(tweet[0], level=ConnectPerm);
            report tweet[0].get_tweet_dict();
            disengage;
        }
    }
    report {"error": "Not a member of this channel"};
}

# ============================================================================
# Standalone walker implementations
# ============================================================================

impl get_all_profiles.run {
    results: list = [];
    for r in allroots() {
        prof = [r-->(?:Profile)];
        if prof {
            results.append({
                "id": jid(prof[0]),
                "username": prof[0].username,
                "bio": prof[0].bio
            });
        }
    }
    report results;
}

impl follow_user.run {
    my_profiles = [-->(?:Profile)];
    if not my_profiles {
        report {"error": "No profile"};
        disengage;
    }
    my_profile = my_profiles[0];
    for r in allroots() {
        target_list = [r-->(?:Profile)];
        if target_list and jid(target_list[0]) == self.target_id {
            my_profile +>:Follow(since=_now()):+> target_list[0];
            report {"success": True};
            disengage;
        }
    }
    report {"error": "User not found"};
}

impl unfollow_user.run {
    my_profiles = [-->(?:Profile)];
    if not my_profiles {
        report {"error": "No profile"};
        disengage;
    }
    my_profile = my_profiles[0];
    for r in allroots() {
        target_list = [r-->(?:Profile)];
        if target_list and jid(target_list[0]) == self.target_id {
            follow_edges = [edge my_profile ->:Follow:-> target_list[0]];
            if follow_edges {
                del follow_edges[0];
            }
            report {"success": True};
            disengage;
        }
    }
    report {"error": "User not found"};
}

impl delete_tweet.run {
    profiles = [-->(?:Profile)];
    if not profiles {
        report {"error": "No profile"};
        disengage;
    }
    profile = profiles[0];
    for tweet in [profile-->(?:Tweet)] {
        if jid(tweet) == self.tweet_id {
            del tweet;
            report {"success": True};
            disengage;
        }
    }
    for channel in [profile-->(?:Channel)] {
        for tweet in [channel-->(?:Tweet)] {
            if jid(tweet) == self.tweet_id and tweet.author_username == profile.username {
                del tweet;
                report {"success": True};
                disengage;
            }
        }
    }
    report {"error": "Tweet not found"};
}

impl like_tweet.run {
    my_profiles = [-->(?:Profile)];
    if not my_profiles {
        report {"error": "No profile"};
        disengage;
    }
    my_profile = my_profiles[0];

    for r in allroots() {
        prof_list = [r-->(?:Profile)];
        if prof_list {
            for tweet in [prof_list[0]-->(?:Tweet)] {
                if jid(tweet) == self.tweet_id {
                    existing_likes = [edge tweet ->:Like:-> my_profile];
                    if existing_likes {
                        del existing_likes[0];
                        likes_now = [p.username for p in [tweet->:Like:->(?:Profile)]];
                        report {"liked": False, "likes": likes_now};
                    } else {
                        tweet +>:Like(created_at=_now()):+> my_profile;
                        likes_now = [p.username for p in [tweet->:Like:->(?:Profile)]];
                        report {"liked": True, "likes": likes_now};
                    }
                    disengage;
                }
            }
            for channel in [prof_list[0]-->(?:Channel)] {
                for tweet in [channel-->(?:Tweet)] {
                    if jid(tweet) == self.tweet_id {
                        existing_likes = [edge tweet ->:Like:-> my_profile];
                        if existing_likes {
                            del existing_likes[0];
                            likes_now = [p.username for p in [tweet->:Like:->(?:Profile)]];
                            report {"liked": False, "likes": likes_now};
                        } else {
                            tweet +>:Like(created_at=_now()):+> my_profile;
                            likes_now = [p.username for p in [tweet->:Like:->(?:Profile)]];
                            report {"liked": True, "likes": likes_now};
                        }
                        disengage;
                    }
                }
            }
        }
    }
    report {"error": "Tweet not found"};
}

impl add_comment.run {
    my_profiles = [-->(?:Profile)];
    if not my_profiles {
        report {"error": "No profile"};
        disengage;
    }
    username = my_profiles[0].username;

    for r in allroots() {
        prof_list = [r-->(?:Profile)];
        if prof_list {
            for tweet in [prof_list[0]-->(?:Tweet)] {
                if jid(tweet) == self.tweet_id {
                    now = _now();
                    comment_node = tweet ++> Comment(
                        content=self.content,
                        author_username=username,
                        created_at=now
                    );
                    grant(comment_node[0], level=ConnectPerm);
                    report {
                        "success": True,
                        "comment": {"username": username, "content": self.content, "created_at": now}
                    };
                    disengage;
                }
            }
            for channel in [prof_list[0]-->(?:Channel)] {
                for tweet in [channel-->(?:Tweet)] {
                    if jid(tweet) == self.tweet_id {
                        now = _now();
                        comment_node = tweet ++> Comment(
                            content=self.content,
                            author_username=username,
                            created_at=now
                        );
                        grant(comment_node[0], level=ConnectPerm);
                        report {
                            "success": True,
                            "comment": {"username": username, "content": self.content, "created_at": now}
                        };
                        disengage;
                    }
                }
            }
        }
    }
    report {"error": "Tweet not found"};
}

impl get_trending.run {
    tag_counts: dict = {};
    for r in allroots() {
        prof = [r-->(?:Profile)];
        if prof {
            for tweet in [prof[0]-->(?:Tweet)] {
                for word in tweet.content.split() {
                    if word.startswith("#") and len(word) > 1 {
                        tag = word.lower().rstrip(".,!?;:");
                        tag_counts[tag] = tag_counts.get(tag, 0) + 1;
                    }
                }
            }
        }
    }
    sorted_tags = sorted(tag_counts.items(), key=lambda x: x[1], reverse=True);
    report [{"tag": t[0], "count": t[1]} for t in sorted_tags[:8]];
}

impl join_channel.run {
    profiles = [-->(?:Profile)];
    if not profiles {
        report {"error": "No profile"};
        disengage;
    }
    profile = profiles[0];
    for r in allroots() {
        prof_list = [r-->(?:Profile)];
        if prof_list {
            for ch in [prof_list[0]-->(?:Channel)] {
                if jid(ch) == self.channel_id {
                    if not [edge profile ->:Member:-> ch] {
                        profile +>:Member(joined_at=_now()):+> ch;
                    }
                    report {"success": True};
                    disengage;
                }
            }
        }
    }
    report {"error": "Channel not found"};
}

impl leave_channel.run {
    profiles = [-->(?:Profile)];
    if not profiles {
        report {"error": "No profile"};
        disengage;
    }
    profile = profiles[0];
    for ch in [profile-->(?:Channel)] {
        if jid(ch) == self.channel_id {
            member_edges = [edge profile ->:Member:-> ch];
            if member_edges {
                del member_edges[0];
            }
            report {"success": True};
            disengage;
        }
    }
    report {"error": "Channel not found"};
}

impl get_channels.run {
    my_profiles = [-->(?:Profile)];
    my_profile = my_profiles[0] if my_profiles else None;

    seen: set = set();
    channels: list = [];
    for r in allroots() {
        prof_list = [r-->(?:Profile)];
        if prof_list {
            for ch in [prof_list[0]-->(?:Channel)] {
                ch_id = jid(ch);
                if ch_id not in seen {
                    seen.add(ch_id);
                    channels.append(ch.get_channel_dict(my_profile=my_profile));
                }
            }
        }
    }
    report sorted(channels, key=lambda c: c["created_at"], reverse=True);
}

impl get_channel_detail.run {
    my_profiles = [-->(?:Profile)];
    my_profile = my_profiles[0] if my_profiles else None;

    for r in allroots() {
        prof_list = [r-->(?:Profile)];
        if prof_list {
            for ch in [prof_list[0]-->(?:Channel)] {
                if jid(ch) == self.channel_id {
                    posts = sorted([t.get_tweet_dict() for t in [ch-->(?:Tweet)]], key=lambda p: p["created_at"], reverse=True);
                    report ch.get_channel_dict(my_profile=my_profile) | {"posts": posts};
                    disengage;
                }
            }
        }
    }
    report {"error": "Channel not found"};
}
