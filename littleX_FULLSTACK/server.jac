"""Little X - Social graph backend with TF-IDF feed ranking."""

import datetime;
import from sklearn.feature_extraction.text { TfidfVectorizer }
import from sklearn.metrics.pairwise { cosine_similarity }

glob _vectorizer: Any = TfidfVectorizer();

def _compute_sim(query: str, content: str) -> float {
    if not query.strip() {
        return 1.0;
    }
    try {
        t = _vectorizer.fit_transform([query, content]);
        return float(cosine_similarity(t[0:1], t[1:2])[0][0]);
    } except Exception {
        return 0.0;
    }
}

def _now() -> str {
    return datetime.datetime.utcnow().isoformat() + "Z";
}

node Profile {
    has username: str = "";
    has bio: str = "";
    has created_at: str = "";
}

node Tweet {
    has content: str = "";
    has author_username: str = "";
    has created_at: str = "";
    has likes: list = [];
    has comments: list = [];
}

edge Follow {}
edge Post {}

walker setup_profile {
    has username: str = "";
    has bio: str = "";

    can run with Root entry {
        profiles = [-->(?:Profile)];
        if not profiles {
            p = here ++> Profile(username=self.username, bio=self.bio, created_at=_now());
            grant(p[0], level=ConnectPerm);
            report {"id": jid(p[0]), "username": p[0].username, "bio": p[0].bio, "created_at": p[0].created_at};
        } else {
            profile = profiles[0];
            if self.username {
                profile.username = self.username;
            }
            if self.bio {
                profile.bio = self.bio;
            }
            report {"id": jid(profile), "username": profile.username, "bio": profile.bio, "created_at": profile.created_at};
        }
    }
}

walker get_profile {
    can run with Root entry {
        profiles = [-->(?:Profile)];
        if not profiles {
            report {"error": "No profile found"};
            disengage;
        }
        p = profiles[0];
        my_id = jid(p);

        followers: list = [];
        following: list = [];

        for r in allroots() {
            other_list = [r-->(?:Profile)];
            if other_list {
                other = other_list[0];
                if jid(other) != my_id {
                    follow_out = [edge other ->:Follow:-> p];
                    if follow_out {
                        followers.append({"id": jid(other), "username": other.username});
                    }
                    follow_in = [edge p ->:Follow:-> other];
                    if follow_in {
                        following.append({"id": jid(other), "username": other.username});
                    }
                }
            }
        }

        tweets = [
            {
                "id": jid(t),
                "content": t.content,
                "author_username": t.author_username,
                "created_at": t.created_at,
                "likes": t.likes,
                "comments": t.comments
            }
            for t in [p-->(?:Tweet)]
        ];
        tweets.sort(key=lambda t: t["created_at"], reverse=True);
        report {
            "id": my_id,
            "username": p.username,
            "bio": p.bio,
            "followers": followers,
            "following": following,
            "tweets": tweets
        };
    }
}

walker:pub get_all_profiles {
    can run with Root entry {
        results: list = [];
        for r in allroots() {
            prof = [r-->(?:Profile)];
            if prof {
                results.append({"id": jid(prof[0]), "username": prof[0].username, "bio": prof[0].bio});
            }
        }
        report results;
    }
}

walker follow_user {
    has target_id: str;

    can run with Root entry {
        my_profiles = [-->(?:Profile)];
        if not my_profiles {
            report {"error": "No profile"};
            disengage;
        }
        my_profile = my_profiles[0];
        for r in allroots() {
            target_list = [r-->(?:Profile)];
            if target_list and jid(target_list[0]) == self.target_id {
                my_profile +>:Follow():+> target_list[0];
                report {"success": True};
                disengage;
            }
        }
        report {"error": "User not found"};
    }
}

walker unfollow_user {
    has target_id: str;

    can run with Root entry {
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
}

walker create_tweet {
    has content: str;

    can run with Root entry {
        profiles = [-->(?:Profile)];
        if not profiles {
            report {"error": "No profile"};
            disengage;
        }
        profile = profiles[0];
        tweet = profile +>:Post():+> Tweet(
            content=self.content,
            author_username=profile.username,
            created_at=_now(),
            likes=[],
            comments=[]
        );
        grant(tweet[0], level=ConnectPerm);
        t = tweet[0];
        report {"id": jid(t), "content": t.content, "author_username": t.author_username, "created_at": t.created_at, "likes": t.likes, "comments": t.comments};
    }
}

walker delete_tweet {
    has tweet_id: str;

    can run with Root entry {
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
        report {"error": "Tweet not found"};
    }
}

walker like_tweet {
    has tweet_id: str;

    can run with Root entry {
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
                        if username in tweet.likes {
                            tweet.likes = [u for u in tweet.likes if u != username];
                            report {"liked": False, "likes": tweet.likes};
                        } else {
                            tweet.likes = tweet.likes + [username];
                            report {"liked": True, "likes": tweet.likes};
                        }
                        disengage;
                    }
                }
            }
        }
        report {"error": "Tweet not found"};
    }
}

walker add_comment {
    has tweet_id: str;
    has content: str;

    can run with Root entry {
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
                        comment = {"username": username, "content": self.content, "created_at": _now()};
                        tweet.comments = tweet.comments + [comment];
                        report {"success": True, "comment": comment};
                        disengage;
                    }
                }
            }
        }
        report {"error": "Tweet not found"};
    }
}

walker get_trending {
    can run with Root entry {
        tag_counts: dict = {};
        for r in allroots() {
            prof = [r-->(?:Profile)];
            if prof {
                for tweet in [prof[0]-->(?:Tweet)] {
                    for word in tweet.content.split() {
                        if word.startswith("#") and len(word) > 1 {
                            tag = word.lower().rstrip(".,!?;:");
                            if tag in tag_counts {
                                tag_counts[tag] += 1;
                            } else {
                                tag_counts[tag] = 1;
                            }
                        }
                    }
                }
            }
        }
        sorted_tags = sorted(tag_counts.items(), key=lambda x: x[1], reverse=True);
        report [{"tag": t[0], "count": t[1]} for t in sorted_tags[:8]];
    }
}

walker load_feed {
    has search_query: str = "";

    can run with Root entry {
        my_profiles = [-->(?:Profile)];
        if not my_profiles {
            report [];
            disengage;
        }
        my_profile = my_profiles[0];
        all_tweets: list = [];

        for tweet in [my_profile-->(?:Tweet)] {
            all_tweets.append({
                "id": jid(tweet),
                "content": tweet.content,
                "author_username": tweet.author_username,
                "created_at": tweet.created_at,
                "likes": tweet.likes,
                "comments": tweet.comments,
                "is_mine": True
            });
        }

        for followed in [my_profile->:Follow:->(?:Profile)] {
            for tweet in [followed-->(?:Tweet)] {
                all_tweets.append({
                    "id": jid(tweet),
                    "content": tweet.content,
                    "author_username": tweet.author_username,
                    "created_at": tweet.created_at,
                    "likes": tweet.likes,
                    "comments": tweet.comments,
                    "is_mine": False
                });
            }
        }

        if self.search_query {
            q = self.search_query.lower().strip();
            all_tweets = [t for t in all_tweets if q in t["content"].lower()];
            all_tweets.sort(key=lambda t: t["created_at"], reverse=True);
        } else {
            all_tweets.sort(key=lambda t: t["created_at"], reverse=True);
        }

        report all_tweets;
    }
}
