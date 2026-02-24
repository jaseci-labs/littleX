"""Little X - Frontend declarations."""

import from "@jac/runtime" { jacSignup, jacLogin, jacLogout, jacIsLoggedIn }
sv import from .server { setup_profile, get_profile, get_all_profiles, follow_user, unfollow_user, create_tweet, delete_tweet, like_tweet, add_comment, load_feed, get_trending, create_channel, join_channel, leave_channel, get_channels, get_channel_detail, create_channel_tweet }
import from "lucide-react" { Home, Compass, User, LogOut, Search, Feather, Hash, Users, Plus, ArrowLeft }
import from .components.TweetCard { TweetCard }
import from .components.AuthForm { AuthForm }
import "./global.css";

def:pub app() -> Any {
    has isLoggedIn: bool = False,
        checkingAuth: bool = True,
        isSignup: bool = False,
        authUsername: str = "",
        authPassword: str = "",
        authError: str = "",
        authLoading: bool = False,
        activeTab: str = "feed",
        myProfile: Any = None,
        tweets: list = [],
        feedLoading: bool = True,
        composerText: str = "",
        searchQuery: str = "",
        allProfiles: list = [],
        editingBio: bool = False,
        bioText: str = "",
        trendingTags: list = [],
        notifCount: int = 0,
        showWelcome: bool = False,
        channels: list = [],
        channelsLoading: bool = False,
        selectedChannel: Any = None,
        channelPosts: list = [],
        channelComposerText: str = "",
        showCreateChannel: bool = False,
        newChannelName: str = "",
        newChannelDescription: str = "";

    can with entry {
        isLoggedIn = jacIsLoggedIn();
        checkingAuth = False;
    }

    can with [isLoggedIn] entry {
        if isLoggedIn {
            showWelcome = not localStorage.getItem("lx_welcomed");
            loadData();
        }
    }

    async def loadData() -> None;
    async def handleLogin() -> None;
    async def handleSignup() -> None;
    def handleLogout() -> None;
    async def postTweet() -> None;
    async def handleLike(tweetId: str) -> None;
    async def handleComment(tweetId: str, content: str) -> None;
    async def handleDelete(tweetId: str) -> None;
    async def handleFollow(profileId: str) -> None;
    async def handleUnfollow(profileId: str) -> None;
    async def handleSaveBio() -> None;
    async def handleSearch(query: str) -> None;
    def handleRepost(tweetId: str, content: str, author: str) -> None;
    def handleDismissWelcome() -> None;
    async def loadChannels() -> None;
    async def handleCreateChannel() -> None;
    async def handleJoinChannel(channelId: str) -> None;
    async def handleLeaveChannel(channelId: str) -> None;
    async def handleSelectChannel(channelId: str) -> None;
    async def handleChannelPost() -> None;
    def handleBackToChannels() -> None;

    if checkingAuth {
        return <div className="lx-loading">Loading...</div>;
    }

    if not isLoggedIn {
        return <AuthForm
            isSignup={isSignup}
            username={authUsername}
            password={authPassword}
            error={authError}
            loading={authLoading}
            onUsernameChange={lambda e: Any -> None { authUsername = e.target.value; }}
            onPasswordChange={lambda e: Any -> None { authPassword = e.target.value; }}
            onSubmit={lambda e: Any -> None { e.preventDefault(); if isSignup { handleSignup(); } else { handleLogin(); } }}
            onToggleMode={lambda -> None { isSignup = not isSignup; authError = ""; }}
        />;
    }

    profileUsername = myProfile.username if myProfile else "";
    displayUsername = profileUsername.split("@")[0] if profileUsername.includes("@") else profileUsername;
    profileAvatar = "https://i.pravatar.cc/150?u=fake@" + profileUsername;
    followingIds = [f["id"] for f in myProfile.following] if myProfile and myProfile.following else [];
    charsLeft = 280 - composerText.length;
    ring_progress = Math.min(1.0, (280 - charsLeft) / 280.0);
    ring_offset = String(62.83 * (1.0 - ring_progress));
    ring_color = "#ef4444" if charsLeft < 0 else ("#f97316" if charsLeft < 50 else ("#fb923c" if charsLeft < 100 else "#2a2a35"));
    toFollow = [u for u in allProfiles if not followingIds.includes(u["id"]) and u["id"] != (myProfile.id if myProfile else "")];
    current_total_activity = (myProfile.tweets if myProfile and myProfile.tweets else []).reduce(lambda acc, t: acc + t["likes"].length + t["comments"].length, 0);

    return <div className="lx-root">
        <aside className="lx-sidebar-left">
            <div className="lx-brand">
                <img src="/static/assets/littlex-logo.png" className="lx-brand-logo" alt="little-x" />
                <span className="lx-brand-name">LITTLE-X</span>
            </div>

            <nav className="lx-nav">
                <div
                    className={"lx-nav-item" + (" lx-nav-item-active" if activeTab == "feed" else "")}
                    onClick={lambda -> None { activeTab = "feed"; }}
                >
                    <Home size={22} />
                    <span>Home</span>
                </div>
                <div
                    className={"lx-nav-item" + (" lx-nav-item-active" if activeTab == "explore" else "")}
                    onClick={lambda -> None { activeTab = "explore"; }}
                >
                    <Compass size={22} />
                    <span>Explore</span>
                </div>
                <div
                    className={"lx-nav-item" + (" lx-nav-item-active" if activeTab == "channels" else "")}
                    onClick={lambda -> None { activeTab = "channels"; loadChannels(); }}
                >
                    <Hash size={22} />
                    <span>Channels</span>
                </div>
                <div
                    className={"lx-nav-item" + (" lx-nav-item-active" if activeTab == "profile" else "")}
                    onClick={lambda -> None { activeTab = "profile"; localStorage.setItem("lx_activity_total", String(current_total_activity)); notifCount = 0; }}
                >
                    <User size={22} />
                    <span>Profile</span>
                    {(
                        <span className="lx-nav-badge">{String(notifCount)}</span>
                    ) if notifCount > 0 else None}
                </div>
            </nav>

            <button className="lx-compose-btn" onClick={lambda -> None { activeTab = "feed"; }}>
                <Feather size={18} />
                <span>Post</span>
            </button>

            <div style={{"flex": "1"}} />

            <div className="lx-sidebar-user">
                <img className="lx-avatar" src={profileAvatar} alt={profileUsername} />
                <div className="lx-sidebar-user-info">
                    <div className="lx-sidebar-user-name">{displayUsername}</div>
                    <div className="lx-sidebar-user-handle">{"@" + displayUsername}</div>
                </div>
                <button className="lx-logout-icon-btn" onClick={lambda -> None { handleLogout(); }}>
                    <LogOut size={18} />
                </button>
            </div>
        </aside>

        <main className="lx-main">
            <div className="lx-feed-header">
                <span className="lx-feed-title">
                    {("Home" if activeTab == "feed" else ("Explore" if activeTab == "explore" else ("Channels" if activeTab == "channels" else "Profile")))}
                </span>
                {(
                    <button
                        className="lx-edit-profile-btn"
                        onClick={lambda -> None { editingBio = not editingBio; bioText = (myProfile.bio if myProfile and myProfile.bio else ""); }}
                    >
                        {"Cancel" if editingBio else "Edit profile"}
                    </button>
                ) if activeTab == "profile" else None}
            </div>

            {(
                <div>
                    {(
                        <div className="lx-welcome-banner">
                            <div className="lx-welcome-content">
                                <div className="lx-welcome-title">Welcome to LITTLE-X</div>
                                <div className="lx-welcome-tips">
                                    <span className="lx-welcome-tip">{"Post a thought to get started"}</span>
                                    <span className="lx-welcome-tip">{"Use #hashtags to join trending topics"}</span>
                                    <span className="lx-welcome-tip">{"Explore and follow people in Explore"}</span>
                                </div>
                            </div>
                            <button className="lx-welcome-dismiss" onClick={lambda -> None { handleDismissWelcome(); }}>
                                {"Got it"}
                            </button>
                        </div>
                    ) if showWelcome else None}
                    <div className="lx-composer">
                        <img className="lx-avatar" src={profileAvatar} alt={profileUsername} />
                        <div className="lx-composer-body">
                            <textarea
                                className="lx-composer-textarea"
                                placeholder="What's happening?"
                                value={composerText}
                                onChange={lambda e: Any -> None { composerText = e.target.value; }}
                                rows={3}
                            />
                            <div className="lx-composer-footer">
                                <div className="lx-char-ring-wrap">
                                    <svg className="lx-char-ring" viewBox="0 0 24 24">
                                        <circle className="lx-char-ring-bg" cx={12} cy={12} r={10} />
                                        <circle
                                            className="lx-char-ring-fill"
                                            cx={12}
                                            cy={12}
                                            r={10}
                                            strokeDasharray={"62.83"}
                                            strokeDashoffset={ring_offset}
                                            stroke={ring_color}
                                        />
                                    </svg>
                                    {(
                                        <span className={"lx-char-count-over" if charsLeft < 0 else "lx-char-count-warn"}>
                                            {String(charsLeft)}
                                        </span>
                                    ) if charsLeft <= 20 else None}
                                </div>
                                <button
                                    className="lx-post-btn"
                                    disabled={not composerText.trim() or charsLeft < 0}
                                    onClick={lambda -> None { postTweet(); }}
                                >
                                    Post
                                </button>
                            </div>
                        </div>
                    </div>

                    {(
                        <div className="lx-loading">Loading feed...</div>
                    ) if feedLoading else None}

                    {(
                        <div>
                            {(
                                <div className="lx-empty">
                                    <div className="lx-empty-title">Nothing here yet</div>
                                    <span>Follow people or post something!</span>
                                </div>
                            ) if tweets.length == 0 else None}
                            {[
                                <TweetCard
                                    key={tweet["id"]}
                                    tweet={tweet}
                                    myUsername={profileUsername}
                                    onLike={handleLike}
                                    onComment={handleComment}
                                    onDelete={handleDelete}
                                    onRepost={handleRepost}
                                /> for tweet in tweets
                            ]}
                        </div>
                    ) if not feedLoading else None}
                </div>
            ) if activeTab == "feed" else None}

            {(
                <div>
                    {(
                        <div className="lx-loading">Loading users...</div>
                    ) if not allProfiles else None}
                    {[
                        <div className="lx-explore-item" key={u["id"]}>
                            <img className="lx-avatar" src={"https://i.pravatar.cc/150?u=fake@" + u["username"]} alt={u["username"]} />
                            <div className="lx-explore-info">
                                <div className="lx-explore-name">{u["username"].split("@")[0] if u["username"].includes("@") else u["username"]}</div>
                                <div className="lx-explore-handle">{"@" + (u["username"].split("@")[0] if u["username"].includes("@") else u["username"])}</div>
                                <div className="lx-explore-bio">{u["bio"] if u["bio"] else "No bio yet"}</div>
                            </div>
                            {(
                                <button
                                    className="lx-unfollow-btn"
                                    onClick={lambda -> None { handleUnfollow(u["id"]); }}
                                >
                                    Following
                                </button>
                            ) if followingIds.includes(u["id"]) else (
                                <button
                                    className="lx-follow-btn"
                                    onClick={lambda -> None { handleFollow(u["id"]); }}
                                >
                                    Follow
                                </button>
                            ) if u["id"] != (myProfile.id if myProfile else "") else None}
                        </div>
                        for u in allProfiles
                    ]}
                </div>
            ) if activeTab == "explore" else None}

            {(
                <div>
                    {(
                        <div>
                            <div className="lx-channel-actions">
                                <button
                                    className="lx-post-btn"
                                    onClick={lambda -> None { showCreateChannel = not showCreateChannel; }}
                                >
                                    <Plus size={16} />
                                    {"Create Channel"}
                                </button>
                            </div>

                            {(
                                <div className="lx-channel-create-form">
                                    <input
                                        className="lx-input"
                                        placeholder="Channel name"
                                        value={newChannelName}
                                        onChange={lambda e: Any -> None { newChannelName = e.target.value; }}
                                    />
                                    <input
                                        className="lx-input"
                                        placeholder="Description (optional)"
                                        value={newChannelDescription}
                                        onChange={lambda e: Any -> None { newChannelDescription = e.target.value; }}
                                    />
                                    <div style={{"display": "flex", "gap": "0.5rem"}}>
                                        <button
                                            className="lx-post-btn"
                                            disabled={not newChannelName.trim()}
                                            onClick={lambda -> None { handleCreateChannel(); }}
                                        >
                                            Create
                                        </button>
                                        <button
                                            className="lx-edit-profile-btn"
                                            onClick={lambda -> None { showCreateChannel = False; newChannelName = ""; newChannelDescription = ""; }}
                                        >
                                            Cancel
                                        </button>
                                    </div>
                                </div>
                            ) if showCreateChannel else None}

                            {(
                                <div className="lx-loading">Loading channels...</div>
                            ) if channelsLoading else None}

                            {(
                                <div>
                                    {(
                                        <div className="lx-empty">
                                            <div className="lx-empty-title">No channels yet</div>
                                            <span>Create one to get started!</span>
                                        </div>
                                    ) if channels.length == 0 else None}
                                    {[
                                        <div
                                            className="lx-channel-item"
                                            key={ch["id"]}
                                            onClick={lambda -> None { handleSelectChannel(ch["id"]); }}
                                        >
                                            <div className="lx-channel-icon">
                                                <Hash size={20} />
                                            </div>
                                            <div className="lx-channel-item-info">
                                                <div className="lx-channel-item-name">{ch["name"]}</div>
                                                {(
                                                    <div className="lx-channel-item-desc">{ch["description"]}</div>
                                                ) if ch["description"] else None}
                                                <div className="lx-channel-item-meta">
                                                    <Users size={12} />
                                                    <span>{String(ch["member_count"]) + " members"}</span>
                                                </div>
                                            </div>
                                            {(
                                                <span className="lx-channel-joined-badge">Joined</span>
                                            ) if ch["is_member"] else None}
                                        </div>
                                        for ch in channels
                                    ]}
                                </div>
                            ) if not channelsLoading else None}
                        </div>
                    ) if not selectedChannel else (
                        <div>
                            <div className="lx-channel-header">
                                <button
                                    className="lx-edit-profile-btn"
                                    onClick={lambda -> None { handleBackToChannels(); }}
                                    style={{"display": "flex", "alignItems": "center", "gap": "0.3rem"}}
                                >
                                    <ArrowLeft size={16} />
                                    Back
                                </button>
                                <div className="lx-channel-name">
                                    <Hash size={20} />
                                    {selectedChannel.name}
                                </div>
                                {(
                                    <div className="lx-channel-desc">{selectedChannel.description}</div>
                                ) if selectedChannel.description else None}
                                <div className="lx-channel-meta">
                                    <Users size={14} />
                                    <span>{String(selectedChannel.member_count) + " members"}</span>
                                    {(
                                        <button
                                            className="lx-edit-profile-btn"
                                            onClick={lambda -> None { handleLeaveChannel(selectedChannel.id); }}
                                        >
                                            Leave
                                        </button>
                                    ) if selectedChannel.is_member else (
                                        <button
                                            className="lx-follow-btn"
                                            onClick={lambda -> None { handleJoinChannel(selectedChannel.id); }}
                                        >
                                            Join
                                        </button>
                                    )}
                                </div>
                            </div>

                            {(
                                <div className="lx-composer">
                                    <img className="lx-avatar" src={profileAvatar} alt={profileUsername} />
                                    <div className="lx-composer-body">
                                        <textarea
                                            className="lx-composer-textarea"
                                            placeholder={"Post in #" + selectedChannel.name}
                                            value={channelComposerText}
                                            onChange={lambda e: Any -> None { channelComposerText = e.target.value; }}
                                            rows={2}
                                        />
                                        <div className="lx-composer-footer">
                                            <div />
                                            <button
                                                className="lx-post-btn"
                                                disabled={not channelComposerText.trim()}
                                                onClick={lambda -> None { handleChannelPost(); }}
                                            >
                                                Post
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            ) if selectedChannel.is_member else None}

                            {(
                                <div className="lx-empty">
                                    <div className="lx-empty-title">No posts yet</div>
                                    <span>{("Be the first to post!" if selectedChannel.is_member else "Join this channel to post!")}</span>
                                </div>
                            ) if channelPosts.length == 0 else None}

                            {[
                                <TweetCard
                                    key={tweet["id"]}
                                    tweet={tweet}
                                    myUsername={profileUsername}
                                    onLike={handleLike}
                                    onComment={handleComment}
                                    onDelete={handleDelete}
                                    onRepost={handleRepost}
                                /> for tweet in channelPosts
                            ]}
                        </div>
                    )}
                </div>
            ) if activeTab == "channels" else None}

            {(
                <div>
                    <div className="lx-profile-banner" />
                    <div className="lx-profile-info">
                        <div className="lx-profile-avatar-wrap">
                            <img className="lx-avatar-lg" src={profileAvatar} alt={profileUsername} />
                        </div>
                        <div className="lx-profile-display-name">{displayUsername}</div>
                        <div className="lx-profile-handle">{"@" + displayUsername}</div>
                        {(
                            <div className="lx-profile-bio-text">
                                {myProfile.bio if myProfile and myProfile.bio else "No bio yet"}
                            </div>
                        ) if not editingBio else None}
                        {(
                            <div className="lx-bio-edit-wrap">
                                <textarea
                                    className="lx-bio-input"
                                    rows={3}
                                    placeholder="Write your bio..."
                                    value={bioText}
                                    onChange={lambda e: Any -> None { bioText = e.target.value; }}
                                />
                                <div style={{"display": "flex", "gap": "0.5rem"}}>
                                    <button className="lx-bio-save-btn" onClick={lambda -> None { handleSaveBio(); }}>
                                        Save
                                    </button>
                                    <button
                                        className="lx-edit-profile-btn"
                                        onClick={lambda -> None { editingBio = False; }}
                                    >
                                        Cancel
                                    </button>
                                </div>
                            </div>
                        ) if editingBio else None}
                        <div className="lx-profile-stats">
                            <div className="lx-profile-stat">
                                <strong>{String(len(myProfile.following) if myProfile and myProfile.following else 0)}</strong>
                                Following
                            </div>
                            <div className="lx-profile-stat">
                                <strong>{String(len(myProfile.followers) if myProfile and myProfile.followers else 0)}</strong>
                                Followers
                            </div>
                            <div className="lx-profile-stat">
                                <strong>{String(len(myProfile.tweets) if myProfile and myProfile.tweets else 0)}</strong>
                                Posts
                            </div>
                        </div>
                    </div>

                    {[
                        <TweetCard
                            key={tweet["id"]}
                            tweet={tweet}
                            myUsername={profileUsername}
                            onLike={handleLike}
                            onComment={handleComment}
                            onDelete={handleDelete}
                            onRepost={handleRepost}
                        /> for tweet in (myProfile.tweets if myProfile and myProfile.tweets else [])
                    ]}
                </div>
            ) if activeTab == "profile" else None}
        </main>

        <aside className="lx-sidebar-right">
            <div className="lx-sidebar-right-inner">
                <div className="lx-search-wrap">
                    <span className="lx-search-icon">
                        <Search size={16} />
                    </span>
                    <input
                        className="lx-search-input"
                        placeholder="Search Little-X"
                        value={searchQuery}
                        onChange={lambda e: Any -> None { searchQuery = e.target.value; }}
                        onKeyDown={lambda e: Any -> None { if e.key == "Enter" { handleSearch(e.target.value); } }}
                    />
                    <button
                        className="lx-search-btn"
                        onClick={lambda -> None { handleSearch(searchQuery); }}
                    >
                        Search
                    </button>
                </div>

                {(
                    <div className="lx-widget">
                        <div className="lx-widget-title">Trending</div>
                        {[
                            <div
                                className="lx-trend-item"
                                key={t["tag"]}
                                onClick={lambda -> None { searchQuery = t["tag"]; handleSearch(t["tag"]); activeTab = "feed"; }}
                            >
                                <span className="lx-trend-tag">{t["tag"]}</span>
                                <span className="lx-trend-count">{String(t["count"]) + " posts"}</span>
                            </div>
                            for t in trendingTags
                        ]}
                    </div>
                ) if trendingTags.length > 0 else None}

                {(
                    <div className="lx-widget">
                        <div className="lx-widget-title">Who to follow</div>
                        {[
                            <div className="lx-follow-item" key={u["id"]}>
                                <img className="lx-avatar-sm" src={"https://i.pravatar.cc/150?u=fake@" + u["username"]} alt={u["username"]} />
                                <div className="lx-follow-item-info">
                                    <div className="lx-follow-item-name">{u["username"].split("@")[0] if u["username"].includes("@") else u["username"]}</div>
                                    <div className="lx-follow-item-handle">{"@" + (u["username"].split("@")[0] if u["username"].includes("@") else u["username"])}</div>
                                </div>
                                <button
                                    className="lx-follow-btn"
                                    onClick={lambda -> None { handleFollow(u["id"]); }}
                                >
                                    Follow
                                </button>
                            </div>
                            for u in toFollow.slice(0, 5)
                        ]}
                        {(
                            <div className="lx-widget-show-more" onClick={lambda -> None { activeTab = "explore"; }}>
                                Show more
                            </div>
                        ) if toFollow.length > 5 else None}
                    </div>
                ) if toFollow.length > 0 else None}

                <div className="lx-about-widget">
                    <div className="lx-about-title">LITTLE-X</div>
                    <div className="lx-about-desc">A decentralized social platform built with Jac. Share thoughts, follow people, join conversations.</div>
                    <div className="lx-about-links">
                        <span className="lx-about-tag">{"#jacdev"}</span>
                        <span className="lx-about-tag">{"#jaseci"}</span>
                        <span className="lx-about-tag">{"#open-source"}</span>
                    </div>
                </div>
            </div>
        </aside>

        <nav className="lx-mobile-nav">
            <div
                className={"lx-mobile-nav-item" + (" lx-mobile-nav-item-active" if activeTab == "feed" else "")}
                onClick={lambda -> None { activeTab = "feed"; }}
            >
                <Home size={24} />
            </div>
            <div
                className={"lx-mobile-nav-item" + (" lx-mobile-nav-item-active" if activeTab == "explore" else "")}
                onClick={lambda -> None { activeTab = "explore"; }}
            >
                <Compass size={24} />
            </div>
            <div
                className={"lx-mobile-nav-item" + (" lx-mobile-nav-item-active" if activeTab == "channels" else "")}
                onClick={lambda -> None { activeTab = "channels"; loadChannels(); }}
            >
                <Hash size={24} />
            </div>
            <div
                className={"lx-mobile-nav-item" + (" lx-mobile-nav-item-active" if activeTab == "profile" else "")}
                onClick={lambda -> None { activeTab = "profile"; localStorage.setItem("lx_activity_total", String(current_total_activity)); notifCount = 0; }}
            >
                <User size={24} />
                {(
                    <span className="lx-nav-badge">{String(notifCount)}</span>
                ) if notifCount > 0 else None}
            </div>
        </nav>

        <button className="lx-mobile-fab" onClick={lambda -> None { activeTab = "feed"; }}>
            <Feather size={22} />
        </button>
    </div>;
}
