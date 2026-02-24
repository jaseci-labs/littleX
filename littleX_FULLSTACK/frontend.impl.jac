"""Little X - Frontend function implementations."""

impl app.loadData -> None {
    result = root spawn setup_profile(username=localStorage.getItem("lx_username") or "");
    myProfile = result.reports[0] if result.reports else None;

    feedResult = root spawn load_feed(search_query="");
    tweets = feedResult.reports[0] if feedResult.reports else [];
    feedLoading = False;

    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;

    profilesResult = root spawn get_all_profiles();
    allProfiles = profilesResult.reports[0] if profilesResult.reports else [];

    trendResult = root spawn get_trending();
    trendingTags = trendResult.reports[0] if trendResult.reports else [];

    total_activity = (myProfile.tweets if myProfile and myProfile.tweets else []).reduce(lambda acc, t: acc + t["likes"].length + t["comments"].length, 0);
    last_seen_str = localStorage.getItem("lx_activity_total");
    last_seen = parseInt(last_seen_str) if last_seen_str else 0;
    notifCount = total_activity - last_seen if total_activity > last_seen else 0;
}

impl app.handleLogin -> None {
    authError = "";
    if not authUsername.trim() or not authPassword {
        authError = "Please fill in all fields";
        return;
    }
    authLoading = True;
    result = await jacLogin(authUsername, authPassword);
    authLoading = False;
    if result and (result["ok"] or result == True) {
        localStorage.setItem("lx_username", authUsername);
        isLoggedIn = True;
        authPassword = "";
        authError = "";
    } else {
        authError = (result["error"]["message"] if result and result["error"] and result["error"]["message"] else "Invalid username or password");
    }
}

impl app.handleSignup -> None {
    authError = "";
    if not authUsername.trim() or not authPassword {
        authError = "Please fill in all fields";
        return;
    }
    if authPassword.length < 4 {
        authError = "Password must be at least 4 characters";
        return;
    }
    authLoading = True;
    result = await jacSignup(authUsername, authPassword);
    authLoading = False;
    if result["ok"] or result["success"] {
        localStorage.setItem("lx_username", authUsername);
        isLoggedIn = True;
        authPassword = "";
        authError = "";
    } else {
        authError = (result["error"]["message"] if result["error"] and result["error"]["message"] else (result["error"] if result["error"] else "Signup failed"));
    }
}

impl app.handleLogout -> None {
    jacLogout();
    localStorage.removeItem("lx_username");
    isLoggedIn = False;
    myProfile = None;
    tweets = [];
    allProfiles = [];
    activeTab = "feed";
    authUsername = "";
    authPassword = "";
}

impl app.postTweet -> None {
    if not composerText.trim() {
        return;
    }
    text = composerText;
    composerText = "";
    root spawn create_tweet(content=text);
    feedResult = root spawn load_feed(search_query="");
    tweets = feedResult.reports[0] if feedResult.reports else [];
    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
}

impl app.handleLike(tweetId: str) -> None {
    root spawn like_tweet(tweet_id=tweetId);
    feedResult = root spawn load_feed(search_query=searchQuery);
    tweets = feedResult.reports[0] if feedResult.reports else [];
    if myProfile {
        profileResult = root spawn get_profile();
        myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
    }
    if selectedChannel {
        detailResult = root spawn get_channel_detail(channel_id=selectedChannel.id);
        detail = detailResult.reports[0] if detailResult.reports else None;
        if detail and not detail["error"] {
            selectedChannel = detail;
            channelPosts = detail["posts"] if detail["posts"] else [];
        }
    }
}

impl app.handleComment(tweetId: str, content: str) -> None {
    root spawn add_comment(tweet_id=tweetId, content=content);
    feedResult = root spawn load_feed(search_query=searchQuery);
    tweets = feedResult.reports[0] if feedResult.reports else [];
    if selectedChannel {
        detailResult = root spawn get_channel_detail(channel_id=selectedChannel.id);
        detail = detailResult.reports[0] if detailResult.reports else None;
        if detail and not detail["error"] {
            selectedChannel = detail;
            channelPosts = detail["posts"] if detail["posts"] else [];
        }
    }
}

impl app.handleDelete(tweetId: str) -> None {
    root spawn delete_tweet(tweet_id=tweetId);
    feedResult = root spawn load_feed(search_query=searchQuery);
    tweets = feedResult.reports[0] if feedResult.reports else [];
    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
}

impl app.handleFollow(profileId: str) -> None {
    if profileId == "_load" {
        profilesResult = root spawn get_all_profiles();
        allProfiles = profilesResult.reports[0] if profilesResult.reports else [];
        return;
    }
    root spawn follow_user(target_id=profileId);
    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
    feedResult = root spawn load_feed(search_query=searchQuery);
    tweets = feedResult.reports[0] if feedResult.reports else [];
}

impl app.handleUnfollow(profileId: str) -> None {
    root spawn unfollow_user(target_id=profileId);
    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
    feedResult = root spawn load_feed(search_query=searchQuery);
    tweets = feedResult.reports[0] if feedResult.reports else [];
}

impl app.handleSaveBio -> None {
    uname = myProfile.username if myProfile else "";
    root spawn setup_profile(username=uname, bio=bioText);
    profileResult = root spawn get_profile();
    myProfile = profileResult.reports[0] if profileResult.reports else myProfile;
    editingBio = False;
}

impl app.handleSearch(query: str) -> None {
    feedResult = root spawn load_feed(search_query=query);
    tweets = feedResult.reports[0] if feedResult.reports else [];
}

impl app.handleRepost(tweetId: str, content: str, author: str) -> None {
    display_author = author.split("@")[0] if author.includes("@") else author;
    composerText = "RT @" + display_author + ": " + content;
    activeTab = "feed";
}

impl app.handleDismissWelcome -> None {
    localStorage.setItem("lx_welcomed", "1");
    showWelcome = False;
}

impl app.loadChannels -> None {
    channelsLoading = True;
    result = root spawn get_channels();
    channels = result.reports[0] if result.reports else [];
    channelsLoading = False;
}

impl app.handleCreateChannel -> None {
    if not newChannelName.trim() {
        return;
    }
    root spawn create_channel(name=newChannelName.trim(), description=newChannelDescription.trim());
    newChannelName = "";
    newChannelDescription = "";
    showCreateChannel = False;
    result = root spawn get_channels();
    channels = result.reports[0] if result.reports else [];
}

impl app.handleJoinChannel(channelId: str) -> None {
    root spawn join_channel(channel_id=channelId);
    result = root spawn get_channels();
    channels = result.reports[0] if result.reports else [];
    if selectedChannel and selectedChannel.id == channelId {
        detailResult = root spawn get_channel_detail(channel_id=channelId);
        detail = detailResult.reports[0] if detailResult.reports else None;
        if detail and not detail["error"] {
            selectedChannel = detail;
            channelPosts = detail["posts"] if detail["posts"] else [];
        }
    }
}

impl app.handleLeaveChannel(channelId: str) -> None {
    root spawn leave_channel(channel_id=channelId);
    result = root spawn get_channels();
    channels = result.reports[0] if result.reports else [];
    if selectedChannel and selectedChannel.id == channelId {
        detailResult = root spawn get_channel_detail(channel_id=channelId);
        detail = detailResult.reports[0] if detailResult.reports else None;
        if detail and not detail["error"] {
            selectedChannel = detail;
            channelPosts = detail["posts"] if detail["posts"] else [];
        }
    }
}

impl app.handleSelectChannel(channelId: str) -> None {
    detailResult = root spawn get_channel_detail(channel_id=channelId);
    detail = detailResult.reports[0] if detailResult.reports else None;
    if detail and not detail["error"] {
        selectedChannel = detail;
        channelPosts = detail["posts"] if detail["posts"] else [];
    }
}

impl app.handleChannelPost -> None {
    if not channelComposerText.trim() or not selectedChannel {
        return;
    }
    text = channelComposerText;
    channelComposerText = "";
    root spawn create_channel_tweet(channel_id=selectedChannel.id, content=text);
    detailResult = root spawn get_channel_detail(channel_id=selectedChannel.id);
    detail = detailResult.reports[0] if detailResult.reports else None;
    if detail and not detail["error"] {
        selectedChannel = detail;
        channelPosts = detail["posts"] if detail["posts"] else [];
    }
}

impl app.handleBackToChannels -> None {
    selectedChannel = None;
    channelPosts = [];
    channelComposerText = "";
}
